import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/lift_store.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassLiftPhase;

export 'package:manhwamaniacs/features/library/providers/lift_store.dart' show LiftPhase, LiftState, liftProvider;

/// The `onLiftPhase` callback of a poster of [sourceId]:[seriesKey] (glass 9.3.4): writes the skin-neutral [liftProvider];
/// [rectOf] reads the poster's global rect.
ValueChanged<GlassLiftPhase> liftPhaseHandler(WidgetRef ref, {required String sourceId, required String seriesKey, required Rect Function() rectOf, bool mature = false}) {
  final notifier = ref.read(liftProvider.notifier);
  return (phase) {
    if (phase == GlassLiftPhase.ended) {
      final cur = notifier.state;
      if (cur != null && cur.sourceId == sourceId && cur.seriesKey == seriesKey) notifier.state = null;
      return;
    }
    final rect = rectOf();
    notifier.state = LiftState(
      sourceId: sourceId,
      seriesKey: seriesKey,
      mature: mature,
      phase: phase == GlassLiftPhase.growing ? LiftPhase.growing : LiftPhase.lifted,
      posterRect: rect,
      pointer: notifier.state?.pointer ?? rect.center,
    );
  };
}

/// The profile id of the friend orb holding the lifted poster (it swells to 1.2), or null.
final magnetHeldProvider = StateProvider<Object?>((ref) => null, name: 'glassMagnetHeld');

/// The profile id of the orb that just received a drop (it pulses on `springCelebrate`), or null.
final orbPulseProvider = StateProvider<int?>((ref) => null, name: 'glassOrbPulse');
