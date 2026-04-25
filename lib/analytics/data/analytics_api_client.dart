import 'package:dio/dio.dart';
import '../models/analytics_models.dart';

class AnalyticsApiClient {
  final Dio dio;

  AnalyticsApiClient({required this.dio});

  // post a la db analytics un evento de performance, bq1 c:
  Future<PerformanceResponse> postPerformanceEvent(PerformanceRequest request) async {
    final response = await dio.post('/api/performance', data: request.toJson());
    return PerformanceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> postBQ6Event({
    required String eventName,
    required int userId,
    int? sellerId,
    double? avgResponseMinutes,
    int? unreadConversations,
    Map<String, dynamic>? properties,
  }) async {
    print('BQ6 sending event: $eventName');

    final response = await dio.post('/api/bq6/events/', data: {
      'event_name': eventName,
      'user_id': userId,
      'seller_id': sellerId,
      'avg_response_minutes': avgResponseMinutes,
      'unread_conversations': unreadConversations,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'properties': properties ?? {},
    });

    print('BQ6 response: ${response.statusCode}');
  }

  Future<void> postCrashEvent({
    required String featureName,
    required String codeLocation,
    required String crashSignature,
    String? stackTrace,
    String deviceModel = '',
    String platform = '',
    String osVersion = '',
    String appVersion = '1.0.0',
    Map<String, dynamic>? metadata,
  }) async {
    await dio.post('/api/bq1/events/', data: {
      'event_name': 'crash_occurred',
      'feature_name': featureName,
      'code_location': codeLocation,
      'crash_signature': crashSignature,
      'stack_trace': stackTrace ?? '',
      'device_model': deviceModel,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'metadata': metadata ?? {},
      'client_event_id': '${DateTime.now().millisecondsSinceEpoch}_${crashSignature.hashCode}',
    });
  }

  Future<void> sendBusinessEvent({
    required String eventName,
    required String listingId,
    int? buyerUserId,
    int? sellerUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await dio.post('/api/business-events', data: {
      'event_name': eventName,
      'listing_id': listingId,
      'buyer_user_id': buyerUserId,
      'seller_user_id': sellerUserId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'metadata': metadata ?? {},
      'client_event_id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }
}
