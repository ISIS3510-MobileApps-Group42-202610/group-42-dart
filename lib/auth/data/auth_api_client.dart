// Aqui se manejan las peticiones al api del back

import 'package:dio/dio.dart';
import '../models/auth_models.dart';


class AuthApiClient {
  final Dio dio;

  // instanciar el objeto + dio brando
  AuthApiClient(this.dio);

  // POST para el registro de usuariosss
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await dio.post('/auth/register', data: request.toJson());
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // POST para login de usuarios
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await dio.post('/auth/login', data: request.toJson());
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // POST para forgot password
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) async {
    final response = await dio.post('/auth/forgot-password', data: request.toJson());
    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // POST para reset password
  Future<MessageResponse> resetPassword(ResetPasswordRequest request) async {
    final response = await dio.post('/auth/reset-password', data: request.toJson());
    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }


  // DELETE para eliminar cuenta, requiere el JWT y dio se encarga de eso xd
  Future<MessageResponse> deleteAccount(DeleteAccountRequest request) async {
    final response = await dio.delete('/auth/delete-account', data: request.toJson());
    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
