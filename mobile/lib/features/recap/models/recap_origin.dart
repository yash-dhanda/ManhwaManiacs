import 'package:manhwamaniacs/skins/contract.g.dart';

/// How a recap was opened, so it knows how to leave: `wipe` (Tonight, series pages) and `dip`
/// continue by the Column wipe or the Dip; `reader` goes back to the open page.
enum RecapEntry { wipe, dip, reader }

class RecapOrigin {
  const RecapOrigin(this.entry, {required this.returnTo});
  final RecapEntry entry;
  final String returnTo;
}

/// The origin passed in `GoRouterState.extra`, or a Dip back to Tonight for a cold deep link.
RecapOrigin readRecapOrigin(Object? extra) => extra is RecapOrigin ? extra : RecapOrigin(RecapEntry.dip, returnTo: Routes.tonight());
