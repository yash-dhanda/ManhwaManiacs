/// The chapter boundary (glass 8.16.2, E11): when a chapter's audio ends, a card "Next chapter in 5" with a ring draining over 5 s,
/// "Play now" and "Cancel"; when it completes playback continues into the next chapter (the reader, when open, swaps its text in
/// place). The countdown pauses while focus is inside the card and does not start while a screen reader is on (the card then waits for
/// "Play now"). `autoPlayNext` off: no card, playback just stops. Reduced motion: a `mono` "5 s ... 1 s" count instead of the ring.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show RingPainter;
import 'package:manhwamaniacs/skins/glass/type.dart';

const Duration kPostPlayCountdown = Duration(seconds: 5);

/// The chapter that just ended and is waiting for its follow-up; null when nothing waits.
final glassPostPlayProvider = StateProvider<NovelChapterKey?>((ref) => null, name: 'glassPostPlay');

/// How many players are open (the card shows inside the player, else over the screen).
final glassPlayerOpenProvider = StateProvider<int>((ref) => 0, name: 'glassPlayerOpen');

/// Whether an ended chapter raises the card: the shared setting, and not a sleep-timer stop.
bool postPlayShows({required bool autoPlayNext, required bool sleepStop}) => autoPlayNext && !sleepStop;

/// Seconds shown for a countdown at [remaining] ("5" ... "1").
int postPlaySeconds(Duration remaining) => (remaining.inMilliseconds / 1000).ceil().clamp(0, 5);

class GlassPostPlayCard extends ConsumerStatefulWidget {
  const GlassPostPlayCard({super.key, this.onGlass = true});
  final bool onGlass;

  @override
  ConsumerState<GlassPostPlayCard> createState() => _GlassPostPlayCardState();
}

class _GlassPostPlayCardState extends ConsumerState<GlassPostPlayCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: kPostPlayCountdown);
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'post-play');
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _scope.addListener(_onFocus);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _advance();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // A screen reader waits for "Play now".
      if (!MediaQuery.accessibleNavigationOf(context)) unawaited(_c.forward());
    }
  }

  @override
  void dispose() {
    _scope.removeListener(_onFocus);
    _scope.dispose();
    _c.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_scope.hasFocus) {
      _c.stop();
    } else if (!MediaQuery.accessibleNavigationOf(context) && !_c.isCompleted && !_c.isAnimating) {
      unawaited(_c.forward());
    }
  }

  void _advance() {
    ref.read(glassPostPlayProvider.notifier).state = null;
    unawaited(ref.read(glassNarrationActionsProvider).changeChapter(next: true));
  }

  void _cancel() {
    _c.stop();
    ref.read(glassPostPlayProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final onGlass = widget.onGlass;
    return FocusScope(
      node: _scope,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'Next chapter',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.superellipse(24).border(const Size(340, 96))),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final remaining = kPostPlayCountdown * (1 - _c.value);
                  final secs = postPlaySeconds(remaining);
                  return SizedBox(
                    width: 44,
                    height: 44,
                    child: reduced
                        ? Center(child: GlassText('$secs s', role: gt.typeMono, onGlass: onGlass, maxLines: 1))
                        : CustomPaint(painter: RingPainter(v: 1 - _c.value, stroke: 3, color: gt.colorIris500), child: Center(child: GlassText('$secs', role: gt.typeMono, onGlass: onGlass))),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => GlassText(
                    _c.isAnimating || _c.isCompleted ? 'Next chapter in ${postPlaySeconds(kPostPlayCountdown * (1 - _c.value))}' : 'Next chapter',
                    role: gt.typeHeadline,
                    onGlass: onGlass,
                    maxLines: 2,
                    maxScale: 1.5,
                  ),
                ),
              ),
              GlassButton(label: 'Play now', size: GlassButtonSize.small, variant: GlassButtonVariant.primary, onPressed: _advance),
              const SizedBox(width: 8),
              GlassButton(label: 'Cancel', size: GlassButtonSize.small, onPressed: _cancel),
            ],
          ),
        ),
      ),
    );
  }
}

/// Listens for a chapter's end and raises the card (mounted once, by the listen layer).
class GlassPostPlayWatcher extends ConsumerStatefulWidget {
  const GlassPostPlayWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassPostPlayWatcher> createState() => _GlassPostPlayWatcherState();
}

class _GlassPostPlayWatcherState extends ConsumerState<GlassPostPlayWatcher> {
  StreamSubscription<NarrationEnded>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(narrationControllerProvider.notifier).ended.listen((e) {
      if (!mounted) return;
      final auto = ref.read(listenSettingsValueProvider).autoPlayNext;
      ref.read(glassPostPlayProvider.notifier).state = postPlayShows(autoPlayNext: auto, sleepStop: e.sleepStop) ? e.key : null;
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(glassPostPlayProvider);
    final open = ref.watch(glassPlayerOpenProvider) > 0;
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (waiting != null && !open)
          Positioned(left: 0, right: 0, bottom: 96, child: SafeArea(child: GlassPostPlayCard(key: ValueKey(waiting)))),
      ],
    );
  }
}
