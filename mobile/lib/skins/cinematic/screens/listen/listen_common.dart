import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The mini player's height (cinematic 8.16.2).
const double kMiniPlayerHeight = 56;

/// Opens a Listen sheet. Inside the reader the sheet paints in the page [stock] (the stock scope
/// re-provides the surface and ink tokens); from Settings [stock] is null and it paints in the
/// app's own tokens.
Future<T?> showListenSheet<T>(
  BuildContext context, {
  required String kicker,
  required String title,
  required WidgetBuilder builder,
  CineStockColors? stock,
  bool livePreview = false,
}) =>
    showCineSheet<T>(
      context,
      kicker: kicker,
      title: title,
      livePreview: livePreview,
      builder: (sheetContext) {
        final body = Material(type: MaterialType.transparency, child: Builder(builder: builder));
        return stock == null ? body : CineStock.stock(stock, body);
      },
    );

/// A dot-separated label the way Listen sets it: `CHAPTER 12 · READ BY IRIS`.
String dotted(Iterable<String?> parts) => parts.whereType<String>().where((s) => s.isNotEmpty).join(' · ');

/// A small text action with an optional 16 px leader dial, whose touch target grows to 44 / 48.
/// The Hear and Cast buttons, the post-play `Play now`, and the like.
class ListenAction extends StatelessWidget {
  const ListenAction({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.busy = false,
    this.color,
    this.semanticLabel,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onTap;

  /// The selected state: filled ink with the label in the ground colour (`CAST`).
  final bool filled;

  /// A 16 px leader dial before the label (fetching).
  final bool busy;
  final Color? color;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ink = color ?? c.colorInk100;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      enabled: onTap != null,
      onTap: onTap,
      child: CinePressable(
        onTap: onTap,
        focusNode: focusNode,
        builder: (context, st) => Container(
          constraints: const BoxConstraints(minHeight: 32, minWidth: 56),
          padding: EdgeInsets.symmetric(horizontal: c.space3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? ink : Colors.transparent,
            border: Border.all(color: filled ? ink : (st.focused || st.hovered ? ink : c.colorRule2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[const CineLeaderDial(size: 16, showAfter: Duration.zero), SizedBox(width: c.space2)],
              CineRoleText(label, c.typeUi, color: filled ? c.colorPaper0 : ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// The owner is an admin account: only they see the pickers, the Audiobook sheet and the render
/// actions.
final isOwnerProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is AuthAuthenticated && auth.user.isAdmin;
}, name: 'isOwner',);

/// The on-screen rect of [context], where a menu opened from it anchors.
Rect anchorRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return const Rect.fromLTWH(0, 0, 1, 1);
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The reader's Listen state that the screen, its keys and its back handling share: whether the
/// reading room is open, and how to ask it to collapse (the layer wires [collapse]).
class ListenUi extends ChangeNotifier {
  bool _roomOpen = false;

  /// The post-play card is waiting: the reader's 900 ms auto-next stays off.
  bool cardShowing = false;

  bool get roomOpen => _roomOpen;

  /// Set by the layer: runs the reverse match cut, then calls [setRoomOpen]`(false)`.
  VoidCallback? collapse;

  void setRoomOpen(bool open) {
    if (open == _roomOpen) return;
    _roomOpen = open;
    notifyListeners();
  }

  /// Esc or Android back while the room is open: true when it handled the press.
  bool handleBack() {
    if (!_roomOpen) return false;
    (collapse ?? () => setRoomOpen(false)).call();
    return true;
  }
}
