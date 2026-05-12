// define los eventos que llegan al bloc de auth

import 'package:equatable/equatable.dart';
import 'dart:io';

// evento basico para el bloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// evento para restaurar la sesion (en caso de haber un JWT)
class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

// evento de login
class AuthLoginRequest extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequest({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

// evento de registro
class AuthRegisterRequest extends AuthEvent {
  final String name;
  final String lastName;
  final String email;
  final String password;
  final int? semester;
  final File? profileImageFile;
  final bool isSeller;

  const AuthRegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    this.semester,
    this.profileImageFile,
    this.isSeller = false,
  });

  @override
  List<Object?> get props => [
    name,
    lastName,
    email,
    password,
    semester,
    profileImageFile?.path,
    isSeller,
  ];
}


// sign oput event
class AuthLogoutRequest extends AuthEvent {
  const AuthLogoutRequest();
}

// forgot pass
class AuthForgotPasswordRequest extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequest({required this.email});

  @override
  List<Object> get props => [email];
}


//  reset password event
class AuthResetPasswordRequest extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthResetPasswordRequest({required this.token, required this.newPassword});

  @override
  List<Object> get props => [token, newPassword];
}


// borrar cuenta rip
class AuthDeleteAccountRequest extends AuthEvent {
  final String password;

  const AuthDeleteAccountRequest({required this.password});

  @override
  List<Object> get props => [password];
}
