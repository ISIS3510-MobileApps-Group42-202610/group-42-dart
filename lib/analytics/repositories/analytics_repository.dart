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
    await apiClient.postCrashEvent(
      featureName: featureName,
      codeLocation: codeLocation,
      crashSignature: crashSignature,
      stackTrace: stackTrace,
      deviceModel: deviceModel,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      metadata: metadata,
    );
  }

  Future<void> sendBusinessEvent({
    required String eventName,
    required String listingId,
    int? buyerUserId,
    int? sellerUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await apiClient.sendBusinessEvent(
      eventName: eventName,
      listingId: listingId,
      buyerUserId: buyerUserId,
      sellerUserId: sellerUserId,
      metadata: metadata,
    );
  }
}
