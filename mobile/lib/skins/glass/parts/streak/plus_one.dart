import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// Plus one (glass 4.10): "+1" in `caption1` 700, `streakCore`, rising 12 px from the streak chip on `celebrate`, held 1,200 ms, then
/// `fadeOut`. Plays once per flare while mounted; under reduced motion it only fades (150 ms) in place. Anchored over its child.
class GlassPlusOne extends ConsumerStatefulWidget {
  const GlassPlusOne({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassPlusOne> createState() => _GlassPlusOneState();
}

class _GlassPlusOneState extends ConsumerState<GlassPlusOne> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 643 + 1200 + 120));
  GlassMotionEntry? _entry;

  @override
  void initState() {
    super.initState();
    // A flare while Home was not mounted plays on this build (once: the shown count is session state).
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    final ui = ref.read(streakUiProvider);
    if (ui.plusOne > ui.plusOneShown) {
      ref.read(streakUiProvider.notifier).plusOnePlayed();
      _play();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _play() {
    _entry = GlassMotion.recorder.begin(MotionName.plusOne.label, 643);
    _c.forward(from: 0).whenComplete(() {
      if (_entry != null) GlassMotion.recorder.end(_entry!);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(streakUiProvider.select((s) => s.plusOne), (_, __) => _check());
    final reduced = ref.watch(glassReducedProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: -4,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final ms = _c.value * 1963;
                  if (_c.value == 0 || _c.isCompleted) return const SizedBox.shrink();
                  final rise = reduced ? 0.0 : 12 * Curves.easeOutBack.transform((ms / 643).clamp(0.0, 1.0));
                  final opacity = reduced
                      ? (ms < 150
                          ? ms / 150
                          : ms > 1350
                              ? (1 - (ms - 1350) / 150).clamp(0.0, 1.0)
                              : 1.0)
                      : (ms < 643 + 1200 ? 1.0 : (1 - (ms - 1843) / 120).clamp(0.0, 1.0));
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(offset: Offset(0, -rise), child: GlassLabel('+1', role: gt.typeCaption1, wght: 700, color: gt.colorStreakCore)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
