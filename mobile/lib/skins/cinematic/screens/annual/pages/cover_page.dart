import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cover.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/letter_reveal.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The covers of the 3 x 3 mosaic: the top series first, then the shareable art
/// series without repeats, up to nine.
List<({String url, String? duo})> mosaicCovers(AnnualEnv env) {
  final seen = <String>{};
  final out = <({String url, String? duo})>[];
  void add(String source, String key, String? url, String? duo) {
    if (url == null || out.length >= 9 || !seen.add('$source/$key')) return;
    out.add((url: url, duo: duo));
  }

  for (final s in env.annual.topSeries) {
    add(s.sourceId, s.seriesKey, s.coverUrl, s.ambient?.duo);
  }
  for (final a in env.annual.shareable?.artSeries ?? const []) {
    add(a.sourceId, a.seriesKey, a.coverUrl, a.ambient?.duo);
  }
  return out;
}

/// Page 1: the cover. A 3 x 3 mosaic in duotone, the masthead, the year typed,
/// the deck and the issue line. A 450 ms long press on the art opens the Lightbox.
class AnnualCoverPage extends ConsumerWidget {
  const AnnualCoverPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final a = env.annual;
    final covers = mosaicCovers(env);
    final provider = ref.watch(coverImageProvider);
    final issue = issueNumber(a.year, a.availableYears);
    final mosaic = LayoutBuilder(builder: (context, box) {
      final side = box.maxWidth;
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top + 56),
          child: RawGestureDetector(
            gestures: {
              LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 450)),
                (r) => r.onLongPress = covers.isEmpty ? null : () => showCoverLightbox(context, provider(covers.first.url)),
              ),
            },
            child: SizedBox(
              width: side,
              height: side,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < 9; i++)
                    i < covers.length ? DuotoneImage(image: provider(covers[i].url), duo: parseHex(covers[i].duo)) : const ColoredBox(color: CineColors.paper1),
                ],
              ),
            ),
          ),
        ),
      );
    },);
    return AnnualPageFrame(
      annual: a,
      artOverride: mosaic,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (a.partial) CineText('YOUR YEAR SO FAR', t.typeKicker, color: CineColors.ink60),
        SetHeading('The Annual', role: t.typeCover, level: 1),
        const SizedBox(height: 4),
        TypedNumeral('${a.year}', semanticsLabel: '${a.year}'),
        const SizedBox(height: 8),
        CineText(coverDeck(env.profileName), t.typeDeck, color: CineColors.ink80),
        const SizedBox(height: 8),
        CineText(issueLine(issue, a.until ?? env.now), t.typeFolio, color: CineColors.ink60),
      ],),
    );
  }
}

/// TODO(mobile/05): the Lightbox primitive (7.30) owns this; a black, tap-to-close
/// full-screen view of the cover until then.
void showCoverLightbox(BuildContext context, ImageProvider image) {
  Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    barrierColor: CineColors.lightbox,
    barrierLabel: 'Close cover',
    pageBuilder: (context, _, __) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Semantics(label: 'Cover. Tap to close.', image: true, child: InteractiveViewer(child: Center(child: Image(image: image, fit: BoxFit.contain)))),
    ),
  ),);
}
