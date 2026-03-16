// el mismisimo business logic component de autenticacion

import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../repositories/auth_repository.dart';
import '../models/auth_models.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required AuthRepository repositoryTemp})
    : repository = repositoryTemp,
      super(const AuthInitial()) {}

  // ============================================================================
  // eventos
  // Aqui el chiste es mappear cada evento

  // restaurar sesion
  Future<void> onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await repository.tryRestoreSession();
      if (user != null) {
        final token = await repository.getToken();
        // si el token es nulo, lanza error. se pone el ! para intentarlo
        emit(AuthAuthenticated(user: user, accessToken: token!));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  // login
  Future<void> onLogin(AuthLoginRequest event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await repository.login(
        LoginRequest(email: event.email, password: event.password),
      );
      emit(
        AuthAuthenticated(
          user: response.user,
          accessToken: response.accessToken,
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // reegister
  Future<void> onRegister(
    AuthRegisterRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await repository.register(
        RegisterRequest(
          name: event.name,
          lastName: event.lastName,
          email: event.email,
          password: event.password,
          semester: event.semester,
          profilePic: event.profilePic,
          isSeller: event.isSeller,
        ),
      );
      emit(
        AuthAuthenticated(
          user: response.user,
          accessToken: response.accessToken,
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // logout
  Future<void> _onLogout(
      AuthLogoutRequest event,
      Emitter<AuthState> emit,
      ) async {
    await repository.logout();
    emit(const AuthUnauthenticated());
  }

  // olvide contraseña
  Future<void> onForgotPassword(
      AuthForgotPasswordRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final response = await repository.forgotPassword(event.email);
      emit(AuthActionSuccess(
        message: response.message,
        action: AuthAction.forgotPassword,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // Reset contraseña
  Future<void> onResetPassword(
      AuthResetPasswordRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final response = await repository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(AuthActionSuccess(
        message: response.message,
        action: AuthAction.resetPassword,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }


  // Borrar cuenta
  Future<void> onDeleteAccount(
      AuthDeleteAccountRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final response = await repository.deleteAccount(event.password);
      emit(AuthActionSuccess(
        message: response.message,
        action: AuthAction.deleteAccount,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

}
