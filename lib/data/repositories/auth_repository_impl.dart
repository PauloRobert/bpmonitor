import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dartz/dartz.dart';
import 'package:bp_monitor/core/error/failures.dart';
import 'package:bp_monitor/core/error/exceptions.dart';
import 'package:bp_monitor/domain/entities/user_entity.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';
import 'package:bp_monitor/data/models/user_model.dart';
import 'package:bp_monitor/core/utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final AppLogger _logger;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
    required AppLogger logger,
  }) : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore,
        _logger = logger;

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      // Iniciar fluxo de login
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(AuthFailure('Login cancelado pelo usuário'));
      }

      // Obter credenciais de autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Login no Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return Left(AuthFailure('Falha ao obter dados do usuário'));
      }

      // Verificar se o usuário já existe no Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Atualizar último login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });

        // Converter para UserEntity
        final userData = userDoc.data() as Map<String, dynamic>;
        return Right(UserModel.fromFirestore(userData, user.uid).toEntity());
      } else {
        // Criar novo usuário no Firestore
        final newUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Usuário',
          email: user.email,
          photoUrl: user.photoURL,
          birthDate: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return Right(newUser.toEntity());
      }
    } catch (e, stackTrace) {
      _logger.e('Erro no login com Google', e, stackTrace);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Erro ao fazer logout', e, stackTrace);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return const Right(null);
      }

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        return const Right(null);
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return Right(UserModel.fromFirestore(userData, firebaseUser.uid).toEntity());
    } catch (e, stackTrace) {
      _logger.e('Erro ao obter usuário atual', e, stackTrace);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);

      await _firestore.collection('users').doc(user.id).update({
        'name': userModel.name,
        'birthDate': userModel.birthDate,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Obter dados atualizados
      final updatedUserDoc = await _firestore.collection('users').doc(user.id).get();
      final updatedUserData = updatedUserDoc.data() as Map<String, dynamic>;

      return Right(UserModel.fromFirestore(updatedUserData, user.id).toEntity());
    } catch (e, stackTrace) {
      _logger.e('Erro ao atualizar perfil', e, stackTrace);
      return Left(AuthFailure(e.toString()));
    }
  }
}