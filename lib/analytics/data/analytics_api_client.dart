import 'package:dio/dio.dart';

class AnalyticsApiClient {
  final Dio dio;

  AnalyticsApiClient({required this.dio});

  // post a la db analytics un evento de performance, bq1 c:
  Future<void> postPerformanceEvent({
    required String eventType,
    required String deviceModel,
    required String platform,
    required double durationMs,
    String osVersion = '',
    String appVersion = '',
  }) async {
    await dio.post( // hacer el post a la db analytica a traves de django
      '/api/performance',
      data: {
        'event_type': eventType,
        'device_model': deviceModel,
        'platform': platform,
        'duration_ms': durationMs,
        'os_version': osVersion,
        'app_version': appVersion,
      },
    );
  }
}
