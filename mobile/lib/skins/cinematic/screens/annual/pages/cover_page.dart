import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/authed_cover.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/colophon_page.dart' show italicOf;
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

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
  for (final a in env.annual.shareable?.artSeries ?? const <ArtSeries>[]) {
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
                (r) => r.onLongPress = covers.isEmpty ? null : () => _openLightbox(context, ref, covers.first.url, env.annual.topSeries.isEmpty ? '' : env.annual.topSeries.first.title),
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
                    i < covers.length ? Hero(tag: i == 0 ? 'annual-cover' : 'annual-cover-$i', child: AnnualArt(url: covers[i].url, duo: parseAmbientHex(covers[i].duo))) : const ColoredBox(color: CineColors.paper1),
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
        if (a.partial) CineRoleText('YOUR YEAR SO FAR', t.typeKicker, color: CineColors.ink60),
        AnnualTitle('The Annual', italicOf(t.typeCover), id: 'cover', level: 1),
        const SizedBox(height: 4),
        Semantics(
          label: '${a.year}',
          excludeSemantics: true,
          child: TypedHeadline('${a.year}', style: CineText.style(context, t.typeNumeral).copyWith(color: CineColors.ink100, fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()]), cap: t.typeNumeral.cap),
        ),
        const SizedBox(height: 8),
        CineRoleText(coverDeck(env.profileName), t.typeDeck, color: CineColors.ink80),
        const SizedBox(height: 8),
        CineRoleText(issueLine(issue, a.until ?? env.now), t.typeFolio, color: CineColors.ink60),
      ],),
    );
  }
}

/// A 450 ms long press on the art opens the Lightbox (cinematic 7.30) on the top cover.
void _openLightbox(BuildContext context, WidgetRef ref, String url, String title) {
  unawaited(openCineLightbox(
    context,
    heroTag: 'annual-cover',
    image: ref.read(authedCoverProvider)(url),
    title: title,
    folio: 'COVER',
  ),);
}
