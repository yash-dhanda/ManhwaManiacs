import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

// Everything drawn inside the strip is a content twin (glass 2.4.1): seams, seam cards, the broken-page lens and the end cards
// never read the backdrop.

/// The number in a chapter title ("Chapter 143", "Ch. 12.5"), or null.
double? chapterNumberOf(String? title) {
  if (title == null) return null;
  final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(title);
  return m == null ? null : double.tryParse(m.group(1)!);
}

/// The chapters missing between [from] and [to] (143 -> 145 is "144"); empty when they follow or the numbers are unknown.
List<String> missingBetween(String? from, String? to) {
  final a = chapterNumberOf(from), b = chapterNumberOf(to);
  if (a == null || b == null || a != a.roundToDouble() || b != b.roundToDouble() || b - a <= 1) return const [];
  return [for (var n = a.round() + 1; n < b.round(); n++) '$n'];
}

String _upper(String? title) => (title ?? '').toUpperCase();

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 24), color: gt.colorSeparator);
}

/// The 96 px seam between chapters (glass 8.14.4): a hairline, "CHAPTER 144" in `caption1` +0.2 em revealed letter by letter when
/// the seam enters, the title in `footnote` `label2`, a hairline; a `warning` row when chapters are missing from the source.
class GlassChapterSeam extends StatelessWidget {
  const GlassChapterSeam({super.key, required this.from, required this.to, this.slim = false});
  final String? from;
  final String? to;

  /// Read-all: 48 px, no card and no pause.
  final bool slim;

  @override
  Widget build(BuildContext context) {
    final missing = missingBetween(from, to);
    final n = chapterNumberOf(to);
    final label = n == null ? _upper(to) : 'CHAPTER ${n == n.roundToDouble() ? n.round() : n}';
    if (slim) {
      return Semantics(
        header: true,
        headingLevel: 2,
        label: to ?? '',
        excludeSemantics: true,
        child: Center(
          child: Row(children: [
            const Expanded(child: _Hairline()),
            GlassText(label, role: gt.typeCaption1, color: gt.colorLabel2),
            const Expanded(child: _Hairline()),
          ],),
        ),
      );
    }
    return Semantics(
      header: true,
      headingLevel: 2,
      label: [to ?? '', if (missing.isNotEmpty) 'Chapter ${missing.join(', ')} is missing from this source'].join('. '),
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Hairline(),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: const TextStyle(letterSpacing: 0.2 * 12),
            child: LetterReveal(label, role: gt.typeCaption1, color: gt.colorLabel1, revealKey: 'seam:$to', screenId: 'reader'),
          ),
          const SizedBox(height: 2),
          if (to != null && to!.toUpperCase() != label) GlassText(to!, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 4),
            // The note wraps inside the strip's margins rather than running off the screen.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(GlassGlyph.warning.regular, size: 14, color: gt.colorWarning),
                const SizedBox(width: 6),
                Flexible(child: GlassText('Chapter ${missing.join(', ')} ${missing.length == 1 ? 'is' : 'are'} missing from this source', role: gt.typeFootnote, color: gt.colorWarning)),
              ],),
            ),
          ],
          const SizedBox(height: 12),
          const _Hairline(),
        ],
      ),
    );
  }
}

/// A content-twin card in the strip (the failed-neighbour card, the end cards).
class StripCard extends StatelessWidget {
  const StripCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(color: gt.colorTwinDense, borderRadius: BorderRadius.circular(gt.radiusXl), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
              child: Padding(padding: const EdgeInsets.all(20), child: child),
            ),
          ),
        ),
      );
}

/// The bands of the strip (glass 8.14.4), built for the engine's `bandBuilder`.
class GlassReaderBands {
  const GlassReaderBands({
    required this.nextLabel,
    required this.previousLabel,
    required this.onRetryNeighbour,
    required this.onOpenNext,
    required this.onDownloadNext,
    this.backoff,
    this.readAll = false,
  });

  /// "Chapter 144" for the chapter after / before the strip.
  final String nextLabel, previousLabel;
  final VoidCallback onRetryNeighbour, onOpenNext, onDownloadNext;

