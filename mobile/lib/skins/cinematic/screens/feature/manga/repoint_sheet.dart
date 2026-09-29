import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/utils/repoint_mapping.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Move to another source (repoint): candidates, then the mapping sentence,
/// `Keep following it on … too`, and `Move`. TODO(mobile/06): `CineSheetRoute`.
Future<void> showRepointSheet(BuildContext context, FeatureData data,
        {required bool sourceIsDown,}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cineOf(context).colorPaper2,
      builder: (_) => _RepointSheet(data: data, sourceIsDown: sourceIsDown),
    );

class _RepointSheet extends ConsumerStatefulWidget {
  const _RepointSheet({required this.data, required this.sourceIsDown});
  final FeatureData data;
  final bool sourceIsDown;

  @override
  ConsumerState<_RepointSheet> createState() => _RepointSheetState();
}

class _RepointSheetState extends ConsumerState<_RepointSheet> {
  List<({String sourceName, GlobalSearchItem item})>? _candidates;
  bool _failed = false;
  ({String sourceName, GlobalSearchItem item})? _picked;
  ({double from, double to})? _range;
  bool _keepOld = false;
  bool _moving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _candidates = null;
      _failed = false;
    });
    final r = await ref.read(sourcesRepositoryProvider).searchGrouped(widget.data.title);
    if (!mounted) return;
    if (r.isErr) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _candidates = [
        for (final g in r.value.groups)
          if (!g.isLocal && g.source != widget.data.sourceId)
            for (final i in g.items) (sourceName: g.sourceName, item: i),
      ];
    });
  }

  Future<void> _pick(({String sourceName, GlobalSearchItem item}) c) async {
    setState(() {
      _picked = c;
      _range = null;
    });
    final r =
        await ref.read(sourcesRepositoryProvider).getChapters(c.item.source!, c.item.seriesId);
    if (!mounted || r.isErr) return;
    final nums = [
      for (final ch in r.value)
        if (ch.number != null) ch.number!,
    ]..sort();
    setState(() => _range = nums.isEmpty ? null : (from: nums.first, to: nums.last));
  }

  Future<void> _move() async {
    final p = _picked!;
    final f = widget.data.followed;
    if (f == null) return;
    setState(() {
      _moving = true;
      _error = null;
    });
    final r = await ref.read(libraryRepositoryProvider).repoint(
          f.id,
          sourceId: p.item.source!,
          seriesKey: p.item.seriesId,
          keepOld: _keepOld,
        );
    if (!mounted) return;
    if (r.isErr) {
      setState(() {
        _moving = false;
        _error = "Couldn't move this series.";
      });
      return;
    }
    ref.invalidate(updatesProvider);
    final nav = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final n = r.value.mappedChapterNumber;
    messenger.showSnackBar(
      SnackBar(
          content: Text(
              "Moved to ${p.sourceName}.${n == null ? '' : " You're on chapter ${n % 1 == 0 ? n.toInt() : n}."}",),),
    );
    unawaited(nav.pushReplacement<void>(Routes.feature(p.item.source!, p.item.seriesId)));
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final picked = _picked;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sourceIsDown) ...[
              Text('NOTE', style: kickerStyle(context, color: t.colorSpot)),
              const Text('This source is down. Move the series to another source to keep reading.'),
              const SizedBox(height: 12),
            ],
            Text('MOVE TO ANOTHER SOURCE', style: kickerStyle(context)),
            const SizedBox(height: 8),
            if (picked == null) ...[
              if (_failed) ...[
                Text('CORRECTION', style: kickerStyle(context)),
                TextButton(onPressed: _search, child: const Text('Retry')),
              ] else if (_candidates == null)
                const LinearProgressIndicator(minHeight: 2)
              else if (_candidates!.isEmpty)
                const Text('No other source has this series.')
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in _candidates!)
                        ListTile(
                          minVerticalPadding: 12,
                          title: Text(c.item.title),
                          subtitle: Text(c.sourceName),
                          onTap: () => _pick(c),
                        ),
                    ],
                  ),
                ),
            ] else ...[
              Text(
                mappingSentence(
                  currentNumber: null, // TODO: the follow's current chapter number
                  candidateRange: _range,
                  sourceName: picked.sourceName,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _keepOld,
                onChanged: (v) => setState(() => _keepOld = v ?? false),
                title: Text('Keep following it on ${widget.data.sourceId} too'),
              ),
              if (_error != null) Text(_error!, style: TextStyle(color: t.colorProof)),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _moving ? null : () => setState(() => _picked = null),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _moving ? null : _move,
                    child: Text(_error != null ? 'Try again' : 'Move'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
