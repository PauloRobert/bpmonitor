// data/repositories/auth_repository_impl.dart (MIGRAÇÃO CORRETA PARA v7)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dartz/dartz.dart';
import 'package:bp_monitor/core/error/failures.dart';
import 'package:bp_monitor/domain/entities/user_entity.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';
import 'package:bp_monitor/data/models/user_model.dart';
import 'package:bp_monitor/core/utils/logger.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final AppLogger _logger;
  final AppStrings _strings;

  // Manual state management (required in v7)
  GoogleSignInAccount? _currentUser;
  bool _isGoogleSignInInitialized = false;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
    required AppLogger logger,
    required AppStrings strings,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore,
        _logger = logger,
        _strings = strings;

  /// Ensure Google Sign-In is initialized before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
        _logger.d('Google Sign-In inicializado com sucesso');
      } catch (e) {
        _logger.e('Falha ao inicializar Google Sign-In', e);
        throw Exception('Falha na inicialização do Google Sign-In: $e');
      }
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // CORREÇÃO: Usar authenticate() ao invés de signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Update manual state management
      _currentUser = googleUser;

      // CORREÇÃO: authentication agora é síncrono (não await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Get authorization for Firebase scopes
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email', 'profile']);

      if (authorization == null) {
        return Left(AuthFailure(_strings.loginError));
      }

      // Criar credencial do Firebase usando authorization
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      // Login no Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return Left(AuthFailure(_strings.loginError));
      }

      // Verificar se o usuário já existe no Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Atualizar último login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });

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
    } on GoogleSignInException catch (e) {
      _logger.e('Google Sign-In error: ${e.code.name}', e);
      return Left(AuthFailure(_googleSignInExceptionToMessage(e)));
    } catch (e, stackTrace) {
      _logger.e('Erro no login com Google', e, stackTrace);
      return Left(AuthFailure('Erro no login: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      // Clear manual state
      _currentUser = null;

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Erro ao fazer logout', e, stackTrace);
      return Left(AuthFailure('Erro ao fazer logout: ${e.toString()}'));
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
      return Left(AuthFailure('Erro ao obter usuário: ${e.toString()}'));
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

      final updatedUserDoc = await _firestore.collection('users').doc(user.id).get();

      if (!updatedUserDoc.exists) {
        return Left(AuthFailure('Usuário não encontrado após atualização'));
      }

      final updatedUserData = updatedUserDoc.data() as Map<String, dynamic>;
      return Right(UserModel.fromFirestore(updatedUserData, user.id).toEntity());
    } catch (e, stackTrace) {
      _logger.e('Erro ao atualizar perfil', e, stackTrace);
      return Left(AuthFailure('Erro ao atualizar perfil: ${e.toString()}'));
    }
  }

  /// Silent authentication attempt
  Future<GoogleSignInAccount?> _attemptSilentSignIn() async {
    await _ensureGoogleSignInInitialized();
    try {
      // CORREÇÃO: Usar attemptLightweightAuthentication() ao invés de signInSilently()
      final result = _googleSignIn.attemptLightweightAuthentication();

      // Handle both sync and async returns
      if (result is Future<GoogleSignInAccount?>) {
        return await result;
      } else {
        return result as GoogleSignInAccount?;
      }
    } catch (error) {
      _logger.w('Silent sign-in failed', error);
      return null;
    }
  }

  /// Convert GoogleSignInException to user-friendly message
  String _googleSignInExceptionToMessage(GoogleSignInException exception) {
    switch (exception.code.name) {
      case 'canceled':
        return _strings.loginCanceled;
      case 'interrupted':
        return 'Login foi interrompido. Tente novamente.';
      case 'clientConfigurationError':
        return 'Erro de configuração. Contate o suporte.';
      case 'providerConfigurationError':
        return 'Google Sign-In indisponível. Tente mais tarde.';
      case 'uiUnavailable':
        return 'Interface de login indisponível. Tente mais tarde.';
      case 'userMismatch':
        return 'Problema com sua conta. Saia e tente novamente.';
      case 'unknownError':
      default:
        return _strings.loginError;
    }
  }
}