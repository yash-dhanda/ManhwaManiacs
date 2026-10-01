import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/chapters_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_states.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

/// The manga series detail (glass 8.12).
class MangaVariant implements SeriesVariant {
  const MangaVariant({this.velocity, this.mature = false});
  final Offset? velocity;
  final bool mature;

  @override
  Widget header(BuildContext context, SeriesPageState page) => Consumer(builder: (context, ref, _) {
        final d = page.data;
        final resume = seriesResume(d.readingOrder, ref.watch(sourceSeriesProgressProvider(d.progressKey)));
        page.warm(resume.chapterKey);
        final desktop = page.layout == SeriesLayout.desktop;
        final v = velocity == null ? null : Velocity(pixelsPerSecond: velocity!);
        final cover = KeyedSubtree(
          key: page.coverKey,
          child: SeriesCover(data: d, width: desktop ? 240 : 112, height: desktop ? 360 : 168, velocity: v, onTap: page.openCover),
        );
        final title = SeriesTitleBlock(data: d, mature: mature, titleFocus: page.titleFocus);
        final actions = SeriesActions(data: d, resume: resume, commands: page.commands, logic: page.logic, onDownloadSeries: page.downloadSeries, followKey: page.followKey, stacked: desktop);
        if (desktop) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [cover, const SizedBox(height: 16), title, const SizedBox(height: 16), actions]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [cover, const SizedBox(width: 16), Expanded(child: title)]),
            const SizedBox(height: 16),
            actions,
          ],
        );
      },);

  @override
  List<Widget> chapterSlivers(BuildContext context, SeriesPageState page) => [
        Consumer(builder: (context, ref, _) {
          final d = page.data;
          final state = chapterListState(d, online: isOnline(ref));
          if (state != null) {
            return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ChapterListNotice(state: state, sourceId: d.sourceId, listed: d.series.chapterCount)));
          }
          return ChapterRowsSliver(data: d, chapters: page.chapters, shown: shownChapters(d, page.chapters.order), onToggleRun: () {});
        },),
      ];

  @override
  void primary(BuildContext context, SeriesPageState page) {
    final ref = page.ref;
    final d = page.data;
    final r = seriesResume(d.readingOrder, ref.read(sourceSeriesProgressProvider(d.progressKey)));
    final key = r.chapterKey;
    if (key == null) return;
    final from = rectOf(page.followKey.currentContext ?? context);
    unawaited(enterReader(context, ref, readerLocation(d, key, page: r.page), fromRect: from));
  }
}
