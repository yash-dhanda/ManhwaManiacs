import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_not_available_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const List<int> _ragged = [92, 78, 96, 64, 88];

/// The chapter loading (cinematic 8.15.9): 12 greeked lines at the body's line height in
/// `galley` bars at the 7.17 ragged widths, Flickering at half strength (opacity 0.775 to 1 over a
/// 1400 ms half-period; static at 0.8 under reduced motion).
class NovelLoadingPage extends StatefulWidget {
  const NovelLoadingPage({super.key, required this.lineHeight, required this.width});

  final double lineHeight, width;

  @override
  State<NovelLoadingPage> createState() => _NovelLoadingPageState();
}

class _NovelLoadingPageState extends State<NovelLoadingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CineMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galley = context.cine.colorGalley;
    final reduced = CineMotion.reduced(context);
    return ExcludeSemantics(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 96),
          child: SizedBox(
            width: widget.width,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Opacity(
                opacity: reduced ? 0.8 : 0.775 + 0.225 * Curves.easeInOut.transform(_c.value),
                child: Column(
                  children: [
                    for (var i = 0; i < 12; i++)
                      SizedBox(
                        height: widget.lineHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(widthFactor: _ragged[i % _ragged.length] / 100, heightFactor: 0.5, child: ColoredBox(key: const Key('novel-galley-bar'), color: galley)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a chapter that did not open shows, in the stock colours: the `NOT IN THIS ISSUE` notice
/// for a removed or gated book (worded identically for both), the `SLOW DOWN` band with the live
/// countdown, or "Couldn't load this chapter." with `Back to the book`.
class NovelFailureView extends StatelessWidget {
  const NovelFailureView({super.key, required this.error, required this.onRetry, required this.onBack});

  final AppError error;
  final VoidCallback onRetry, onBack;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiError ? error as ApiError : null;
    final kind = notAvailableKind(error) ?? (api != null && api.isNotFound ? NotAvailableKind.series : null);
    if (kind != null) return CineNotAvailableNotice(kind: kind);
    if (api != null && api.statusCode == 429) {
      return _Pad(
        child: CineNotice(
          tone: CineNoticeTone.rateLimit,
          headline: 'Slow down for a moment.',
          wholeScreen: true,
          retryAfter: api.retryAfter ?? const Duration(seconds: 10),
          onRetry: onRetry,
          primary: CineNoticeAction('Back to the book', onBack),
        ),
      );
    }
    return _Pad(
      child: CineNotice(
        tone: CineNoticeTone.error,
        headline: "Couldn't load this chapter.",
        wholeScreen: true,
        primary: CineNoticeAction('Back to the book', onBack),
        quiet: CineNoticeAction('Try again', onRetry),
      ),
    );
  }
}

/// A chapter with no paragraphs.
class NovelEmptyView extends StatelessWidget {
  const NovelEmptyView({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _Pad(
        child: CineNotice(
          tone: CineNoticeTone.empty,
          headline: 'This chapter came through empty — usually a page that was pulled or is still being published.',
          wholeScreen: true,
          primary: CineNoticeAction('Back to the book', onBack),
        ),
      );
}

class _Pad extends StatelessWidget {
  const _Pad({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: child);
}
