// Guardar el token JWT en el localstorage del device

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';

// funcion para decodificar el usuario en un isolate
AuthUser? decodeUserOnIsolate(String jsonStr) {
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      return AuthUser.fromJson(decoded);
    }
    return null;
  } catch (_) {
    return null;
  }
}

// clase para encapsular los datos de sesión (token y usuario) que se cargarán en el isolate
class SessionData {
  final String? token;
  final AuthUser? user;

  const SessionData({required this.token, required this.user});
}

// cargar sesion en isolate
Future<SessionData> loadSessionOnIsolate(
  Map<String, String?> storageData,
) async {
  final token = storageData['token'];
  final userJson = storageData['user'];

  AuthUser? user;
  if (userJson != null) {
    user = decodeUserOnIsolate(userJson);
  }

  return SessionData(token: token, user: user);
}

class TokenStorage {
  static const tokenKey = 'access_token';
  static const userKey = 'auth_user';
  final FlutterSecureStorage storage;

  TokenStorage({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  Future<void> save(AuthResponse auth) async {
    await Future.wait([
      storage.write(key: tokenKey, value: auth.accessToken),
      storage.write(key: userKey, value: jsonEncode(auth.user.toJson())),
    ]);
  }

  Future<String?> getToken() => storage.read(key: tokenKey);

  Future<AuthUser?> getUser() async {
    final raw = await storage.read(key: userKey);
    if (raw == null) return null;
    return compute(decodeUserOnIsolate, raw);
  }

  Future<void> clear() async {
    await Future.wait([
      storage.delete(key: tokenKey),
      storage.delete(key: userKey),
    ]);
  }

  Future<bool> hasToken() async => (await getToken()) != null;

  // restaurar sesion usando isolate para descodificación eficiente en paralelo
  Future<(String?, AuthUser?)> restoreSessionOnIsolate() async {
    try {
      final tokenFuture = storage.read(key: tokenKey);
      final userJsonFuture = storage.read(key: userKey);

      final results = await Future.wait<String?>([tokenFuture, userJsonFuture]);
      final token = results[0];
      final userJson = results[1];

      if (token == null) {
        return (null, null);
      }

      final storageData = <String, String?>{'token': token, 'user': userJson};
      final sessionData = await compute(loadSessionOnIsolate, storageData);

      return (sessionData.token, sessionData.user);
    } catch (_) {
      return (null, null);
    }
  }
}
