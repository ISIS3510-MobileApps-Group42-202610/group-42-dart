// el mismisimo business logic component de autenticacion

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../repositories/auth_repository.dart';
import '../models/auth_models.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required AuthRepository repositoryTemp})
    : repository = repositoryTemp,
      super(const AuthInitial()) {
    on<AuthCheckSession>(onCheckSession);
    on<AuthLoginRequest>(onLogin);
    on<AuthRegisterRequest>(onRegister);
    on<AuthLogoutRequest>(onLogout);
    on<AuthForgotPasswordRequest>(onForgotPassword);
    on<AuthResetPasswordRequest>(onResetPassword);
    on<AuthDeleteAccountRequest>(onDeleteAccount);
  }

  // ============================================================================
  // eventos
  // Aqui el chiste es mappear cada evento

  // restaurar sesion usando isolate para descodificación eficiente en paralelo
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
      emit(AuthError(message: "Error restoring session. Please log in again."));
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
    } on ConnectionError {
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          message:
              "There was an error during login. Please check your credentials and try again.",
        ),
      );
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
    } on ConnectionError {
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          message: "There was an error during registration. Please try again.",
        ),
      );
    }
  }

  // logout
  Future<void> onLogout(
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
      emit(
        AuthActionSuccess(
          message: response.message,
          action: AuthAction.forgotPassword,
        ),
      );
    } on ConnectionError {
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          message:
              "There was an error processing your request. Please try again.",
        ),
      );
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
      emit(
        AuthActionSuccess(
          message: response.message,
          action: AuthAction.resetPassword,
        ),
      );
    } on ConnectionError {
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          message:
              "There was an error processing your request. Please try again.",
        ),
      );
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
      emit(
        AuthActionSuccess(
          message: response.message,
          action: AuthAction.deleteAccount,
        ),
      );
    } on ConnectionError {
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          message:
              "Error deleting account. Please check your password and try again.",
        ),
      );
    }
  }

  // Extraer errores
  String extractMessage(Object error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final msg = data['message'];
          if (msg is List) return msg.join('\n');
          if (msg is String) return msg;
        }

        if (data is String && data.isNotEmpty) return data;

        // Fallback a codigos de estado
        switch (response.statusCode) {
          case 400:
            return 'Invalid request. Please check your input.';
          case 409:
            return 'Email already in use.';
          case 401:
            return 'Invalid credentials.';
          default:
            return 'Server error (${response.statusCode}). Please try again.';
        }
      }

      // Problemas de internet
      return 'Connection error. Check your internet and try again.';
    }
    return 'An unexpected error occurred.';
  }
}
