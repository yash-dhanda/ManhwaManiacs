import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// How long a `Continue` waits for the availability answer of an item that carries no `recap`.
const Duration kRecapAskTimeout = Duration(milliseconds: 400);

/// The one helper behind every `Continue` in the Cinematic skin (cinematic 9.1.5). Opens the
/// recap first when `mm.recap` asks for it (`RecapOrigin(origin, returnTo: here)`, by Dip), else the
/// reader with the origin's transition: the Column wipe for `wipe`, the Dip for `dip`.
///
/// An item with a [recap] answer decides at once; one without it asks the endpoint only when the
/// setting could open a recap, and gives up after [kRecapAskTimeout].
Future<void> continueTo(
  BuildContext context,
  WidgetRef ref, {
  required String sourceId,
  required String seriesKey,
  required String chapterKey,
  String? title,
  DateTime? lastReadAt,
  RecapAvailability? recap,
  required RecapEntry origin,
  int? page,
}) async {
  final setting = ref.read(recapSettingProvider);
  final now = ref.read(clockProvider)();
  final seriesId = '$sourceId:$seriesKey';
  var recapFirst = false;
  if (recap != null) {
    recapFirst = shouldOpenRecapFirst(setting: setting, seriesId: seriesId, lastReadAt: lastReadAt, now: now, available: recap.available);
  } else if (mayAutoOpen(setting: setting, seriesId: seriesId, lastReadAt: lastReadAt, now: now)) {
    try {
      final a = await ref.read(recapAvailabilityProvider(RecapKey(sourceId, seriesKey, chapterKey)).future).timeout(kRecapAskTimeout);
      recapFirst = a.available;
    } on TimeoutException {
      recapFirst = false;
    } catch (_) {
      recapFirst = false;
    }
  }
  if (!context.mounted) return;
  if (recapFirst) {
    openRecap(context, sourceId, seriesKey, chapterKey, origin: origin);
    return;
  }
  openReaderAt(context, ref, sourceId, seriesKey, chapterKey, entry: origin == RecapEntry.wipe ? ReaderEntry.wipe : ReaderEntry.dip, page: page);
}

/// `Routes.feature` with the More like this tab selected.
String featureMoreLikeThis(String sourceId, String seriesKey) =>
    Uri.parse(Routes.feature(sourceId, seriesKey)).replace(queryParameters: {'tab': 'more-like-this'}).toString();

/// Pops the recap and returns to the page it was opened from.
void closeRecap(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) router.pop();
}

/// Whether a recap is available for [k], asked now and given up on after [limit]: Quick look adds its
/// `Previously on` row only on a yes in time.
Future<bool> recapAvailableWithin(WidgetRef ref, RecapKey k, {Duration limit = const Duration(milliseconds: 300)}) async {
  try {
    return (await ref.read(recapAvailabilityProvider(k).future).timeout(limit)).available;
  } catch (_) {
    return false;
  }
}
