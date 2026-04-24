// basicamente es el entry point para el bloc de auth

import 'package:isis3510_group42_flutter_app/services/connectivity_service.dart';
import 'package:isis3510_group42_flutter_app/products/data/listings_cache.dart';

import '../data/auth_api_client.dart';
import '../data/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final AuthApiClient api;
  final TokenStorage storage;
  final ConnectivityService connectivityService;
  final ListingsCache listingsCache;

  AuthRepository({
    required AuthApiClient apiTemp,
    required TokenStorage storageTemp,
    required ConnectivityService connectivityServiceTemp,
    ListingsCache? listingsCacheTemp,
  }) : api = apiTemp,
       storage = storageTemp,
       connectivityService = connectivityServiceTemp,
       listingsCache = listingsCacheTemp ?? ListingsCache();

  // Registro de un nuevo usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      throw ConnectionError('No internet connection. Please try again later');
    }
    final response = await api.register(request);
    await storage.save(response);
    return response;
  }

  // Inicio de sesión de un usuario existente
  Future<AuthResponse> login(LoginRequest request) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      throw ConnectionError('No internet connection. Please try again later');
    }
    final response = await api.login(request);
    await storage.save(response);
    return response;
  }

  // Forgot password
  Future<MessageResponse> forgotPassword(String email) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      throw ConnectionError('No internet connection. Please try again later');
    }
    return api.forgotPassword(ForgotPasswordRequest(email: email));
  }

  // Nueva contraseña
  Future<MessageResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      throw ConnectionError('No internet connection. Please try again later');
    }
    return api.resetPassword(
      ResetPasswordRequest(token: token, newPassword: newPassword),
    );
  }

  // Eliminar cuenta
  Future<MessageResponse> deleteAccount(String password) async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      throw ConnectionError('No internet connection. Please try again later');
    }
    final response = await api.deleteAccount(
      DeleteAccountRequest(password: password),
    );
    await storage
        .clear(); // borrar el localstorage de token para evitar problemas
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
    await listingsCache.clearSessionCache(); // borrar el cache de las listings si se cierra sesión
    await storage.clear();
  }
}

// Excepción personalizada para errores de conexión
class ConnectionError implements Exception {
  final String message;

  ConnectionError(this.message);

  @override
  String toString() => message;
}
