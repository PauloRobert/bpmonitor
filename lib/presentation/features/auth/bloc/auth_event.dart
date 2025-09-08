import 'package:equatable/equatable.dart';
import 'package:bp_monitor/domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class SignOutEvent extends AuthEvent {}

class UpdateUserProfileEvent extends AuthEvent {
  final UserEntity user;

  const UpdateUserProfileEvent(this.user);

  @override
  List<Object?> get props => [user];
}