// el mismo business logic component de autenticacion

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
      super(const AuthUnauthenticated()) {
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
    print('[AUTH_BLOC] onCheckSession disabled');
    await repository.logout();
    emit(const AuthUnauthenticated());
  }

  // login
  Future<void> onLogin(AuthLoginRequest event, Emitter<AuthState> emit) async {
    print('[AUTH_BLOC] onLogin started');
    emit(const AuthLoading());
    print('[AUTH_BLOC] emitted AuthLoading');

    try {
      print('[AUTH_BLOC] calling repository.login');

      final response = await repository.login(
        LoginRequest(email: event.email, password: event.password),
      );

      print('[AUTH_BLOC] repository.login success');
      print('[AUTH_BLOC] user: ${response.user.email}');
      print('[AUTH_BLOC] TOKEN PARA SEED: ${response.accessToken}');

      emit(
        AuthAuthenticated(
          user: response.user,
          accessToken: response.accessToken,
        ),
      );

      print('[AUTH_BLOC] emitted AuthAuthenticated');
    } on ConnectionError catch (e) {
      print('[AUTH_BLOC] ConnectionError: $e');
      emit(
        const AuthConnectionError(
          message: 'No internet connection. Please try again later.',
        ),
      );
    } catch (e, st) {
      print('[AUTH_BLOC] login error: $e');
      print('[AUTH_BLOC] stack: $st');
      emit(AuthError(message: extractMessage(e)));
    }
  }

  // reegister
  Future<void> onRegister(
      AuthRegisterRequest event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    try {
      String? profilePicUrl;

      if (event.profileImageFile != null) {
        profilePicUrl = await repository.uploadProfileImage(
          event.profileImageFile!,
        );
      }

      final response = await repository.register(
        RegisterRequest(
          name: event.name,
          lastName: event.lastName,
          email: event.email,
          password: event.password,
          semester: event.semester,
          profilePic: profilePicUrl,
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
    print('[AUTH_BLOC] onLogout called');
    await repository.logout();
    print('[AUTH_BLOC] emitting AuthUnauthenticated from onLogout');
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
          message: extractMessage(e),
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
          final msg = data['message'] ?? data['error'];
          if (msg is List) return msg.join('\n');
          if (msg is String && msg.isNotEmpty) return msg;
          return data.toString();
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
