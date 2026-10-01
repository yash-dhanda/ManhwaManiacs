import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/tier_capsule.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/skins.dart';

typedef MoveCandidate = ({String sourceName, String? iconUrl, SourceHealth? health, GlobalSearchItem item});

GlassSourceHealth _bead(SourceHealth? h) => switch (h?.status) {
      SourceHealthStatus.ok => GlassSourceHealth.ok,
      SourceHealthStatus.failing => GlassSourceHealth.failing,
      SourceHealthStatus.dead => GlassSourceHealth.dead,
      _ => GlassSourceHealth.unknown,
    };

/// Move to another source… (`?sheet=move-source`, `large`, glass 8.12): the tier-1 search, then tier 2, the candidates, the mapping
/// line, "Keep the old one too" and the tinted Move (`POST /library/series/{id}/repoint {source_id, series_key, keep_old}`).
class MoveSourceSheet extends ConsumerStatefulWidget {
  const MoveSourceSheet({super.key, required this.data});
  final GlassSeriesData data;

  @override
  ConsumerState<MoveSourceSheet> createState() => _MoveSourceSheetState();
}

class _MoveSourceSheetState extends ConsumerState<MoveSourceSheet> {
  List<MoveCandidate> _candidates = [];
  bool _searching = true;
  int _pendingSources = 0;
  bool _failed = false;
  MoveCandidate? _picked;
  bool _keepOld = false;
  bool _moving = false;

  GlassSeriesData get d => widget.data;

  @override
  void initState() {
    super.initState();
    unawaited(_search(1));
  }

  Future<void> _search(int tier) async {
    final r = await ref.read(sourcesRepositoryProvider).searchGrouped(d.title, tier: tier);
    if (!mounted) return;
    if (r.isErr) {
      setState(() {
        _searching = false;
        _failed = _candidates.isEmpty;
      });
      return;
    }
    final v = r.value;
    setState(() {
      _candidates = [
        ..._candidates,
        for (final g in v.groups)
          if (!g.isLocal && g.source != d.sourceId)
            for (final i in g.items) (sourceName: g.sourceName, iconUrl: g.iconUrl, health: g.health, item: i),
      ];
      _pendingSources = v.nextTier == 2 ? v.sourcesDeferred : 0;
      _searching = v.nextTier == 2;
    });
    if (v.nextTier == 2 && tier == 1) await _search(2);
  }

  double? _currentNumber() {
    final progress = ref.read(sourceSeriesProgressProvider(d.progressKey));
    String? key;
    DateTime? at;
    for (final e in progress.entries) {
      if (at == null || e.value.updatedAt.isAfter(at)) {
        key = e.key;
        at = e.value.updatedAt;
      }
    }
    return d.chapters.where((c) => c.id == key).firstOrNull?.number;
  }

  Future<void> _move() async {
    final p = _picked, f = d.followed;
    if (p == null || f == null) return;
    setState(() => _moving = true);
    final r = await ref.read(libraryRepositoryProvider).repoint(f.id, sourceId: p.item.source!, seriesKey: p.item.seriesId, keepOld: _keepOld);
    if (!mounted) return;
    setState(() => _moving = false);
    if (r.isErr) {
      showGlassToast(ref, const GlassToastSpec("Couldn't move it. Try again", kind: GlassToastKind.error));
      return;
    }
    ref.invalidate(updatesProvider);
    showGlassToast(ref, GlassToastSpec('Moved to ${p.sourceName}', kind: GlassToastKind.success));
    final router = ref.read(skinRouterProvider);
    Navigator.of(context).pop();
    unawaited(router.pushReplacement<void>(Routes.feature(p.item.source!, p.item.seriesId), extra: const GlassNavExtra()));
  }

  @override
  Widget build(BuildContext context) {
    if (!isOnline(ref)) {
      return Padding(padding: const EdgeInsets.all(16), child: GlassLabel('Moving needs a connection', key: const ValueKey('move-offline'), role: gt.typeBody, color: gt.colorLabel2));
    }
    final picked = _picked;
    final current = _currentNumber();
    final n = chapterNum(current);
    // Scrolls when the candidates and the mapping outgrow the sheet (large text); on the sheets' 20 px gutter.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_searching) Align(alignment: Alignment.centerLeft, child: TierCapsule(results: _candidates.length, pending: _pendingSources, answered: 0, queried: 0)),
          if (!_searching && _candidates.isEmpty)
            GlassLabel(_failed ? "Couldn't search other sources" : 'No other source has this series', key: const ValueKey('move-none'), role: gt.typeBody, color: gt.colorLabel2),
          for (final c in _candidates)
            GlassListRow(
              key: ValueKey('move-${c.item.source}-${c.item.seriesId}'),
              title: c.item.title,
              subtitle: [c.sourceName, if (c.item.extra?['chapter_count'] case final num cc) '$cc chapters'].join(' · '),
              trailing: GlassHealthBead(status: _bead(c.health)),
              selectMode: true,
              selected: identical(c, picked),
              onTap: () => setState(() => _picked = c),
            ),
          if (picked != null) ...[
            const SizedBox(height: 16),
            GlassLabel(
              n == null ? "Your place couldn't be matched; you'll start from chapter 1" : "You're on chapter $n here. It becomes chapter $n on ${picked.sourceName}.",
              key: const ValueKey('move-mapping'),
              role: gt.typeBody,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            GlassSwitch(key: const ValueKey('move-keep-old'), value: _keepOld, label: 'Keep the old one too', onChanged: (v) => setState(() => _keepOld = v)),
            const SizedBox(height: 12),
            GlassButton(key: const ValueKey('move-go'), label: 'Move', variant: GlassButtonVariant.primary, loading: _moving, fullWidth: true, onPressed: _moving ? null : () => unawaited(_move())),
          ],
        ],
      ),
    );
  }
}
