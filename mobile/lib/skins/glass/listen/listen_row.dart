/// The listen row (glass 8.16.1, D1): a `glassRegular` (T3) capsule 48 px tall, 8 px above the novel reader's bottom capsule: the
/// narrating voice's orb, "Ch 12 · Aurora", play/pause, and a 2 px progress line along its bottom edge. It is a shape of the bottom
/// capsule's group (one layer, `NovelBottomCapsule.listenRow`), shows with the chrome and lingers 5000 ms after it hides unless pinned.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const double kListenRowHeight = 48;
const Duration kListenRowLinger = Duration(milliseconds: 5000);

/// The row's width: the capsule's, and 320 floating bottom-right on a landscape phone (glass 8.14.11).
double listenRowWidth(double capsuleWidth, {required bool landscapePhone}) => landscapePhone ? 320 : capsuleWidth;

/// Whether the row is up: with the chrome, or lingering [kListenRowLinger] after it hid, or always while pinned.
class ListenRowLinger extends StatefulWidget {
  const ListenRowLinger({super.key, required this.chromeShown, required this.pinned, required this.builder});
  final bool chromeShown, pinned;
  final Widget Function(BuildContext context, bool visible) builder;

  @override
  State<ListenRowLinger> createState() => _ListenRowLingerState();
}

class _ListenRowLingerState extends State<ListenRowLinger> {
  Timer? _timer;
  bool _lingering = false;

  @override
  void didUpdateWidget(ListenRowLinger old) {
    super.didUpdateWidget(old);
    if (old.chromeShown && !widget.chromeShown) {
      _lingering = true;
      _timer?.cancel();
      _timer = Timer(kListenRowLinger, () {
        if (mounted) setState(() => _lingering = false);
      });
    } else if (widget.chromeShown) {
      _timer?.cancel();
      _lingering = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.chromeShown || _lingering || widget.pinned);
}

/// The row's content, sized by the capsule group: [width] x 48.
class GlassListenRowBody extends ConsumerWidget {
  const GlassListenRowBody({super.key, required this.width});
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    if (t == null) return const SizedBox.shrink();
    final voice = ref.watch(glassNarratorProvider(t.key));
    final actions = ref.read(glassNarrationActionsProvider);
    final phase = listenPhaseOf(s);
    final pinned = ref.watch(glassListenRowPinnedProvider);
    final narr = ref.read(narrationControllerProvider.notifier);
    final total = t.audio.totalMs;
    return ListenGestures(
      pinned: pinned,
      onTogglePin: () => ref.read(glassListenRowPinnedProvider.notifier).state = !pinned,
      onOpen: actions.openPlayer,
      onNext: () => unawaited(actions.changeChapter(next: true)),
      onPrevious: () => unawaited(actions.changeChapter(next: false)),
      onStop: () => unawaited(actions.stopWithUndo()),
      onHide: () => unawaited(actions.pauseWithUndo(() => ref.read(glassListenRowHiddenProvider.notifier).state = true)),
      child: SizedBox(
        width: width,
        height: kListenRowHeight,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 2),
              child: Row(
                children: [
                  ListenVoiceOrb(hue: voice.hue, initial: voice.initial),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: 'Now narrating, ${glassNarratingLine(t, voice.name)}. Open the player',
                      excludeSemantics: true,
                      child: GlassText(glassNarratingLine(t, voice.name, short: true), role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
                    ),
                  ),
                  ListenSleepCountdown(narration: narr),
                  ListenPlayButton(phase: phase, onTap: () => phase == ListenPhase.failed ? unawaited(narr.retry()) : unawaited(actions.toggle())),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: ValueListenableBuilder<int>(
                valueListenable: narr.position,
                builder: (context, pos, _) => ValueListenableBuilder<int>(
                  valueListenable: narr.buffered,
                  builder: (context, buf, _) => ListenProgressLine(progress: total <= 0 ? 0 : pos / total, buffered: total <= 0 ? 0 : buf / total),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
