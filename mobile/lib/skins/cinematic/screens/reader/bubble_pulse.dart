import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
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
// The manga reader calls this, then pulses through its OcrOverlayController.
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
