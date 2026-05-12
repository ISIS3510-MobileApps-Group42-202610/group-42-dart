// Aqui se manejan las peticiones al api del back

import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import 'dart:io';


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

  Future<Map<String, dynamic>> getCloudinarySignature({
    String? folder,
  }) async {
    final response = await dio.post(
      '/uploads/cloudinary-signature',
      data: {
        if (folder != null) 'folder': folder,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;

    throw Exception('Invalid cloudinary signature response.');
  }

  Future<String> uploadProfileImageToCloudinary(File imageFile) async {
    final sig = await getCloudinarySignature(
      folder: 'unimarket/profile_pictures',
    );

    final cloudName = sig['cloud_name'] ?? sig['cloudName'];
    final apiKey = sig['api_key'] ?? sig['apiKey'];
    final timestamp = sig['timestamp'];
    final signature = sig['signature'];
    final folder = sig['folder'];

    final uploadDio = Dio();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      if (folder != null) 'folder': folder,
    });

    final uploadResponse = await uploadDio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
    );

    final uploadData = uploadResponse.data;
    if (uploadData is Map<String, dynamic>) {
      return (uploadData['secure_url'] ?? uploadData['url']) as String;
    }

    throw Exception('Invalid Cloudinary upload response.');
  }

}
