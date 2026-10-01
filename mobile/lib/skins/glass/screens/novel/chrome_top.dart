import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/reader_system_ui_stand_in.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/nav_row.dart' show statusCapsuleWidth;
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Where every novel chrome element sits (glass 8.14.11): the reader insets, the hit side, the bottom line.
class NovelChromeGeometry {
  NovelChromeGeometry.of(BuildContext context)
      : size = MediaQuery.sizeOf(context),
        inset = NovelReaderInsets.of(context),
        side = math.max(44.0, GlassFrame.hitMin(context)),
        gestureBottom = MediaQuery.systemGestureInsetsOf(context).bottom;

  final Size size;
  final EdgeInsets inset;
  final double side, gestureBottom;

  double get top => inset.top + 8;
  double get left => math.max(inset.left, 16);
  double get right => math.max(inset.right, 16);

  /// The bottom capsule's bottom edge above the screen's (E4).
  double get bottom => math.max(inset.bottom, gestureBottom) + 16;

  bool get landscapePhone => size.shortestSide < 600 && size.width > size.height;

  /// The bands paged mode reserves (G2): the chrome heights plus 16 px each.
  double get topBand => top + side + 16;
  double get bottomBand => bottom + 56 + 16;
}

/// A trailing icon a later step adds to the top-right group (`mobile/37`: listen `headphones`, voices `voice-31`).
class NovelChromeSlot {
  const NovelChromeSlot({required this.icon, required this.label, required this.onPressed, this.inMoreMenu = false});
  final GlassButtonIcon icon;
  final String label;
  final VoidCallback onPressed;

  /// Landscape phones move it into the ⋯ menu (voices, the soundscape row).
  final bool inMoreMenu;
}

/// The page tint inside a shape (C4): the paper's ink at 12 %, clipped to the shape.
class NovelTintedShape extends StatelessWidget {
  const NovelTintedShape({super.key, required this.tint, required this.child, this.circle = false});
  final Color? tint;
  final bool circle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = tint;
    if (t == null || t.a <= 0.001) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: t, shape: circle ? BoxShape.circle : BoxShape.rectangle, borderRadius: circle ? null : BorderRadius.circular(999)))),
        child,
      ],
    );
  }
}

/// The two top groups (E2, E3) in one `SkinGlassGroup` layer, so both sample one backdrop: back (with the depth glyph) and the title
/// capsule on the left (the "Saved copy" capsules join them); bookmark, the [slots] and Aa on the right. Never more than four icons.
class NovelChromeTop extends StatelessWidget {
  const NovelChromeTop({
    super.key,
    required this.g,
    required this.title,
    required this.bookmarked,
    required this.onBookmark,
    required this.onContents,
    required this.onType,
    required this.lb,
    this.tint,
    this.savedCopy = false,
    this.staleAge,
    this.slots = const [],
    this.aaBadge = false,
    this.onMore,
    this.titleKey,
    this.bookmarkDrop,
  });

  final NovelChromeGeometry g;
  final String title;
  final bool bookmarked;
  final VoidCallback onBookmark, onContents, onType;
  final double lb;
  final Color? tint;

  /// Reading a downloaded copy.
  final bool savedCopy;

  /// `cache.stale`: "Saved copy · 2 h".
  final String? staleAge;
  final List<NovelChromeSlot> slots;

  /// `mobile/44`'s 6 px `iris400` dot on Aa.
  final bool aaBadge;

  /// Landscape phones: the ⋯ menu.
  final VoidCallback? onMore;
  final GlobalKey? titleKey;

  /// The bookmark flag's 4 px drop (0..1), sprung back on `tick`.
  final Animation<double>? bookmarkDrop;

