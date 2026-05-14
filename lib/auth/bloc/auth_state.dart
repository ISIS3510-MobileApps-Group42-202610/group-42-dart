/// estados utilizados en el bloc

import 'package:equatable/equatable.dart';
import '../models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// El app inicia por primera vez
class AuthInitial extends AuthState {
  const AuthInitial();
}

// operacion asincrona
class AuthLoading extends AuthState {
  const AuthLoading();
}

// el usuario se autentico (login, registro, sesion restaurada con token)
class AuthAuthenticated extends AuthState {
  final AuthUser user;
  final String accessToken;
  final DateTime authenticatedAt;

  AuthAuthenticated({
    required this.user,
    required this.accessToken,
    DateTime? authenticatedAt,
  }) : authenticatedAt = authenticatedAt ?? DateTime.now();

  @override
  List<Object> get props => [user, accessToken, authenticatedAt];
}

// no hay token
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// error ocurrio durante el login o registro del usuario
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

// enum para las posibles acciones que se pueden realizar, sin contar login y registro
enum AuthAction { forgotPassword, resetPassword, deleteAccount }

// operacion exitosa (no login o registro)
class AuthActionSuccess extends AuthState {
  final String message;
  final AuthAction action;

  const AuthActionSuccess({required this.message, required this.action});

  @override
  List<Object> get props => [message, action];
}

// Nuevo estado de error de conexión
class AuthConnectionError extends AuthState {
  final String message;

  const AuthConnectionError({required this.message});

  @override
  List<Object> get props => [message];
}