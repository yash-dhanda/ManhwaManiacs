import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a poster lift is: growing at 150 ms, lifted at 450 ms, ended on release.
enum LiftPhase { growing, lifted, ended }

/// A poster, card or cover being lifted (glass 9.3.4): the recommend orbs appear while [phase] is `lifted`.
@immutable
class LiftState {
  const LiftState({required this.sourceId, required this.seriesKey, required this.phase, this.mature = false, this.posterRect = Rect.zero, this.pointer = Offset.zero});
  final String sourceId, seriesKey;
  final bool mature;
  final LiftPhase phase;
  final Rect posterRect;
  final Offset pointer;

  String get key => '$sourceId:$seriesKey';

  LiftState copyWith({LiftPhase? phase, Rect? posterRect, Offset? pointer}) =>
      LiftState(sourceId: sourceId, seriesKey: seriesKey, mature: mature, phase: phase ?? this.phase, posterRect: posterRect ?? this.posterRect, pointer: pointer ?? this.pointer);

  @override
  bool operator ==(Object other) => other is LiftState && other.key == key && other.mature == mature && other.phase == phase && other.posterRect == posterRect && other.pointer == pointer;

  @override
  int get hashCode => Object.hash(key, mature, phase, posterRect, pointer);
}

/// The lift in progress; null at rest. Skin-neutral: a skin's poster writes it.
final liftProvider = StateProvider<LiftState?>((ref) => null, name: 'lift');
