import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';

/// A single unfollow or remove never opens a dialog (cinematic 7.10): it commits at once and shows
/// the toast [message] ("Removed {title}.") with `Undo`, held 8000 ms. Pressing Undo runs [undo]
/// and fires `HapticEvent.undo`. A failure of [run] shows an error toast instead.
Future<void> commitWithUndo(
  BuildContext context, {
  required Future<void> Function() run,
  required Future<void> Function() undo,
  required String message,
}) async {
  final toasts = ProviderScope.containerOf(context, listen: false).read(cineToastsProvider.notifier);
  try {
    await run();
  } catch (e) {
    toasts.error(e is AppError ? e.userMessage : 'That didn’t go through. Try again.');
    return;
  }
  toasts.undo(
    message,
    onUndo: () {
      undo().catchError((Object e) {
        toasts.error(e is AppError ? e.userMessage : 'Couldn’t undo that.');
      });
    },
  );
}