  /// The engine's back-off before the next automatic retry.
  final Duration? backoff;
  final bool readAll;

  Widget build(BuildContext context, BandKind kind, {String? from, String? to, Duration? retryIn}) => switch (kind) {
        BandKind.seam => GlassChapterSeam(from: from, to: to, slim: readAll),
        BandKind.top => GlassChapterSeam(from: null, to: from),
        BandKind.topLoading => _Waiting(text: '$previousLabel is on its way'),
        BandKind.nextLoading => _Waiting(text: '$nextLabel is on its way'),
        BandKind.nextFailed => StripCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassText("$nextLabel didn't load", role: gt.typeHeadline, color: gt.colorLabel1, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    GlassButton(label: 'Try again', onPressed: onRetryNeighbour, twin: GlassTwin.content, size: GlassButtonSize.small),
                    GlassButton(label: 'Open it on its own', onPressed: onOpenNext, variant: GlassButtonVariant.plain, twin: GlassTwin.content, size: GlassButtonSize.small),
                  ],
                ),
              ],
            ),
          ),
        BandKind.offlineEnd => StripCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassText('$nextLabel needs a connection', role: gt.typeHeadline, color: gt.colorLabel1, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GlassButton(label: 'Download next 10 when online', onPressed: onDownloadNext, variant: GlassButtonVariant.plain, twin: GlassTwin.content, size: GlassButtonSize.small),
              ],
            ),
          ),
        BandKind.rateLimited => const _Waiting(text: 'The source is rate-limiting; pages will keep loading', warning: true),
      };
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warning) Icon(GlassGlyph.warning.regular, size: 16, color: gt.colorWarning) else const GlassSpinner(),
              const SizedBox(width: 8),
              Flexible(child: GlassText(text, role: gt.typeFootnote, color: warning ? gt.colorWarning : gt.colorLabel2)),
            ],
          ),
        ),
      );
}

/// A page box while it has no picture (glass 8.14.1): `#0B0B0F` and no spinner; broken: the 72 px lens with the `image-broken`
/// glyph, "This page didn't load" and Retry, which reloads only that image.
Widget glassPageState(BuildContext context, int page, PageStatus status, String? reason, VoidCallback retry) {
  if (status == PageStatus.placeholder) return const ColoredBox(color: Color(0xFF0B0B0F));
  return ColoredBox(
    color: const Color(0xFF0B0B0F),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: gt.colorTwinDense, shape: BoxShape.circle, border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
            child: Icon(GlassGlyph.imageBroken.regular, size: 32, color: gt.colorLabel2),
          ),
          const SizedBox(height: 12),
          GlassText("This page didn't load", role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 8),
          GlassButton(label: 'Retry', onPressed: retry, twin: GlassTwin.content, size: GlassButtonSize.small),
        ],
      ),
    ),
  );
}

/// The end card of the strip's last chapter (glass 8.14.4 "Caught up"): "You're caught up" and, when the series is not in the
/// library, the invitation to follow it.
class CaughtUpCard extends StatelessWidget {
  const CaughtUpCard({super.key, required this.nextNumber, required this.inLibrary, required this.onFollow, this.reactions});
  final String nextNumber;

  /// The finished chapter's reactions (mobile/43), above the caught-up line; the sent glyph lands in its strip.
  final Widget? reactions;
  final bool inLibrary;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) => StripCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reactions != null) ...[reactions!, const SizedBox(height: 16)],
            GlassText("You're caught up", role: gt.typeTitle3, color: gt.colorLabel1, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            GlassText("The source hasn't published chapter $nextNumber yet.", role: gt.typeFootnote, color: gt.colorLabel2, textAlign: TextAlign.center),
            if (!inLibrary) ...[
              const SizedBox(height: 16),
              GlassText('Add to library to hear about new chapters', role: gt.typeFootnote, color: gt.colorLabel2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              GlassButton(label: 'Add to library', onPressed: onFollow, variant: GlassButtonVariant.primary, twin: GlassTwin.content, size: GlassButtonSize.small),
            ],
          ],
        ),
      );
}
