import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Tests replace the restart (there is no `AppRestart` above a widget test) and record what it was asked for.
@visibleForTesting
Future<void> Function(SkinId target, String returnRoute)? restartIntoSkinTestHook;

/// Restarts the app into [target] (glass 8.5, stack 2.5): writes the device mirror (`mm.skin.active`) and the return route, then
/// `AppRestart`. A profile whose skin differs melts and restarts with no confirm and
/// no Undo. It is `switch_skin.dart`'s one restart path with the mirror chosen; there is no second copy.
Future<void> restartIntoSkin(BuildContext context, WidgetRef ref, SkinId target, {String returnRoute = '/'}) {
  final hook = restartIntoSkinTestHook;
  if (hook != null) return hook(target, returnRoute);
  return restartInto(context, ref, skin: target, returnRoute: returnRoute);
}
