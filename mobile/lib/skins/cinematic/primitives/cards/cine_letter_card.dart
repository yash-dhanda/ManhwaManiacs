import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A Letter (a recommendation from a person): a duotone cover strip at left; kicker `FROM RIYA`,
/// the title, the note in italic quotes and action slots at right (cinematic 7.6). A new letter
/// [unfold]s once (cinematic 9.3.4): its box reveals from the top edge down over 480 ms `settle`
/// (layout holds) while the sender kicker types at 50 ms per grapheme; under reduced motion it is a
/// 150 ms fade. The `spot` dot before the kicker fades over 160 ms when [isNew] turns false.
class CineLetterCard extends StatefulWidget {
  const CineLetterCard({
    super.key,
    required this.from,
    required this.title,
    this.note,
    this.imageUrl,
    this.duo,
    this.isNew = false,
    this.unfold = false,
    this.kicker,
    this.actionsEnabled = true,
    this.disabledHint,
    this.onOpen,
    this.onRead,
    this.onAdd,
    this.onKeep,
    this.onDismiss,
    this.onUnfolded,
    this.focusNode,
  });

  final String from, title;
  final String? note;
  final String? imageUrl;
  final Color? duo;
  final bool isNew;

  /// Play the unfold on first build (a `new` letter the first time it renders in the session).
  final bool unfold;

  /// Overrides `FROM RIYA` (`FROM RIYA (@riya)` when two members share a name).
  final String? kicker;
  final bool actionsEnabled;

  /// Shown under the actions while they are disabled ("Needs a connection.").
  final String? disabledHint;
  final VoidCallback? onOpen, onRead, onAdd, onKeep, onDismiss, onUnfolded;
  final FocusNode? focusNode;

  @override
  State<CineLetterCard> createState() => _CineLetterCardState();
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, size.height * t);

  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}

class _CineLetterCardState extends State<CineLetterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _unfold = AnimationController(vsync: this, duration: CineDur.spread);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.unfold) {
      _unfold.value = 1;
      return;
    }
    final reduced = CineMotion.reduced(context);
    _unfold.duration = reduced ? CineDur.reduced : CineDur.spread;
    unawaited(_unfold.forward().whenComplete(() => widget.onUnfolded?.call()));
  }

  @override
  void dispose() {
    _unfold.dispose();
    super.dispose();
  }

  String get from => widget.from;
  String get title => widget.title;
  String? get note => widget.note;
  String? get imageUrl => widget.imageUrl;
  Color? get duo => widget.duo;
  bool get isNew => widget.isNew;
  VoidCallback? get onOpen => widget.onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final onRead = widget.onRead, onAdd = widget.onAdd, onKeep = widget.onKeep, onDismiss = widget.onDismiss;
    final kicker = widget.kicker ?? 'FROM ${from.toUpperCase()}';
    final actions = <(String, VoidCallback?)>[('Read', onRead), ('Add', onAdd), ('Keep', onKeep), ('Dismiss', onDismiss)].where((a) => a.$2 != null).toList();
    final card = CinePressable(
      hit: false,
      focusNode: widget.focusNode,
      onTap: onOpen,
      builder: (context, st) {
        final lit = st.hovered || st.focused;
        return AnimatedContainer(
          duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
          transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
          child: CineStock.raised(Builder(
            builder: (context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 132,
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: ClipRect(
                    child: AnimatedScale(
                      scale: lit && !reduced ? 1.04 : 1,
                      duration: reduced ? Duration.zero : c.durClip,
                      curve: c.easeSettle,
                      child: CineDuotone(duo: duo ?? c.colorAmbientFallbackDuo, child: CineImage(url: imageUrl, title: title)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: c.space3),
              Expanded(
                child: Semantics(
                  container: true,
                  label: 'From $from, $title.${note == null ? '' : ' $note'}',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      AnimatedOpacity(
                        opacity: isNew ? 1 : 0,
                        duration: reduced ? Duration.zero : CineDur.beat,
                        child: Container(key: const Key('letter-dot'), width: 6, height: 6, margin: EdgeInsets.only(right: c.space2), color: c.colorSpot),
                      ),
                      Flexible(
                        child: widget.unfold
                            ? TypedText.plain(kicker, style: CineText.style(context, c.typeKicker).copyWith(color: c.colorInk45), maxLines: 1, overflow: TextOverflow.ellipsis)
                            : CineRoleText(kicker, c.typeKicker, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],),
                    SizedBox(height: c.space1),
                    CineRoleText(title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis, decoration: lit ? TextDecoration.underline : null),
                    SizedBox(height: c.space1),
                    if (note != null && note!.isNotEmpty) CineRoleText('“$note”', c.typeBodyItalic, color: context.cine.colorInk60, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (actions.isNotEmpty)
                      Wrap(spacing: c.space1, children: [
                        for (final a in actions)
                          CineButton(
                            label: a.$1,
                            variant: a.$1 == 'Read' ? CineButtonVariant.secondary : CineButtonVariant.quiet,
                            size: CineButtonSize.sm,
                            onPressed: widget.actionsEnabled ? a.$2 : null,
                          ),
                      ],),
                    if (!widget.actionsEnabled && widget.disabledHint != null) CineRoleText(widget.disabledHint!, c.typeCaption, color: c.colorInk45),
                  ],),
                ),
              ),
            ],),
          ),),
        );
      },
    );
    return AnimatedBuilder(
      animation: _unfold,
      builder: (context, child) {
        final t = CineCurves.settle.transform(_unfold.value);
        if (reduced) return Opacity(opacity: _unfold.value, child: child);
        return ClipRect(clipper: _RevealClipper(t), child: child);
      },
      child: card,
    );
  }
}
