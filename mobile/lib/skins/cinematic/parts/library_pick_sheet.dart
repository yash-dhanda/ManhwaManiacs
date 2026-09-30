import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A series chosen from the viewer's library.
class LibraryPick {
  const LibraryPick({required this.sourceId, required this.seriesKey, required this.title, this.coverUrl});
  final String sourceId, seriesKey, title;
  final String? coverUrl;
}

/// A sheet with a search field over the viewer's library and 48 x 72 covers; choosing a row closes it
/// with the [LibraryPick] (the member page's `Recommend something to Riya`, Settings' `Add a series`).
/// [exclude] are `source\u0000series` keys already chosen.
Future<LibraryPick?> showLibraryPickSheet(BuildContext context, {String kicker = 'YOUR LIBRARY', String title = 'Choose a series', Set<String> exclude = const {}}) => showCineSheet<LibraryPick>(
      context,
      kicker: kicker,
      title: title,
      builder: (ctx) => Material(type: MaterialType.transparency, child: LibraryPickList(exclude: exclude)),
    );

class LibraryPickList extends ConsumerStatefulWidget {
  const LibraryPickList({super.key, this.exclude = const {}});
  final Set<String> exclude;

  @override
  ConsumerState<LibraryPickList> createState() => _LibraryPickListState();
}

class _LibraryPickListState extends ConsumerState<LibraryPickList> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
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
                if (!widget.exclude.contains('${s.sourceId}\u0000${s.seriesKey}') && (text.isEmpty || s.title.toLowerCase().contains(text))) s,
            ];
            if (offered.isEmpty) return Padding(padding: EdgeInsets.symmetric(vertical: c.space4), child: CineRoleText('No series available.', c.typeBody, color: c.colorInk60));
            return Column(children: [
              for (final FollowedSeries s in offered)
                CineRow(
                  key: ValueKey('pick-${s.id}'),
                  title: s.title,
                  caption: names[s.sourceId] ?? s.sourceId,
                  leading: SizedBox(width: 48, height: 72, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: followedSeriesCoverUrl(apiBase, s), title: s.title))),
                  onTap: () => Navigator.of(context).pop(LibraryPick(sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title, coverUrl: s.coverUrl)),
                ),
            ],);
          },
        ),
      ],),
    );
  }
}
