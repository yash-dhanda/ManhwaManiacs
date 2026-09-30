import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_date.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero_phone.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_spread.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';

export 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_actions.dart' show ResumePoint;

/// Where `Read` / `Continue` goes, and what the split button says.
ResumePoint resumePoint(FeatureData d, WidgetRef ref) {
  final order = d.readingOrder;
  if (order.isEmpty) return (label: 'Read', chapter: null, sub: null);
  final progress =
      ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
  String? lastKey;
  DateTime? at;
  for (final e in progress.entries) {
    if (at == null || e.value.updatedAt.isAfter(at)) {
      lastKey = e.key;
      at = e.value.updatedAt;
    }
  }
  String num(int i) => order[i].number?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '${i + 1}';
  if (lastKey == null) return (label: 'Read', chapter: order.first.id, sub: 'CH ${num(0)}');
  final i = order.indexWhere((c) => c.id == lastKey);
  if (i < 0) return (label: 'Read', chapter: order.first.id, sub: 'CH ${num(0)}');
  final p = progress[lastKey]!;
  if (!p.completed) return (label: 'Continue', chapter: lastKey, sub: 'CH ${num(i)} · p.${p.page}');
  if (i + 1 < order.length) {
    return (label: 'Continue', chapter: order[i + 1].id, sub: 'CH ${num(i + 1)}');
  }
  return (label: 'All caught up', chapter: null, sub: null);
}

/// The cover, its `Hero` and the Lightbox long-press. Drift (26 s, 1.00 to
/// 1.06) runs on the art only; reduced motion holds it at 1.03.
class FeatureCover extends StatefulWidget {
  const FeatureCover({
    super.key,
    required this.url,
    required this.heroTag,
    required this.onCover,
    this.drift = true,
  });

  final String? url;
  final Object heroTag;
  final VoidCallback onCover;
  final bool drift;

  @override
  State<FeatureCover> createState() => _FeatureCoverState();
}

class _FeatureCoverState extends State<FeatureCover> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: CineDur.drift);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.drift && !CineMotion.reduced(context)) {
      _started = true;
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
    final t = cineOf(context);
    final reduced = CineMotion.reduced(context);
    final image = widget.url == null
        ? ColoredBox(color: t.colorPaper2)
        : Image.network(
            widget.url!,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => ColoredBox(color: t.colorPaper2),
          );
    return Semantics(
      label: 'Cover. Long press to view.',
      onLongPress: widget.onCover,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPress: widget.onCover,
        child: Hero(
          tag: widget.heroTag,
          transitionOnUserGestures: Theme.of(context).platform == TargetPlatform.iOS,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final v = reduced || !widget.drift ? (reduced ? 0.5 : 0.0) : CineCurves.drift.transform(_c.value);
                return Transform.translate(
                  offset: Offset(-0.01 * 390 * v, -0.015 * 500 * v),
                  child: Transform.scale(scale: 1 + 0.06 * v, child: child),
                );
              },
              child: image,
            ),
          ),
        ),
      ),
    );
  }
}

/// Credits rows (§7.28) that set in reading order after the title lands:
/// 320 ms `settle` each, 24 ms apart, capped at 360 ms of stagger.
class CreditsBlock extends StatefulWidget {
  const CreditsBlock({super.key, required this.rows, this.trailing});
  final List<(String, String)> rows;
  final Widget? trailing;

  @override
  State<CreditsBlock> createState() => _CreditsBlockState();
}

class _CreditsBlockState extends State<CreditsBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (CineMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final stagger = (24 * widget.rows.length).clamp(0, 360);
    _c.duration = Duration(milliseconds: 320 + stagger);
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) unawaited(_c.forward());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _c.duration?.inMilliseconds ?? 1;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final ms = _c.value * total;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.rows.length; i++)
              Builder(builder: (context) {
                final p = CineCurves.settle
                    .transform(((ms - (24 * i).clamp(0, 360)) / 320).clamp(0.0, 1.0));
                return Opacity(
                  opacity: p,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - p)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 72, child: Text(widget.rows[i].$1, style: kickerStyle(context))),
                          Expanded(child: Text(widget.rows[i].$2)),
                        ],
                      ),
                    ),
                  ),
                );
              },),
            if (widget.trailing != null) widget.trailing!,
          ],
        );
      },
    );
  }
}

