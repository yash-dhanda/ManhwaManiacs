import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

enum CineToastKind { info, success, error, action, undo }

/// One "subtitle" (cinematic 7.11).
@immutable
class CineToast {
  const CineToast({
    required this.id,
    required this.kind,
    required this.text,
    required this.hold,
    this.actionLabel,
    this.onAction,
  });

  final int id;
  final CineToastKind kind;
  final String text;

  /// How long it stays: 3600 ms, 6000 ms errors, 8000 ms with an action, 10000 ms skin undo.
  final Duration hold;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasAction => actionLabel != null && onAction != null;
}

/// The toast queue. The host (`CineToastHost`) shows the newest two; older ones are dropped.
class CineToastsNotifier extends Notifier<List<CineToast>> {
  int _next = 1;

  @override
  List<CineToast> build() => const [];

  int _push(CineToastKind kind, String text, Duration hold, {String? label, VoidCallback? onAction}) {
    final id = _next++;
    state = [...state, CineToast(id: id, kind: kind, text: text, hold: hold, actionLabel: label, onAction: onAction)];
    return id;
  }

  int info(String text) => _push(CineToastKind.info, text, CineDur.holdToast);
  int success(String text) => _push(CineToastKind.success, text, CineDur.holdToast);
  int error(String text) => _push(CineToastKind.error, text, CineDur.holdToastError);

  int action(String text, {required String label, required VoidCallback onAction}) =>
      _push(CineToastKind.action, text, CineDur.holdToastAction, label: label, onAction: onAction);

  /// The skin-switch undo passes [CineDur.holdToastUndo].
  int undo(String text, {required VoidCallback onUndo, Duration hold = CineDur.holdToastAction}) =>
      _push(CineToastKind.undo, text, hold, label: 'Undo', onAction: onUndo);

  void dismiss(int id) => state = [for (final t in state) if (t.id != id) t];
}

final cineToastsProvider = NotifierProvider<CineToastsNotifier, List<CineToast>>(CineToastsNotifier.new, name: 'cineToasts');
