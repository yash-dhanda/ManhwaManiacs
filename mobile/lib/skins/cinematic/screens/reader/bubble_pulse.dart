import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Where a dialogue hit lands in the reader, and what to tell the reader.
class DialogueLanding {
  const DialogueLanding({this.page, this.box, required this.toast});

  final int? page;
  final OcrBox? box;

  /// `Found on page 12.` or the chapter-start line.
  final String toast;

  bool get found => page != null;
}

/// Resolves a taken [DialogueJump]: the page it names, else the first page
/// whose text matches (read from [loadPages], the chapter's OCR text).
/// Callers `jumpToPage(page)` when [DialogueLanding.found].
// The reader chrome mounts [DialogueLandingHost], which calls this.
Future<DialogueLanding> resolveDialogueLanding(
  DialogueJump jump,
  Future<List<PageText>?> Function() loadPages,
) async {
  var page = jump.page;
  if (page == null) {
    final pages = await loadPages();
    if (pages != null) page = findMatchPage(pages, jump.q);
  }
  if (page == null) {
    return const DialogueLanding(
      toast: 'Opened at the chapter start. The line is in this chapter.',
    );
  }
  return DialogueLanding(
      page: page, box: jump.box, toast: 'Found on page $page.',);
}

/// A 2 px `spot` frame around a matched bubble, drawn inside the page's own
/// box (fill the per-page overlay slot with it). Shows twice for 480 ms each
/// (opacity 0 -> 1 -> 0, `easeSettle`); once, static, for 960 ms under
/// reduced motion.
class BubblePulse extends StatefulWidget {
  const BubblePulse({super.key, required this.box, this.onDone});

  final OcrBox box;
  final VoidCallback? onDone;

  @override
  State<BubblePulse> createState() => _BubblePulseState();
}

class _BubblePulseState extends State<BubblePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;
  bool _reduced = false;
  Timer? _hold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = CineMotion.reduced(context);
    if (_reduced) {
      _hold = Timer(const Duration(milliseconds: 960), () {
        if (mounted) setState(() => _reduced = false);
        widget.onDone?.call();
      });
    } else {
      // Two 480 ms passes as one 960 ms run.
      _c.duration = const Duration(milliseconds: 960);
      unawaited(_c.forward().whenComplete(() => widget.onDone?.call()));
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, size) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // 0 -> 1 -> 0 within one 480 ms pass: a triangle eased by settle.
            final pass = _c.value >= 1 ? 1.0 : (_c.value * 2) % 1;
            final tri = pass < 0.5 ? pass * 2 : (1 - pass) * 2;
            final opacity = _reduced ? 1.0 : CineCurves.settle.transform(tri);
            final b = widget.box;
            return Stack(
              children: [
                Positioned(
                  left: b.x * size.maxWidth,
                  top: b.y * size.maxHeight,
                  width: b.w * size.maxWidth,
                  height: b.h * size.maxHeight,
                  child: Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border.all(color: t.colorSpot, width: 2),),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The reader-side hook of a dialogue jump. The Cinematic reader chrome wraps
/// its page view in this once; on first layout it takes the jump for this
/// chapter, calls [jumpToPage] (the engine's `jumpToPage`) with the matched
/// page, shows the toast, and hands [builder] a per-page overlay that draws
/// the [BubblePulse] on that page only.
///
/// The manga reader lands the same jump itself (`resolveDialogueLanding` plus its own
/// `OcrOverlayController` pulse); this host serves readers without that controller.
class DialogueLandingHost extends ConsumerStatefulWidget {
  const DialogueLandingHost({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.loadPages,
    required this.jumpToPage,
    required this.builder,
  });

  final String sourceId;
  final String seriesKey;
  final String chapterKey;
  final Future<List<PageText>?> Function() loadPages;
  final void Function(int page) jumpToPage;

  /// `pageOverlay(page)` goes in the reader's per-page overlay slot.
  final Widget Function(
      BuildContext context, Widget Function(int page) pageOverlay,) builder;

  @override
  ConsumerState<DialogueLandingHost> createState() =>
      _DialogueLandingHostState();
}

class _DialogueLandingHostState extends ConsumerState<DialogueLandingHost> {
  DialogueLanding? _landing;
  bool _pulsing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_land()));
  }

  Future<void> _land() async {
    final jump = ref
        .read(dialogueJumpProvider.notifier)
        .take(widget.sourceId, widget.seriesKey, widget.chapterKey);
    if (jump == null) return;
    final landing = await resolveDialogueLanding(jump, widget.loadPages);
    if (!mounted) return;
    if (landing.found) widget.jumpToPage(landing.page!);
    ref.read(cineToastsProvider.notifier).info(landing.toast);
    setState(() => _landing = landing);
  }

  Widget _overlay(int page) {
    final l = _landing;
    if (l == null || !_pulsing || !l.found || l.box == null || l.page != page) {
      return const SizedBox.shrink();
    }
    return BubblePulse(
      key: ValueKey('pulse-$page'),
      box: l.box!,
      onDone: () {
        if (mounted) setState(() => _pulsing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _overlay);
}
