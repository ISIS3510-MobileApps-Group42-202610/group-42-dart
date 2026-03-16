// basicamente es el entry point para el bloc de auth

import '../data/auth_api_client.dart';
import '../data/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final AuthApiClient api;
  final TokenStorage storage;

  AuthRepository({
    required AuthApiClient apiTemp,
    required TokenStorage storageTemp,
  }) : api = apiTemp,
       storage = storageTemp;

  // Registro de un nuevo usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await api.register(request);
    await storage.save(response);
    return response;
  }

  // Inicio de sesión de un usuario existente
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await api.login(request);
    await storage.save(response);
    return response;
  }

  // Forgot password
  Future<MessageResponse> forgotPassword(String email) async {
    return api.forgotPassword(ForgotPasswordRequest(email: email));
  }

  // Nueva contraseña
  Future<MessageResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return api.resetPassword(ResetPasswordRequest(
      token: token,
      newPassword: newPassword,
    ));
  }

  // Eliminar cuenta
  Future<MessageResponse> deleteAccount(String password) async {
    final response = await api.deleteAccount(DeleteAccountRequest(password: password));
    await storage.clear(); // borrar el localstorage de token para evitar problemas
    return response;
  }


  // Verificar si el usuario está logueado
  Future<AuthUser?> tryRestoreSession() async {
    final hasToken = await storage.hasToken(); // sacar el JWT
    if (!hasToken) return null;
    return storage.getUser(); // Sacar el user
  }

  // Obtener el JWT
  Future<String?> getToken() async {
    return storage.getToken();
  }

  // Borrar el localstorage
  Future<void> logout() async {
    await storage.clear();
  }
}