  @override
  Widget build(BuildContext context) {
    final side = g.side;
    final avail = g.size.width - g.left - g.right;
    final landscape = g.landscapePhone;
    final visibleSlots = [for (final s in slots) if (!landscape || !s.inMoreMenu) s].take(2).toList();
    final icons = <Widget>[
      _Bookmark(saved: bookmarked, onPressed: onBookmark, drop: bookmarkDrop),
      for (final s in visibleSlots) GlassBarIcon(icon: s.icon, label: s.label, onPressed: s.onPressed),
      Stack(
        clipBehavior: Clip.none,
        children: [
          GlassBarIcon(icon: roleIcon(GlassIconRole.type), label: aaBadge ? 'Type and page, soundscape playing' : 'Type and page', onPressed: onType),
          if (aaBadge) Positioned(right: 10, top: 10, child: IgnorePointer(child: SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris400, shape: BoxShape.circle))))),
        ],
      ),
      if (landscape && onMore != null) GlassBarIcon(icon: GlassButtonIcon.glyph(GlassGlyph.dotsThree), label: 'More', onPressed: onMore),
    ];
    final iconsW = icons.length * side + (icons.length - 1) * 4;
    final savedText = staleAge != null ? 'Saved copy · $staleAge' : (savedCopy ? 'Saved copy' : null);
    var savedW = savedText == null ? 0.0 : statusCapsuleWidth(context, savedText);
    // A narrow phone keeps the title readable: the capsule falls back to its glyph and the age ("2 h"); its name stays in semantics.
    final compactSaved = savedText != null && avail - side - 8 - iconsW - 8 - savedW - 8 < 120;
    if (compactSaved) savedW = statusCapsuleWidth(context, staleAge ?? '') - (staleAge == null ? 6 : 0);
    final style = roleStyle(context, gt.typeSubhead, onGlass: true, wght: 600, maxScale: 1.3);
    final textW = measureText(context, title, style).width + 32;
    final maxTitle = math.max(56.0, math.min(avail * (landscape ? 0.4 : 0.6), avail - side - 8 - iconsW - 8 - (savedText == null ? 0 : savedW + 8)));
    final titleW = textW.clamp(56.0, maxTitle).toDouble();
    final shapes = <SkinGlassShape>[
      SkinGlassShape(size: Size(side, side), shape: const GlassShape.circle(), child: NovelTintedShape(tint: tint, circle: true, child: const GlassBackButton(inGroup: true, showDepth: true))),
      SkinGlassShape(size: Size(titleW, side), child: NovelTintedShape(tint: tint, child: _TitleCapsule(key: titleKey, text: title, onTap: onContents))),
      if (savedText != null)
        SkinGlassShape(size: Size(savedW, 36), child: compactSaved ? _SavedCopy(text: staleAge, label: savedText) : staleAge != null ? GlassStatusCapsule(kind: GlassStatusKind.savedCopy, savedAgo: staleAge!, inGroup: true) : const _SavedCopy()),
      SkinGlassShape(size: Size(iconsW, side), child: NovelTintedShape(tint: tint, child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < icons.length; i++) ...[if (i > 0) const SizedBox(width: 4), icons[i]]]))),
    ];
    final leftCount = savedText == null ? 2 : 3;
    return SizedBox(
      height: side,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final offsets = <double>[];
        var x = 0.0;
        for (var i = 0; i < leftCount; i++) {
          offsets.add(x);
          x += shapes[i].size.width + 8;
        }
        offsets.add(w - shapes.last.size.width);
        return SkinGlassGroup(
          shapes: shapes,
          aligns: [for (var i = 0; i < shapes.length; i++) Alignment(w - shapes[i].size.width <= 0 ? -1 : offsets[i] / (w - shapes[i].size.width) * 2 - 1, 0)],
          height: side,
          lb: lb,
          debugLabel: 'novel top groups',
        );
      },),
    );
  }
}

class _TitleCapsule extends StatelessWidget {
  const _TitleCapsule({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: text,
        hint: 'Opens the contents',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // The series name gives way first; the chapter always shows.
            child: Builder(builder: (context) {
              final cut = text.lastIndexOf(' · ');
              if (cut < 0) return Center(child: GlassText(text, role: gt.typeSubhead, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1, overflow: TextOverflow.ellipsis));
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: GlassText(text.substring(0, cut), role: gt.typeSubhead, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  GlassText(text.substring(cut), role: gt.typeSubhead, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1),
                ],
              );
            },),
          ),
        ),
      );
}

class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.saved, required this.onPressed, this.drop});
  final bool saved;
  final VoidCallback onPressed;
  final Animation<double>? drop;

  @override
  Widget build(BuildContext context) {
    Widget glyph(BuildContext c) {
      final icon = saved
          ? GlassBacking(size: 30, child: Icon(GlassGlyph.bookmarkSimple.fill, size: 20, color: gt.colorIris400))
          : Icon(GlassGlyph.bookmarkSimple.regular, size: 22, color: gt.colorOnGlass);
      final d = drop;
      if (d == null) return icon;
      return AnimatedBuilder(animation: d, builder: (_, child) => Transform.translate(offset: Offset(0, 4 * d.value), child: child), child: icon);
    }

    return GlassBarIcon(icon: roleIcon(GlassIconRole.bookmark), label: 'Bookmark', toggled: saved, onPressed: onPressed, iconBuilder: glyph);
  }
}

/// "Saved copy" (a downloaded copy, E2): the status capsule's look without an age.
class _SavedCopy extends StatelessWidget {
  const _SavedCopy({this.text = 'Saved copy', this.label = 'Saved copy'});
  final String? text;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassBacking(size: 20, child: GlyphIcon(GlassGlyph.wifiSlash, size: 14, color: gt.colorWarning)),
              if (text != null && text!.isNotEmpty) ...[
                const SizedBox(width: 6),
                GlassText(text!, role: gt.typeFootnote, wght: 600, onGlass: true, maxScale: 1.5),
              ],
            ],
          ),
        ),
      );
}
