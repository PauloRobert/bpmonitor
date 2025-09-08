import 'package:dartz/dartz.dart';
import 'package:bp_monitor/core/error/failures.dart';
import 'package:bp_monitor/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Verifica se o usuário está autenticado
  Future<bool> isAuthenticated();

  /// Realiza login com Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Realiza logout
  Future<Either<Failure, void>> signOut();

  /// Obtém usuário atual
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Atualiza perfil do usuário
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user);
}