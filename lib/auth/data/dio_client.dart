// Dio es una dependencia para las peticiones http al back

import 'package:dio/dio.dart';
import '../data/token_storage.dart';

// Dio esencialmente va a servirnos para hacer las peticiones a la API
// Este específicamente es para el módulo de autenticación

Dio createDio({
  required TokenStorage tokenStorage,
  String baseUrl = 'http://localhost:3000',
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // el interceptor para el token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // los paths del login, register, forgot-password y reset-password no necesitan token
        const publicPaths = [
          '/auth/login',
          '/auth/register',
          '/auth/forgot-password',
          '/auth/reset-password',
        ];
        final isPublic = publicPaths.contains(options.path);
        if (!isPublic) {
          // si no es publico, se obtiene el token y se agrega al header
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        // se continua con la peticion
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ),
  );

  return dio;
}
