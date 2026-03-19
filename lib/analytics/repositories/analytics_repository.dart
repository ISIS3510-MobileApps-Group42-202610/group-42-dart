import '../data/analytics_api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final AnalyticsApiClient api;

  AnalyticsRepository({required AnalyticsApiClient apiClient})
    : api = apiClient;

  Future<void> postPerformanceEvent(PerformanceRequest request) async {
    await api.postPerformanceEvent(request);
  }
}
