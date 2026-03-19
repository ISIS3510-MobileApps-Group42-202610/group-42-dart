// ============================================================================
// Definition of backend DTOs for the analytics requests

// Post BQ2 DTO
class PerformanceRequest {
  final String eventType;
  final String deviceModel;
  final String platform;
  final double durationMs;
  final String osVersion;
  final String appVersion;

  // instancia
  const PerformanceRequest({
    required this.eventType,
    required this.deviceModel,
    required this.platform,
    required this.durationMs,
    required this.osVersion,
    required this.appVersion,
  });

  // mappear en json
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'device_model': deviceModel,
    'platform': platform,
    'duration_ms': durationMs,
    'os_version': osVersion,
    'app_version': appVersion,
  };
}

// BQ2 DTO
class PerformanceResponse {
  final String status;

  const PerformanceResponse({required this.status});

  factory PerformanceResponse.fromJson(Map<String, dynamic> json) =>
      PerformanceResponse(status: json['status'] as String ?? 'ok');

  Map<String, dynamic> toJson() => {'status': status};
}
