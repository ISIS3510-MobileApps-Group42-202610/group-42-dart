import 'package:dio/dio.dart';
import '../models/analytics_models.dart';

class AnalyticsApiClient {
  final Dio dio;

  AnalyticsApiClient({required this.dio});

  // post a la db analytics un evento de performance, bq1 c:
  Future<PerformanceResponse> postPerformanceEvent( PerformanceRequest request ) async {
    final response = await dio.post('/api/performance', data: request.toJson());
    return PerformanceResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
