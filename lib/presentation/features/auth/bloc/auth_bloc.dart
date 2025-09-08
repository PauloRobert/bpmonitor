import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bp_monitor/domain/repositories/auth_repository.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_event.dart';
import 'package:bp_monitor/presentation/features/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    final isAuthenticated = await authRepository.isAuthenticated();

    if (isAuthenticated) {
      final userResult = await authRepository.getCurrentUser();
      userResult.fold(
            (failure) => emit(AuthError(failure.message)),
            (user) {
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogle(
      SignInWithGoogleEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await authRepository.signInWithGoogle();

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignOut(
      SignOutEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await authRepository.signOut();

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onUpdateUserProfile(
      UpdateUserProfileEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await authRepository.updateUserProfile(event.user);

    result.fold(
          (failure) => emit(ProfileUpdateFailure(failure.message)),
          (updatedUser) => emit(ProfileUpdateSuccess(updatedUser)),
    );
  }
}