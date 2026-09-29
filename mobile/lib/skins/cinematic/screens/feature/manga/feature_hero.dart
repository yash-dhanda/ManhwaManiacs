import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Where `Read` / `Continue` goes, and what the split button says.
({String label, String? chapter, String? sub}) resumePoint(FeatureData d, WidgetRef ref) {
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

/// The phone hero (4:5 cover, title block) or the tablet spread, plus the
/// actions and credits. Ambient colour comes from the fallback tokens until
/// `CineAmbient` lands (mobile/04).
class FeatureHero extends ConsumerWidget {
  const FeatureHero({super.key, required this.data, required this.onSelect, required this.onCover});

  final FeatureData data;
  final VoidCallback onSelect;
  final VoidCallback onCover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = cineOf(context);
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
    final titleSize = s.title.length > 40 ? 24.0 : (s.title.length > 24 ? 28.0 : 32.0);

    Widget art() => GestureDetector(
          onLongPress: onCover,
          child: Hero(
            tag: tag,
            transitionOnUserGestures: Theme.of(context).platform == TargetPlatform.iOS,
            child: cover == null
                ? ColoredBox(color: t.colorPaper2)
                : Image.network(cover,
                    fit: BoxFit.cover, errorBuilder: (c, e, s) => ColoredBox(color: t.colorPaper2),),
          ),
        );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: kickerStyle(context, color: t.colorAmbientFallbackInk)),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            s.title,
            style: TextStyle(fontSize: wide ? 44 : titleSize, height: 1.1, color: t.colorInk100),
          ),
        ),
        if (s.description != null && s.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            s.description!.trim().split(RegExp(r'(?<=[.!?])\s')).first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: t.colorInk60),
          ),
        ],
      ],
    );

    final primary = SizedBox(
      width: wide ? null : double.infinity,
      child: FilledButton(
        key: const Key('primary-action'),
        style: FilledButton.styleFrom(minimumSize: Size(wide ? 200 : 0, 48)),
        onPressed: resume.chapter == null
            ? null
            : () => context.push(Routes.reader(d.sourceId, d.seriesKey, resume.chapter!)),
        child: Text(resume.sub == null ? resume.label : '${resume.label}  │  ${resume.sub}'),
      ),
    );

    final readAll = d.chapters.length > 1
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.view_stream_outlined, size: 20),
            label: const Text('Read all'),
            onPressed: () => context.push(Routes.readAll(d.sourceId, d.seriesKey)),
          )
        : null;

    final f = d.followed;
    Future<void> toggleFollow() async {
      final n = ref.read(updatesProvider.notifier);
      final err = f == null
          ? await n.followSeries(sourceId: d.sourceId, seriesKey: d.seriesKey)
          : await n.unfollow(f.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null
                  ? err.userMessage
                  : f == null
                      ? 'Following ${d.title}. New chapters will notify you.'
                      : 'Removed ${d.title}.',
            ),
          ),
        );
      }
    }

    Widget iconBtn(IconData icon, String label, VoidCallback? onTap, {bool on = false}) => Expanded(
          child: Semantics(
            button: true,
            selected: on,
            label: label,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: on ? t.colorSpot : t.colorInk100),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label.toUpperCase(),
                          maxLines: 1, style: const TextStyle(fontSize: 10, letterSpacing: 0.6),),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    final iconRow = Row(
      children: [
        iconBtn(f == null ? Icons.add : Icons.check, 'Follow', toggleFollow, on: f != null),
        iconBtn(
          f?.isFavorite ?? false ? Icons.star : Icons.star_border,
          'Favourite',
          f == null
              ? null
              : () async {
                  await ref
                      .read(libraryRepositoryProvider)
                      .patchSeries(f.id, isFavorite: !f.isFavorite);
                  ref.invalidate(updatesProvider);
                },
          on: f?.isFavorite ?? false,
        ),
        iconBtn(
          f?.notify ?? false ? Icons.notifications_active : Icons.notifications_none,
          'Notify',
          f == null
              ? null
              : () async {
                  await ref.read(libraryRepositoryProvider).patchSeries(f.id, notify: !f.notify);
                  ref.invalidate(updatesProvider);
                },
          on: f?.notify ?? false,
        ),
        iconBtn(Icons.cloud_download_outlined, 'Download', onSelect),
      ],
    );

    Widget credit(String k, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(k, style: kickerStyle(context))),
                Expanded(child: Text(v)),
              ],
            ),
          );
    final credits = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        credit('STORY', s.author),
        credit('ART', s.artist),
        credit('SOURCE', d.sourceId),
        credit('STATUS', s.status?.toUpperCase()),
      ],
    );

    if (wide) {
      final h = (MediaQuery.sizeOf(context).height * 0.64).clamp(520.0, 760.0);
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: SizedBox(
          height: h,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      titleBlock,
                      const SizedBox(height: 16),
                      credits,
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, children: [primary, if (readAll != null) readAll]),
                      iconRow,
                    ],
                  ),
                ),
              ),
              Expanded(flex: 4, child: art()),
            ],
          ),
        ),
      );
    }

    final screenH = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;
    final heroH = (w * 1.25).clamp(0.0, screenH * 0.70);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(height: heroH, width: double.infinity, child: art()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, t.colorAmbientFallbackTint],
                    stops: const [0.5, 1],
                  ),
                ),
              ),
            ),
            Positioned(left: 16, right: 16, bottom: 0, child: titleBlock),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              primary,
              if (readAll != null) ...[
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: readAll),
              ],
              const SizedBox(height: 8),
              iconRow,
              const SizedBox(height: 8),
              credits,
            ],
          ),
        ),
      ],
    );
  }
}
