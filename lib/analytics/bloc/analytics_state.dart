import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

// no hay nada ocurriendo en cuanto a analitica (sera quizas mas util en
//otras bqs)
class AnalyticsIdle extends AnalyticsState {
  const AnalyticsIdle();
}
