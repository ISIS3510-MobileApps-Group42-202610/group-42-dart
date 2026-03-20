import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

// para medir el tiempo de startup
class TrackAppStartup extends AnalyticsEvent {
  final double durationMs;

  const TrackAppStartup({required this.durationMs});

  @override
  List<Object?> get props => [durationMs];
}

// medir el tiempo entre pantallas
class TrackScreenNavigation extends AnalyticsEvent {
  final double durationMs;

  const TrackScreenNavigation({required this.durationMs});

  @override
  List<Object?> get props => [durationMs];
}

class TrackBusinessEvent extends AnalyticsEvent {
  final String eventName;
  final String listingId;
  final int? buyerUserId;
  final int? sellerUserId;
  final Map<String, dynamic>? metadata;

  const TrackBusinessEvent({
    required this.eventName,
    required this.listingId,
    this.buyerUserId,
    this.sellerUserId,
    this.metadata,
  });

  @override
  List<Object?> get props => [eventName, listingId, buyerUserId, sellerUserId, metadata];
}
