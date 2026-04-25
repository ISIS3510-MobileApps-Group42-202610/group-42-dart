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
    on<TrackBQ6Event>(onTrackBQ6Event);
    on<TrackCrashEvent>(onTrackCrashEvent);
    on<TrackBusinessEvent>((event, emit) async {
      try {
        await repository.sendBusinessEvent(
          eventName: event.eventName,
          listingId: event.listingId,
          metadata: event.metadata,
        );
      } catch (e) {
        print('BQ6 ERROR: $e');
        emit(AnalyticsError(message: e.toString()));
      }
    });
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

  Future<void> onTrackCrashEvent(
    TrackCrashEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      await repository.postCrashEvent(
        featureName: event.featureName,
        codeLocation: event.codeLocation,
        crashSignature: event.crashSignature,
        stackTrace: event.stackTrace,
        deviceModel: deviceInfo.deviceModel,
        platform: deviceInfo.platform,
        osVersion: deviceInfo.osVersion,
        appVersion: appVersion,
        metadata: event.metadata,
      );
      emit(const AnalyticsIdle());
    } catch (e) {
      // Silently ignore — crash reporting must never cascade into another crash
      emit(const AnalyticsIdle());
    }
  }

  Future<void> onTrackBQ6Event(
      TrackBQ6Event event,
      Emitter<AnalyticsState> emit,
      ) async {
    try {
      await repository.postBQ6Event(
        eventName: event.eventName,
        userId: event.userId,
        sellerId: event.sellerId,
        avgResponseMinutes: event.avgResponseMinutes,
        unreadConversations: event.unreadConversations,
        properties: event.properties,
      );

      emit(const AnalyticsIdle());
    } catch (e) {
      emit(AnalyticsError(message: e.toString()));
    }
  }
}
