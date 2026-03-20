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
