import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Leaves the reader by Dip (cinematic 8.14.2): pops when it can; when the reader is the first
/// route (a deep link), goes to the series page, which enters by Dip.
void leaveReaderByDip(BuildContext context, {required String sourceId, required String seriesKey}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go(Routes.feature(sourceId, seriesKey), extra: <String, String>{'transition': 'dip'});
}
