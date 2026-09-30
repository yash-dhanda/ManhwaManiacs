import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// What a Continue on Home continues (the spotlight primary, a Continue stack, the accessory, the dock menu).
@immutable
class HomeContinueTarget {
  const HomeContinueTarget({required this.sourceId, required this.seriesKey, required this.chapterKey, this.isNovel = false, this.recap, this.lastReadAt, this.chapterNumber, this.page});

  final String sourceId, seriesKey, chapterKey;
  final bool isNovel;
  final RecapAvailability? recap;
  final DateTime? lastReadAt;
  final double? chapterNumber;
  final int? page;

  String get seriesId => '$sourceId:$seriesKey';

  String get readerLocation => isNovel ? Routes.novel(sourceId, seriesKey, chapterKey) : Routes.reader(sourceId, seriesKey, chapterKey, {if (page != null && page! > 1) 'page': page});

  factory HomeContinueTarget.fromContinue(HomeContinueItem i) => HomeContinueTarget(
        sourceId: i.row.sourceId,
        seriesKey: i.row.seriesKey,
        chapterKey: i.row.chapterKey,
        recap: i.recap,
        lastReadAt: i.row.lastReadAt,
        chapterNumber: i.row.chapterNumber,
        page: i.row.lastPage,
      );
}

enum ContinueDecision { dive, recap, offer }

/// The recap setting's decision for one Continue (glass 15.6). `always` opens the recap when [shouldOpenRecapFirst] says so; `ask`
/// opens the offer sheet when it is registered, else dives; `off` and everything else dive.
ContinueDecision decideContinue({required RecapSetting setting, required HomeContinueTarget item, required DateTime now, required bool offerRegistered}) {
  if (setting.mode == RecapMode.off) return ContinueDecision.dive;
  final open = shouldOpenRecapFirst(setting: setting, seriesId: item.seriesId, lastReadAt: item.lastReadAt, now: now, available: item.recap?.available ?? false);
  if (!open) return ContinueDecision.dive;
  if (setting.mode == RecapMode.always) return ContinueDecision.recap;
  return offerRegistered ? ContinueDecision.offer : ContinueDecision.dive;
}

/// Every Continue on Home goes through here. `mobile/41` replaces the body with its `continueSeries`; the signature stays.
Future<void> continueWithRecap(BuildContext context, WidgetRef ref, HomeContinueTarget item, Rect originRect) async {
  final decision = decideContinue(setting: ref.read(recapSettingProvider), item: item, now: ref.read(clockProvider)(), offerRegistered: glassSheetRegistered('offer'));
  final router = ref.read(skinRouterProvider);
  switch (decision) {
    case ContinueDecision.recap:
      final to = item.recap?.toKey ?? item.chapterKey;
      await router.push<void>(Routes.recap(item.sourceId, item.seriesKey, {'to': to}), extra: GlassNavExtra(originRect: originRect));
    case ContinueDecision.offer:
      await router.push<void>('${Routes.tonight({'sheet': 'offer'})}&series=${Uri.encodeQueryComponent(item.seriesId)}', extra: GlassNavExtra(originRect: originRect));
    case ContinueDecision.dive:
      if (!context.mounted) return;
      await enterReader(context, ref, item.readerLocation, fromRect: originRect);
  }
}
