import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroine/heroine.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart' show sourceGenresProvider;
import 'package:manhwamaniacs/features/sources/providers/series_enrichment_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_link.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show SpringCurve;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_form_route.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show HomeCoverImage;
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart' show SpotlightTilt;
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:url_launcher/url_launcher.dart';

/// The series URL the share action copies.
String seriesShareUrl(WidgetRef ref, GlassSeriesData d) => '${ref.read(apiBaseUrlProvider).replaceFirst(RegExp(r'/api/?$'), '')}${Routes.feature(d.sourceId, d.seriesKey)}';

void copySeriesLink(WidgetRef ref, GlassSeriesData d) {
  unawaited(Clipboard.setData(ClipboardData(text: seriesShareUrl(ref, d))));
  showGlassToast(ref, const GlassToastSpec('Link copied'));
}

/// "Updated 2 d ago" from a release date string.
String? updatedAgo(String? raw, DateTime now) {
  final t = raw == null ? null : DateTime.tryParse(raw);
  if (t == null) return null;
  final d = now.difference(t);
  if (d.inDays >= 1) return 'Updated ${d.inDays} d ago';
  if (d.inHours >= 1) return 'Updated ${d.inHours} h ago';
  return 'Updated today';
}

/// The top band (glass 8.12 Top band): the cover's blurred enlargement in the series palette fading to black, [height] 280 on phones and
/// tablet frames, 240 on the desktop frame; the nav row's trailing glass group (share, bookmarks, ⋯) sits inside it.
class SeriesBand extends ConsumerWidget {
  const SeriesBand({super.key, required this.data, required this.height, required this.onMore, this.leading, this.topInset = 0});
  final double topInset;
  final GlassSeriesData data;
  final double height;
  final void Function(Rect anchor) onMore;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final cover = d.series.coverUrl;
    return SizedBox(
      key: const ValueKey('series-band'),
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            ExcludeSemantics(
              child: Opacity(
                opacity: 0.6,
                child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36, tileMode: TileMode.decal), child: Transform.scale(scale: 1.4, child: HomeCoverImage(url: cover))),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xFF000000)], stops: [0.35, 1])),
          ),
          Positioned(
            top: 8 + topInset,
            left: 12,
            right: 12,
            child: Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
                Builder(
                  builder: (c) => GlassGroup(
                    key: const ValueKey('series-band-group'),
                    twin: windowTwin(context),
                    items: [
                      GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.arrowSquareOut.regular), label: 'Share', onPressed: () => copySeriesLink(ref, d)),
                      GlassGroupItem(
                        icon: GlassButtonIcon(GlassGlyph.bookmarkSimple.regular),
                        label: 'Bookmarks for this series',
                        onPressed: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.bookmarks({'source': d.sourceId, 'series': d.seriesKey}))),
                      ),
                      GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.dotsThree.regular), label: 'More', onPressed: () => onMore(rectOf(c))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// In the desktop window (a `materialThick` content slab, glass 7.10) the page's controls are content twins, not live glass.
GlassTwin? windowTwin(BuildContext context) => ModalRoute.of(context) is GlassFormRoute ? GlassTwin.content : null;

/// A widget's global rect.
Rect rectOf(BuildContext c) {
  final box = c.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Whether the hero tilt may read the accelerometer now (glass 15.7): this route on top, the app resumed, tickers on, the preference on
/// and motion not reduced.
class SeriesTiltGate extends ConsumerStatefulWidget {
  const SeriesTiltGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SeriesTiltGate> createState() => _SeriesTiltGateState();
}

class _SeriesTiltGateState extends ConsumerState<SeriesTiltGate> with WidgetsBindingObserver {
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = WidgetsBinding.instance.lifecycleState;
    _resumed = s == null || s == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => setState(() => _resumed = state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _resumed &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        ref.watch(glassInAppPrefsProvider.select((p) => p.lightFollowsDevice)) &&
        !ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return SpotlightTilt(key: const ValueKey('series-tilt'), active: active, child: widget.child);
  }
}

/// The header cover (112 × 168, radius 14; the desktop frame's 240 × 360): the poster zoom lands here, the hero tilt moves it, and a
/// tap opens the image viewer.
class SeriesCover extends ConsumerWidget {
  const SeriesCover({super.key, required this.data, required this.width, required this.height, this.onTap, this.velocity});
  final GlassSeriesData data;
  final double width, height;
  final VoidCallback? onTap;
  final Velocity? velocity;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
        button: onTap != null,
        label: 'Cover of ${data.title}',
        onTap: onTap,
        child: GestureDetector(
          excludeFromSemantics: true, // the labelled Semantics above carries the tap; the detector's own node was an unlabelled twin
          onTap: onTap,
          onScaleStart: onTap == null ? null : (_) {},
          onScaleUpdate: onTap == null ? null : (s) {
            if (s.pointerCount > 1 && s.scale > 1.08) onTap!();
          },
          child: SeriesTiltGate(
            child: GlassCoverHero(
              sourceId: data.sourceId,
              seriesKey: data.seriesKey,
              releaseVelocity: velocity,
              child: ClipRRect(
                key: const ValueKey('series-cover'),
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(width: width, height: height, child: HomeCoverImage(url: data.series.coverUrl, width: width)),
              ),
            ),
          ),
        ),
      );
}

