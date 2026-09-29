import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';

/// Debug switches (cinematic 8.30.7): in memory, so they reset on restart.
final layoutGridOverlayProvider = StateProvider<bool>((ref) => false, name: 'layoutGridOverlay');

/// A `StateProvider<bool>` in every way a caller sees (`.state`, `.notifier.state`), except
/// that turning it on or off switches the [MotionRecorder].
class _MotionOverlay extends StateController<bool> {
  _MotionOverlay() : super(false);

  @override
  set state(bool v) {
    MotionRecorder.instance.recording = v;
    super.state = v;
  }
}

final motionTimingsOverlayProvider = StateNotifierProvider<StateController<bool>, bool>(
  (ref) {
    ref.onDispose(() => MotionRecorder.instance.recording = false);
    return _MotionOverlay();
  },
  name: 'motionTimingsOverlay',
);
