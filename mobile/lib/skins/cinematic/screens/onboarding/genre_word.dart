import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/utils/genre_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The face of the paragraph: Bodoni Moda Italic (opsz 28, wght 500), 22 px on phones, 26 on
/// tablets, line 44 (iOS) / 48 (Android).
TextStyle genreStyle(BuildContext context, {required double size}) =>
    CineText.literal(context, CineFace.bodoni, size, cineHitMin(context), italic: true, wght: 500);

/// One word of the genre paragraph: tap, 450 ms hold, menu, semantics actions, roving arrows.
class GenreWord extends StatelessWidget {
  const GenreWord({super.key, required this.name, required this.mark, required this.size, required this.scope, required this.onChange});
  final String name;
  final GenreMark? mark;
  final double size;
  final FocusScopeNode scope;

  /// Called with the new mark (null clears) after every change.
  final void Function(GenreMark? mark, {required bool announce}) onChange;

  void _set(BuildContext context, GenreMark? m) {
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    onChange(m, announce: true);
  }

  Future<void> _menu(BuildContext context) async {
    final picked = await showCineMenu<GenreMenuAction>(context, anchor: cineAnchorRect(context), entries: [
      CineMenuEntry(label: 'Like', value: GenreMenuAction.like, checked: mark == GenreMark.like),
      CineMenuEntry(label: 'Love', value: GenreMenuAction.love, checked: mark == GenreMark.love),
      CineMenuEntry(label: 'Skip', value: GenreMenuAction.skip, checked: mark == GenreMark.skip),
      CineMenuEntry(label: 'Clear', value: GenreMenuAction.clear, checked: mark == null),
    ],);
    if (picked != null && context.mounted) _set(context, menuGenre(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final love = mark == GenreMark.love, like = mark == GenreMark.like, skip = mark == GenreMark.skip;
    final base = genreStyle(context, size: size);
    final ink = skip ? c.colorInk45 : (like || love ? c.colorInk100 : c.colorInk60);
    final scaler = CineText.literalScaler(context, CineFace.bodoni);
    Text word(TextStyle s) => Text(name, style: s, textScaler: scaler, softWrap: false);
    // Liked or loved, the word fills with `spot` from the left (no underline: owner, 3.5.2).
    final marked = base.copyWith(color: c.colorSpot);
    final strike = base.copyWith(color: ink, decoration: TextDecoration.lineThrough, decorationColor: c.colorProof, decorationThickness: 1);

    Widget drawn(bool on, Duration d, Curve curve, Widget Function(double t) build) => TweenAnimationBuilder<double>(
          tween: Tween(end: on ? 1 : 0),
          duration: reduced ? Duration.zero : d,
          curve: curve,
          builder: (_, t, __) => build(t),
        );

    final label = genreLabel(name, mark);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => _set(context, tapGenre(mark)),
      onLongPress: () => _set(context, holdGenre()),
      customSemanticsActions: {
        for (final a in GenreMenuAction.values) CustomSemanticsAction(label: '${a.name[0].toUpperCase()}${a.name.substring(1)}'): () => _set(context, menuGenre(a)),
      },
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent) {
            final shiftF10 = e.logicalKey == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed;
            if (shiftF10 || e.logicalKey == LogicalKeyboardKey.contextMenu) {
              _menu(context);
              return KeyEventResult.handled;
            }
          }
          return rovingKey(FocusManager.instance.primaryFocus ?? node, e, scope: scope);
        },
        child: CinePressable(
          onTap: () => _set(context, tapGenre(mark)),
          onLongPress: () => _set(context, holdGenre()),
          builder: (context, st) => Stack(alignment: Alignment.center, children: [
            // The love band sweeps left to right behind the word (Highlight sweep, 200 ms).
            Positioned.fill(
              child: drawn(love, c.durClip, CineCurves.easeSet, (t) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: t, child: DecoratedBox(decoration: BoxDecoration(color: c.colorSpotWash), child: const SizedBox.expand())),
              ),),
            ),
            CineStock.wash(Builder(builder: (context) => word(skip ? strike : base.copyWith(color: ink)))),
            Positioned.fill(
              child: drawn(like || love, c.durLine, CineCurves.settle, (t) => Align(
                alignment: Alignment.centerLeft,
                child: ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: t, child: word(marked))),
              ),),
            ),
          ],),
        ),
      ),
    );
  }
}