/// The title block (glass 8.12 Header): title `title1` with the letter reveal, the byline, tags, the facts and the enrichment line.
class SeriesTitleBlock extends ConsumerWidget {
  const SeriesTitleBlock({super.key, required this.data, required this.mature, this.titleFocus});
  final GlassSeriesData data;
  final bool mature;
  final FocusNode? titleFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final s = d.series;
    final enrichment = ref.watch(seriesEnrichmentProvider((sourceId: d.sourceId, seriesKey: d.seriesKey))).valueOrNull;
    final by = [if (s.author != null && s.author!.isNotEmpty) 'by ${s.author}', if (s.artist != null && s.artist!.isNotEmpty && s.artist != s.author) 'art by ${s.artist}'].join(' · ');
    final latest = d.chapters.isEmpty ? null : d.readingOrder.last.releaseDate;
    final facts = [
      '${d.chapters.isNotEmpty ? d.chapters.length : s.chapterCount} chapters',
      if (updatedAgo(latest, DateTime.now()) case final u?) u,
    ].join(' · ');
    final score = enrichment == null
        ? null
        : [
            if (enrichment.score != null) '★ ${enrichment.score!.toStringAsFixed(1)}',
            if (enrichment.format != null) _format(enrichment.format!),
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          focusNode: titleFocus,
          child: Semantics(
            container: true, // LetterReveal carries the one header node (G2)
            child: LetterReveal(s.title, role: gt.typeTitle1, screenId: 'series', wght: 700, maxLines: 3),
          ),
        ),
        if (by.isNotEmpty) ...[const SizedBox(height: 4), GlassLabel(by, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2)],
        const SizedBox(height: 8),
        SeriesTags(data: d, mature: mature),
        const SizedBox(height: 8),
        GlassLabel(facts, key: const ValueKey('series-facts'), role: gt.typeCaption1, color: gt.colorLabel2),
        if (score != null && score.isNotEmpty) ...[const SizedBox(height: 2), GlassLabel(score, key: const ValueKey('series-score'), role: gt.typeCaption1, color: gt.colorLabel2)],
      ],
    );
  }

  static String _format(String f) => switch (f.toUpperCase()) {
        'MANGA' => 'Manga',
        'MANHWA' => 'Manhwa',
        'MANHUA' => 'Manhua',
        'NOVEL' => 'Novel',
        'ONE_SHOT' => 'One shot',
        _ => f[0].toUpperCase() + f.substring(1).toLowerCase(),
      };
}

/// The status tag, the first [limit] genres (linked when the source lists them) and the 18+ badge.
class SeriesTags extends ConsumerWidget {
  const SeriesTags({super.key, required this.data, required this.mature, this.limit = 4});
  final GlassSeriesData data;
  final bool mature;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final genres = ref.watch(sourceGenresProvider(d.sourceId)).valueOrNull ?? const [];
    final status = d.series.status;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (status != null && status.isNotEmpty) GlassChip(label: status[0].toUpperCase() + status.substring(1).toLowerCase(), kind: GlassChipKind.tag),
        for (final g in d.series.genres.take(limit))
          Builder(builder: (c) {
            final to = genreRoute(d.sourceId, g, genres);
            final id = to == null ? null : Uri.parse(to).queryParameters['genre'];
            final chip = GlassChip(
              label: g,
              kind: GlassChipKind.tag,
              onPressed: to == null ? null : () => unawaited(ref.read(skinRouterProvider).push<void>(to)),
            );
            return id == null ? chip : GenreFlight(tag: 'genre-${d.sourceId}-$id', child: chip);
          },),
        if (mature) const GlassBadge.mature(),
      ],
    );
  }
}

/// Read officially (glass 8.12): up to 3 site chips from the enrichment, opened externally.
class OfficialLinks extends ConsumerWidget {
  const OfficialLinks({super.key, required this.data});
  final GlassSeriesData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(seriesEnrichmentProvider((sourceId: data.sourceId, seriesKey: data.seriesKey))).valueOrNull;
    if (e == null || e.official.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('series-official'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassLabel('Read officially', role: gt.typeFootnote, color: gt.colorLabel2, wght: 600),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final o in e.official.take(3))
            GlassChip(
              label: o.site,
              kind: GlassChipKind.assist,
              onPressed: () async {
                var ok = false;
                try {
                  ok = await launchUrl(Uri.parse(o.url), mode: LaunchMode.externalApplication);
                } catch (_) {}
                if (!ok) showGlassToast(ref, GlassToastSpec("Couldn't open ${o.site}", kind: GlassToastKind.error));
              },
            ),
        ],),
      ],
    );
  }
}

/// The description: `body`, 3 lines with "More" expanding on `springSnappy`.
class SeriesDescription extends StatefulWidget {
  const SeriesDescription({super.key, required this.text, this.literata = false});
  final String text;
  final bool literata;

  @override
  State<SeriesDescription> createState() => _SeriesDescriptionState();
}

class _SeriesDescriptionState extends State<SeriesDescription> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: gt.springSnappy.ms),
            curve: SpringCurve(gt.springSnappy),
            alignment: Alignment.topCenter,
            child: GlassLabel(widget.text, key: const ValueKey('series-description'), role: gt.typeBody, color: gt.colorLabel2, maxLines: _open ? 200 : 3),
          ),
          if (!_open && widget.text.length > 140)
            GlassButton(label: 'More', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, hang: true, onPressed: () => setState(() => _open = true)),
        ],
      );
}

/// The Tag flight (glass 4.10): the genre text flies to the catalogue's chip on `springZoom`.
class GenreFlight extends ConsumerWidget {
  const GenreFlight({super.key, required this.tag, required this.child});
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return Heroine(tag: tag, motion: reduced ? const CurvedMotion(Duration(milliseconds: 200)) : glassZoomMotion(), child: child);
  }
}

/// The follow state for a series, from the shared follow cache.
bool followPending(WidgetRef ref) => ref.watch(updatesProvider.select((s) => s.valueOrNull?.actionPending ?? false));

String resolveCover(WidgetRef ref, String url) => url.isEmpty ? url : resolveApiResourceUrl(ref.read(apiBaseUrlProvider), url);
