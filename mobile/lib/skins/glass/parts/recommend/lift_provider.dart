import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassLiftPhase;

/// A poster, card or spotlight cover that is being lifted (glass 9.3.4): the friend orbs appear while [phase] is `lifted`.
@immutable
class GlassLift {
  const GlassLift({required this.sourceId, required this.seriesKey, required this.phase, required this.rect});
  final String sourceId, seriesKey;
  final GlassLiftPhase phase;
  final Rect rect;

  String get key => '$sourceId:$seriesKey';

  @override
  bool operator ==(Object other) => other is GlassLift && other.key == key && other.phase == phase && other.rect == rect;

  @override
  int get hashCode => Object.hash(key, phase, rect);
}

/// The lift in progress, fed by `GlassPoster.onLiftPhase`; null at rest.
final liftProvider = StateProvider<GlassLift?>((ref) => null, name: 'glassLift');

/// The `onLiftPhase` callback of a poster of [sourceId]:[seriesKey]; [rectOf] reads the poster's global rect.
ValueChanged<GlassLiftPhase> liftPhaseHandler(WidgetRef ref, {required String sourceId, required String seriesKey, required Rect Function() rectOf}) {
  final notifier = ref.read(liftProvider.notifier);
  return (phase) {
    if (phase == GlassLiftPhase.ended) {
      final cur = notifier.state;
      if (cur != null && cur.sourceId == sourceId && cur.seriesKey == seriesKey) notifier.state = null;
      return;
    }
    notifier.state = GlassLift(sourceId: sourceId, seriesKey: seriesKey, phase: phase, rect: rectOf());
  };
}

/// The profile id of the friend orb holding the lifted poster (it swells to 1.2), or null.
final magnetHeldProvider = StateProvider<Object?>((ref) => null, name: 'glassMagnetHeld');

/// The profile id of the orb that just received a drop (it pulses on `springCelebrate`), or null.
final orbPulseProvider = StateProvider<int?>((ref) => null, name: 'glassOrbPulse');
