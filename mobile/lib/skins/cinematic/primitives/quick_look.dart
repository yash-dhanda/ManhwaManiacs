import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens Quick look (cinematic 7.22): a sheet whose top holds a 96 px [cover] beside the credits
/// (the cover is the pressed poster's `Hero` when [heroTag] is given, so it flies into the sheet
/// over the Rise; reduced motion: no flight, the cover fades in), then the [actions] list. Resolves
/// with the chosen action id.
Future<String?> openQuickLook(
  BuildContext context, {
  required String title,
  required Widget cover,
  required List<QuickLookAction> actions,
  String? kicker,
  String? credits,
  Object? heroTag,
}) {
  final reduced = CineMotion.reduced(context);
  return showCineSheet<String>(
    context,
    kicker: kicker ?? 'QUICK LOOK',
    title: title,
    builder: (ctx) {
      final c = ctx.cine;
      Widget art = SizedBox(width: 96, child: AspectRatio(aspectRatio: 2 / 3, child: cover));
      if (heroTag != null && !reduced) art = Hero(tag: heroTag, child: art);
      if (reduced) art = TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: CineDur.reduced, builder: (_, v, ch) => Opacity(opacity: v, child: ch), child: art);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: c.space4), // the sheet body sets the gutter
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            art,
            SizedBox(width: c.space4),
            Expanded(child: credits == null ? const SizedBox() : CineRoleText(credits, c.typeCaption, color: c.colorInk60)),
          ],),
        ),
        for (final a in actions)
          CineRow(
            key: Key('quick-look-${a.id}'),
            title: a.label,
            disabled: a.disabled,
            leading: CineIcon(a.icon, size: 20, color: a.destructive ? c.colorProof : c.colorInk60),
            onTap: a.disabled ? null : () {
              Navigator.of(ctx).pop(a.id);
              a.onSelected?.call();
            },
          ),
      ],);
    },
  );
}

/// Wraps a poster, cutting or row that offers Quick look: a 450 ms long-press dims it to 70 % for
/// 120 ms, fires `longpress.open`, then calls [onOpen].
class CineQuickLookTarget extends StatefulWidget {
  const CineQuickLookTarget({super.key, required this.child, required this.onOpen});
  final Widget child;
  final VoidCallback onOpen;

  @override
  State<CineQuickLookTarget> createState() => _CineQuickLookTargetState();
}

class _CineQuickLookTargetState extends State<CineQuickLookTarget> {
  bool _dim = false;

  Future<void> _open() async {
    cineFeedback(context, HapticEvent.longpressOpen);
    setState(() => _dim = true);
    await Future<void>.delayed(CineDur.snap);
    if (!mounted) return;
    widget.onOpen();
    setState(() => _dim = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        // The wrapped card or row names its own Quick look action for screen readers.
        excludeFromSemantics: true,
        onLongPress: _open,
        child: AnimatedOpacity(duration: CineDur.snap, opacity: _dim ? 0.7 : 1, child: widget.child),
      );
}
