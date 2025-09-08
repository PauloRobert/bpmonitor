import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'Ocorreu um erro inesperado']);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Erro de servidor']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Erro de cache']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Erro de autenticação']) : super(message);
}