import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `Add series` (cinematic 8.11): a sheet of the followed series not on the shelf. Tapping a row
/// adds it; the row then shows a `check` and `ADDED` and stays.
Future<void> showAddSeriesSheet(BuildContext context, {required int collectionId, required Set<String> memberKeys}) => showCineSheet<void>(
      context,
      kicker: 'ADD SERIES',
      title: 'Add series',
      builder: (ctx) => AddSeriesList(collectionId: collectionId, memberKeys: memberKeys),
    );

class AddSeriesList extends ConsumerStatefulWidget {
  const AddSeriesList({super.key, required this.collectionId, required this.memberKeys});
  final int collectionId;

  /// `"$sourceId\u0000$seriesKey"` of the members when the sheet opened.
  final Set<String> memberKeys;

  @override
  ConsumerState<AddSeriesList> createState() => _AddSeriesListState();
}

class _AddSeriesListState extends ConsumerState<AddSeriesList> {
  final _q = TextEditingController();
  final Set<int> _added = {}, _busy = {};

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _add(FollowedSeries s) async {
    if (_added.contains(s.id) || _busy.contains(s.id)) return;
    setState(() => _busy.add(s.id));
    final err = await ref.read(collectionDetailProvider(widget.collectionId).notifier).addSeries(sourceId: s.sourceId, seriesKey: s.seriesKey);
    if (!mounted) return;
    setState(() {
      _busy.remove(s.id);
      if (err == null) _added.add(s.id);
    });
    if (err != null) {
      ref.read(cineToastsProvider.notifier).error("Couldn't add ${s.title}.");
    } else {
      cineFeedback(context, HapticEvent.followAdd, sound: SoundEvent.followAdd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final all = ref.watch(librarySeriesPickerProvider);
    final names = {for (final s in ref.watch(sourcesListProvider).valueOrNull ?? const <SourceSummary>[]) s.id: s.name};
    final apiBase = ref.watch(apiBaseUrlProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineSearchField(semanticLabel: 'Search your library', placeholder: 'Search your library', variant: CineSearchVariant.compact, controller: _q, onChanged: (_) => setState(() {})),
        SizedBox(height: c.space3),
        all.when(
          loading: () => Column(children: [for (var i = 0; i < 4; i++) const CineRow(loading: true, title: '')]),
          error: (_, __) => CineRoleText("Your library didn't load.", c.typeCaption, color: c.colorProof),
          data: (rows) {
            final text = _q.text.trim().toLowerCase();
            final offered = [
              for (final s in rows)
                if ((!widget.memberKeys.contains('${s.sourceId}\u0000${s.seriesKey}') || _added.contains(s.id)) && (text.isEmpty || s.title.toLowerCase().contains(text))) s,
            ];
            if (offered.isEmpty) {
              return Padding(padding: EdgeInsets.symmetric(vertical: c.space4), child: CineRoleText('No series available.', c.typeBody, color: c.colorInk60));
            }
            return Column(children: [
              for (final s in offered)
                CineRow(
                  key: ValueKey('add-${s.id}'),
                  title: s.title,
                  caption: names[s.sourceId] ?? s.sourceId,
                  disabled: _busy.contains(s.id),
                  leading: SizedBox(width: 48, height: 72, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: followedSeriesCoverUrl(apiBase, s), title: s.title))),
                  trailing: _added.contains(s.id)
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const CineGlyphIcon(CineGlyph.check, size: 16),
                          SizedBox(width: c.space1),
                          CineRoleText('ADDED', c.typeFolio),
                        ],)
                      : null,
                  onTap: _added.contains(s.id) ? null : () => unawaited(_add(s)),
                ),
            ],);
          },
        ),
      ],),
    );
  }
}
