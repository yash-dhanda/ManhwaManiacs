import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/server_instant.dart';
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';

/// The states of glass 8.15.7 (J), all in the paper colours.

/// The empty chapter's line.
const String kNovelEmptyText = 'This chapter came through empty. The source answered with no text; the page may have been pulled or is still being published.';

/// The skeleton's line widths (J): 92, 78, 96, 64, 88 % repeating, 12 lines at the body line height.
const List<double> kNovelSkeletonWidths = [0.92, 0.78, 0.96, 0.64, 0.88];

/// The loading page: paper-coloured skeleton lines with the sheen tinted to the ink at 5 % (a 1400 ms loop, phase-offset 60 ms per
/// line; static under Reduce Motion), shown only after 180 ms.
class NovelLoadingPage extends ConsumerStatefulWidget {
  const NovelLoadingPage({super.key, required this.lineHeight, required this.width, this.top = 120});
  final double lineHeight, width, top;

  @override
  ConsumerState<NovelLoadingPage> createState() => _NovelLoadingPageState();
}

class _NovelLoadingPageState extends ConsumerState<NovelLoadingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;
  Timer? _delay;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _delay = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _shown = true);
      if (!GlassMotion.isReduced()) {
        final e = GlassMotion.recorder.begin(MotionName.skeletonShimmer.label, 1400);
        unawaited(_sheen.repeat().whenComplete(() => GlassMotion.recorder.end(e)));
      }
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    if (!_shown) return const SizedBox.expand();
    final reduced = ref.watch(glassReducedProvider);
    final bar = colors.ink.withValues(alpha: 0.14);
    final sheen = colors.ink.withValues(alpha: 0.05);
    return Semantics(
      label: 'Loading the chapter',
      liveRegion: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: widget.top),
          child: SizedBox(
            width: widget.width,
            child: AnimatedBuilder(
              animation: _sheen,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 12; i++)
                    SizedBox(
                      height: widget.lineHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: kNovelSkeletonWidths[i % kNovelSkeletonWidths.length],
                          child: Container(
                            key: ValueKey('novel-skeleton-$i'),
                            height: widget.lineHeight * 0.42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: bar,
                              gradient: reduced
                                  ? null
                                  : LinearGradient(
                                      colors: [bar, Color.alphaBlend(sheen, bar), bar],
                                      stops: const [0, 0.5, 1],
                                      begin: Alignment(-3 + 6 * ((_sheen.value - i * 60 / 1400) % 1), 0),
                                      end: Alignment(-1 + 6 * ((_sheen.value - i * 60 / 1400) % 1), 0),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Which full-screen state the reader shows instead of the text.
enum NovelFailureKind { offline, error, empty, unavailable, gated }

/// What a chapter failure is (J): unreachable while offline, the §8.0.10 unavailable codes, else an error.
NovelFailureKind novelFailureKind(Object? error, {required bool online}) {
  if (error is ApiError && const {'source_not_found', 'series_not_found', 'not_found', 'source_not_browsable', 'forbidden'}.contains(error.code)) {
    return NovelFailureKind.unavailable;
  }
  if (!online || error is NetworkError) return NovelFailureKind.offline;
  return NovelFailureKind.error;
}

/// A full-screen state in the paper colours: the object lens of the shell, its actions "Back to the book" (or "Back home" with no
/// title on a gated profile).
class NovelStateView extends StatelessWidget {
  const NovelStateView({super.key, required this.kind, required this.onBack, this.onHome, this.onRetry, this.error});
  final NovelFailureKind kind;
  final VoidCallback onBack;
  final VoidCallback? onHome;
  final VoidCallback? onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final back = LensAction('Back to the book', onBack);
    final lens = switch (kind) {
      NovelFailureKind.offline => GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: "You're offline", description: 'This chapter is not on the phone.', primary: back, onRetry: onRetry == null ? null : () async {
        onRetry!();
        return true;
      },),
      NovelFailureKind.error => GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't load this chapter", primary: back, secondary: onRetry == null ? null : LensAction('Try again', onRetry!)),
      NovelFailureKind.empty => GlassObjectLens(situation: LensSituation.nothingFound, title: 'This chapter came through empty.', description: 'The source answered with no text; the page may have been pulled or is still being published.', primary: back),
      NovelFailureKind.unavailable => GlassObjectLens(
          situation: LensSituation.unavailable,
          title: error is AppError ? errorEntry(error! as AppError).copy : "This isn't here any more",
          primary: back,
        ),
      NovelFailureKind.gated => GlassObjectLens(situation: LensSituation.unavailable, title: "This isn't available on this profile", primary: LensAction('Back home', onHome ?? onBack)),
    };
    return ColoredBox(color: colors.bg, child: lens);
  }
}

/// "Saved copy · 2 h": the age from `cache.fetched_at`.
String novelCacheAge(String? iso, {DateTime? now}) {
  final t = serverInstant(iso);
  if (t == null) return '';
  final d = (now ?? DateTime.now()).toUtc().difference(t.toUtc());
  if (d.inHours < 1) return '${d.inMinutes.clamp(1, 59)} min';
  if (d.inHours < 48) return '${d.inHours} h';
  return '${d.inDays} d';
}
