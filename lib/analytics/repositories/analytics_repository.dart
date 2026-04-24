import '../data/analytics_api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final AnalyticsApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Future<void> postPerformanceEvent(PerformanceRequest request) async {
    await apiClient.postPerformanceEvent(request);
  }

  Future<void> postBQ6Event({
    required String eventName,
    required int userId,
    int? sellerId,
    double? avgResponseMinutes,
    int? unreadConversations,
    Map<String, dynamic>? properties,
  }) async {
    await apiClient.postBQ6Event(
      eventName: eventName,
      userId: userId,
      sellerId: sellerId,
      avgResponseMinutes: avgResponseMinutes,
      unreadConversations: unreadConversations,
      properties: properties,
    );
  }

  Future<void> sendBusinessEvent({
    required String eventName,
    required String listingId,
    Map<String, dynamic>? metadata,
  }) async {
    await apiClient.sendBusinessEvent(
      eventName: eventName,
      listingId: listingId,
      metadata: metadata,
    );
  }
}
