import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

OverlayEntry? _current;
Timer? _timer;

/// A bottom toast on the root overlay: `paper.3`, a 1 px edge (`proof` for an
/// error), optional action. Replaces the toast on screen.
///
/// TODO(mobile/06): the shell's toast host owns this; call it instead.
void showCineToast(
  BuildContext context,
  String message, {
  Duration duration = CineDur.holdToast,
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  dismissCineToast();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Material(
              color: CineColors.paper3,
              shape: Border(left: BorderSide(color: error ? CineColors.proof : CineColors.spot, width: 2)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(children: [
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: CineText(message, context.cine.typeUi))),
                  if (actionLabel != null)
                    CineButton(actionLabel, small: true, kind: CineButtonKind.quiet, onPressed: () {
                      dismissCineToast();
                      onAction?.call();
                    },),
                ],),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _current = entry;
  overlay.insert(entry);
  _timer = Timer(duration, dismissCineToast);
}

void dismissCineToast() {
  _timer?.cancel();
  _timer = null;
  _current?.remove();
  _current = null;
}
