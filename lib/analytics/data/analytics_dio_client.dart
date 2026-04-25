import 'package:dio/dio.dart';

// dio brando para el analytics backend
Dio createAnalyticsDio({
  required String baseUrl,
}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
        // Static token for BQ1 crash event ingestion (authenticated endpoint)
        'X-Analytics-Token': 'unimarket-bq1-ingest-2026',
      },
    ),
  );
}
