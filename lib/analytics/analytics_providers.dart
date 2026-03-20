import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/analytics_bloc.dart';
import 'data/analytics_dio_client.dart';
import 'data/analytics_api_client.dart';
import 'repositories/analytics_repository.dart';
import 'data/device_info_service.dart';

class AnalyticsProviders extends StatelessWidget {
  final Widget child;
  final String analyticsBaseUrl;

  const AnalyticsProviders({
    super.key,
    required this.child,
    required this.analyticsBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final dio = createAnalyticsDio(baseUrl: analyticsBaseUrl);
    final apiClient = AnalyticsApiClient(dio: dio);
    final repository = AnalyticsRepository(apiClient: apiClient);
    final deviceInfo = DeviceInfoService();

    return BlocProvider(
      create: (_) =>
          AnalyticsBloc(repository: repository, deviceInfo: deviceInfo),
      child: child,
    );
  }
}
