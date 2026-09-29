import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_measure.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The dialog surface (cinematic 7.10): `paper.3` raised, 1 px `ink.30` border, radius 0, 88 % of
/// the width and at most 560, centred; title `typeSubhead`, body `typeBody` `ink.60` at 48ch;
/// [actions] stacked full width, the committing action first and `Cancel` (quiet) last.
/// `Esc` cancels through [onCancel].
class CineDialog extends StatelessWidget {
  const CineDialog({
    super.key,
    required this.title,
    this.body,
    this.content,
    this.errorText,
    required this.actions,
    this.onCancel,
  });

  final String title;
  final String? body;

  /// Extra content between the body and the actions (a typed-phrase field, a checkbox).
  final Widget? content;

  /// An error line above the actions, in `proof`.
  final String? errorText;
  final List<Widget> actions;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.88, 560.0);
    return CallbackShortcuts(
      bindings: {if (onCancel != null) const SingleActivator(LogicalKeyboardKey.escape): onCancel!},
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: width,
            child: CineStock.raised(
              Container(
                decoration: BoxDecoration(color: c.colorPaper3, border: Border.all(color: c.colorInk30)),
                padding: EdgeInsets.all(c.space6),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    CineRoleText(title, c.typeSubhead),
                    if (body != null) ...[
                      SizedBox(height: c.space3),
                      CineMeasure(ch: 48, style: CineText.style(context, c.typeBody), child: CineRoleText(body!, c.typeBody, color: c.colorInk60)),
                    ],
                    if (content != null) ...[SizedBox(height: c.space4), content!],
                    if (errorText != null) ...[
                      SizedBox(height: c.space4),
                      Semantics(liveRegion: true, child: CineRoleText(errorText!, c.typeCaption, color: c.colorProof)),
                    ],
                    SizedBox(height: c.space6),
                    for (var i = 0; i < actions.length; i++) ...[if (i > 0) SizedBox(height: c.space2), actions[i]],
                  ],),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
