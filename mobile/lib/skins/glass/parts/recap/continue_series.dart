import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// What a Continue on Home continues (the spotlight primary, a Continue stack, the accessory, the dock menu).
@immutable
class HomeContinueTarget {
  const HomeContinueTarget(
      {required this.sourceId,
      required this.seriesKey,
      required this.chapterKey,
      this.isNovel = false,
      this.recap,
      this.lastReadAt,
      this.chapterNumber,
      this.page,});

  final String sourceId, seriesKey, chapterKey;
  final bool isNovel;
  final RecapAvailability? recap;
  final DateTime? lastReadAt;
  final double? chapterNumber;
  final int? page;

  String get seriesId => '$sourceId:$seriesKey';

  String get readerLocation => isNovel
      ? Routes.novel(sourceId, seriesKey, chapterKey, {if (page != null && page! > 1) 'page': page})
      : Routes.reader(sourceId, seriesKey, chapterKey,
          {if (page != null && page! > 1) 'page': page},);

  factory HomeContinueTarget.fromContinue(HomeContinueItem i) =>
      HomeContinueTarget(
        sourceId: i.row.sourceId,
        seriesKey: i.row.seriesKey,
        chapterKey: i.row.chapterKey,
        recap: i.recap,
        lastReadAt: i.row.lastReadAt,
        chapterNumber: i.row.chapterNumber,
        page: i.row.lastPage,
      );
}

/// The Continue the offer sheet is open for (set by [continueSeries], read by the `offer` sheet).
final offerTargetProvider = StateProvider<HomeContinueTarget?>((ref) => null);

/// What "Just continue" does: the Dive, run with the caller's own context and ref (the sheet's are gone by then).
final offerContinueProvider = StateProvider<VoidCallback?>((ref) => null);

/// Every Glass Continue goes through here (glass 9.1.3): the recap setting decides between the offer sheet (`ask`), the recap deck
/// (`always`) and the Dive into the reader.
Future<void> continueSeries(BuildContext context, WidgetRef ref,
    HomeContinueTarget item, Rect originRect,) async {
  final decision = recapEntryDecision(
    setting: ref.read(recapSettingProvider),
    seriesId: item.seriesId,
    lastReadAt: item.lastReadAt,
    now: ref.read(clockProvider)(),
    available: item.recap?.available ?? false,
  );
  final router = ref.read(skinRouterProvider);
  switch (decision) {
    case RecapEntryDecision.open:
      await openRecapFor(ref, item, originRect: originRect);
    case RecapEntryDecision.offer:
      ref.read(offerTargetProvider.notifier).state = item;
      ref.read(offerContinueProvider.notifier).state = () {
        if (context.mounted) unawaited(enterReader(context, ref, item.readerLocation, fromRect: originRect));
      };
      await router.push<void>(Routes.tonight({'sheet': 'offer'}),
          extra: GlassNavExtra(originRect: originRect),);
    case RecapEntryDecision.none:
      if (!context.mounted) return;
      await enterReader(context, ref, item.readerLocation,
          fromRect: originRect,);
  }
}

/// Opens the recap deck for [item] up to its continue chapter (the explicit entries and "Show recap" share it).
Future<void> openRecapFor(WidgetRef ref, HomeContinueTarget item,
    {Rect? originRect, bool chapter = false,}) {
  final to = item.recap?.toKey ?? item.chapterKey;
  return ref.read(skinRouterProvider).push<void>(
      Routes.recap(item.sourceId, item.seriesKey,
          {'to': to, if (chapter) 'scope': 'chapter'},),
      extra: GlassNavExtra(originRect: originRect),);
}