/// What the phone hero and the tablet spread both draw.
class HeroParts {
  const HeroParts({
    required this.kicker,
    required this.title,
    required this.deck,
    required this.credits,
    required this.actions,
    required this.cover,
    required this.progressFraction,
  });
  final Widget kicker, title, credits, actions, cover;
  final Widget? deck;
  final double progressFraction;
}

/// The phone hero (4:5 cover, title block) or the tablet spread, plus the
/// actions and credits.
class FeatureHero extends ConsumerWidget {
  const FeatureHero({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onCover,
    required this.commands,
    this.onOverflow,
  });

  final FeatureData data;
  final VoidCallback onSelect;
  final VoidCallback onCover;
  final FeatureCommands commands;
  final VoidCallback? onOverflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = cineOf(context);
    final amb = CineAmbient.of(context);
    final d = data;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final base = ref.watch(apiBaseUrlProvider);
    final cover = d.followed != null
        ? followedSeriesCoverUrl(base, d.followed!)
        : sourceSeriesCoverUrl(base, d.sourceId, d.seriesKey);
    final tag = d.followed != null
        ? seriesCoverHeroTag(d.followed!.id)
        : 'cover-${d.sourceId}-${d.seriesKey}';
    final resume = resumePoint(d, ref);
    final s = d.series;
    final kicker = [
      'MANHWA',
      if (s.status != null) s.status!.toUpperCase(),
      '${d.chapters.length} CHAPTERS',
    ].join(' · ');

    final source = ref.watch(sourcesListProvider).valueOrNull?.cast<SourceSummary?>().firstWhere(
          (x) => x!.id == d.sourceId,
          orElse: () => null,
        );
    final newest = [for (final c in d.chapters) c.releaseDate].whereType<String>().toList();
    final updated = newest.isEmpty ? null : chapterDateLabel(newest.first);
    final matureOpen = d.followed?.rating == 'mature' &&
        (ref.watch(matureContentProvider).valueOrNull ?? false);
    final credits = CreditsBlock(
      trailing: matureOpen
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Semantics(
                label: 'Rated 18 plus',
                child: Icon(CineGlyphs.certificate18Regular, size: 20, color: t.colorInk100),
              ),
            )
          : null,
      rows: [
      if (s.author != null && s.author!.isNotEmpty) ('STORY', s.author!),
      if (s.artist != null && s.artist!.isNotEmpty) ('ART', s.artist!),
      ('SOURCE', source?.name ?? d.sourceId),
      if (s.status != null) ('STATUS', s.status!.toUpperCase()),
      if (updated != null) ('UPDATED', updated.toUpperCase()),
    ],);

    final headline = [wide ? 44.0 : 32.0, wide ? 40.0 : 28.0, wide ? 36.0 : 24.0];
    final titleWidget = SetHeading(
      s.title,
      id: 'feature-${s.title}',
      cap: t.typeCover.cap,
      level: 1,
      trigger: SetTrigger.signal,
      style: TextStyle(
        fontSize: setHeadingSize(s.title, headline),
        height: wide ? 48 / 44 : 36 / 32,
        color: t.colorInk100,
        fontWeight: FontWeight.w700,
      ),
    );
    final deckText = s.description == null || s.description!.trim().isEmpty
        ? null
        : s.description!.trim().split(RegExp(r'(?<=[.!?])\s')).first;
    final parts = HeroParts(
      kicker: Text(kicker, style: kickerStyle(context, color: amb.ink)),
      title: titleWidget,
      deck: deckText == null
          ? null
          : Text(deckText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: t.colorInk60),),
      credits: credits,
      actions: FeatureActions(
        data: d,
        resume: resume,
        wide: wide,
        onSelect: onSelect,
        commands: commands,
        onOverflow: onOverflow,
      ),
      cover: FeatureCover(url: cover, heroTag: tag, onCover: onCover),
      progressFraction: d.chapters.isEmpty
          ? 0
          : (ref
                      .watch(sourceSeriesProgressProvider(
                          (sourceId: d.sourceId, seriesId: d.seriesKey),),)
                      .values
                      .where((p) => p.completed)
                      .length /
                  d.chapters.length)
              .clamp(0.0, 1.0),
    );
    return wide ? FeatureSpread(parts: parts) : FeaturePhoneHero(parts: parts);
  }
}
