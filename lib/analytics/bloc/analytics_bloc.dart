// el bloc del analytics, muy similar al de auth

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/analytics_repository.dart';
import '../models/analytics_models.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
import '../data/device_info_service.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;
  final DeviceInfoService deviceInfo;
  final String appVersion;

  // igual que en el auth, declarar todos los escenarios
  AnalyticsBloc({
    required this.repository,
    required this.deviceInfo,
    this.appVersion = '1.0.0', // esto cambiara en el futuro xd
  }) : super(const AnalyticsIdle()) {
    on<TrackAppStartup>(onTrackAppStartup);
    on<TrackScreenNavigation>(onTrackScreenNavigation);
  }

  // escenario donde se hace el trackeo en startup para el bq1
  Future<void> onTrackAppStartup(
    TrackAppStartup event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      await repository.postPerformanceEvent(
        PerformanceRequest(
          eventType: 'app_startup',
          deviceModel: deviceInfo.deviceModel,
          platform: deviceInfo.platform,
          durationMs: event.durationMs,
          osVersion: deviceInfo.osVersion,
          appVersion: appVersion,
        ),
      );
      emit(const AnalyticsIdle()); // por si acaso
    } catch (e) {
      emit(AnalyticsError(message: e.toString()));
    }
  }

  // escenario donde se hace el trackeo entre pantashas
  Future<void> onTrackScreenNavigation(
    TrackScreenNavigation event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      await repository.postPerformanceEvent(
        PerformanceRequest(
          eventType: 'screen_navigation',
          deviceModel: deviceInfo.deviceModel,
          platform: deviceInfo.platform,
          durationMs: event.durationMs,
          osVersion: deviceInfo.osVersion,
          appVersion: appVersion,
        ),
      );
      emit(const AnalyticsIdle()); // por si acaso
    } catch (e) {
      emit(AnalyticsError(message: e.toString()));
    }
  }
}
