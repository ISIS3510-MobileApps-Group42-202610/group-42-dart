// Dio es una dependencia para las peticiones http al back

import 'package:dio/dio.dart';
import '../data/token_storage.dart';

// Dio esencialmente va a servirnos para hacer las peticiones a la API
// Este específicamente es para el módulo de autenticación

Dio createDio({
  required TokenStorage tokenStorage,
  String baseUrl = 'https://group-42-backend.vercel.app/api/v1',
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
        const publicPaths = [
          '/auth/login',
          '/auth/register',
          '/auth/forgot-password',
          '/auth/reset-password',
        ];

        final isPublic = publicPaths.contains(options.path);

        print('[DIO] ${options.method} ${options.path}');
        print('[DIO] isPublic: $isPublic');

        if (!isPublic) {
          final token = await tokenStorage.getToken();
          print('[DIO] token null?: ${token == null}');
          print('[DIO] token empty?: ${token?.isEmpty}');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('[DIO] Authorization header added');
          }
        }

        return handler.next(options);
      },
      onError: (error, handler) {
        print('[DIO] ERROR ${error.requestOptions.method} ${error.requestOptions.path}');
        print('[DIO] status: ${error.response?.statusCode}');
        print('[DIO] response: ${error.response?.data}');
        return handler.next(error);
      },
    ),
  );

  return dio;
}
