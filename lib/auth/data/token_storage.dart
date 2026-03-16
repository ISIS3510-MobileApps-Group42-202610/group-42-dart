// Guardar el token JWT en el localstorage del device

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';

class TokenStorage {
  static const tokenKey = 'access_token';
  static const userKey = 'auth_user';
  final FlutterSecureStorage storage;

  TokenStorage({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  Future<void> save(AuthResponse auth) async {
    await storage.write(key: tokenKey, value: auth.accessToken);
    await storage.write(key: userKey, value: jsonEncode(auth.user.toJson()));
  }

  Future<String?> getToken() => storage.read(key: tokenKey);

  Future<AuthUser?> getUser() async {
    final raw = await storage.read(key: userKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await storage.delete(key: tokenKey);
    await storage.delete(key: userKey);
  }

  Future<bool> hasToken() async => (await getToken()) != null;
}
