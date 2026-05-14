// el bloc del analytics, muy similar al de auth

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/analytics_repository.dart';
import '../models/analytics_models.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
import '../data/device_info_service.dart';
import 'package:dio/dio.dart';


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
        final normalizedEventName = event.eventName.trim();

        final allowedEvents = {
          'listing_viewed',
          'listing_opened',
          'view_listing',
          'product_viewed',
          'chat_started',
          'chat_opened',
          'conversation_started',
          'first_message_sent',
          'message_sent',
          'transaction_completed',
          'sale_completed',
          'purchase_completed',
          'listing_sold',
          'product_sold',
        };

        if (!allowedEvents.contains(normalizedEventName)) {
          print(
            'Business analytics skipped: invalid event_name=$normalizedEventName',
          );
          emit(const AnalyticsIdle());
          return;
        }

        final parsedListingId = int.tryParse(event.listingId.trim());

        if (parsedListingId == null || parsedListingId <= 0) {
          print(
            'Business analytics skipped: invalid listingId=${event.listingId}, '
                'eventName=$normalizedEventName',
          );
          emit(const AnalyticsIdle());
          return;
        }

        if (normalizedEventName == 'first_message_sent') {
          if (event.buyerUserId == null || event.sellerUserId == null) {
            print(
              'Business analytics skipped: first_message_sent requires '
                  'buyerUserId and sellerUserId.',
            );
            emit(const AnalyticsIdle());
            return;
          }

          if (event.buyerUserId == event.sellerUserId) {
            print(
              'Business analytics skipped: buyerUserId and sellerUserId '
                  'cannot be the same.',
            );
            emit(const AnalyticsIdle());
            return;
          }
        }

        await repository.sendBusinessEvent(
          eventName: normalizedEventName,
          listingId: parsedListingId.toString(),
          buyerUserId: event.buyerUserId,
          sellerUserId: event.sellerUserId,
          metadata: event.metadata,
        );

        emit(const AnalyticsIdle());
      } catch (e) {
        if (e is DioException) {
          print(
            'Business analytics event failed but app continues. '
                'Status: ${e.response?.statusCode}. '
                'Data: ${e.response?.data}',
          );
        } else {
          print('Business analytics event failed but app continues: $e');
        }

        emit(const AnalyticsIdle());
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
      print('BQ6 analytics event failed but app continues: $e');
      emit(const AnalyticsIdle());
    }
  }
}
