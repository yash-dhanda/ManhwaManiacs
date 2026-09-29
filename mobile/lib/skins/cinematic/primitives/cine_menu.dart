import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_keycap.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One item of a [showCineMenu] menu (cinematic 7.22). [value] is what the future resolves with;
/// [onSelected] runs as well, so a row menu can carry its own handlers.
class CineMenuEntry<T> {
  const CineMenuEntry({
    required this.label,
    this.value,
    this.onSelected,
    this.icon,
    this.glyph,
    this.shortcut,
    this.destructive = false,
    this.checked = false,
    this.disabled = false,
    this.disabledReason,
    this.submenu,
    this.separatorBefore = false,
  });

  final String label;
  final T? value;
  final VoidCallback? onSelected;
  final CineIconRole? icon;
  final int? glyph;
  final List<LogicalKeyboardKey>? shortcut;
  final bool destructive, checked, disabled, separatorBefore;
  final String? disabledReason;
  final List<CineMenuEntry<T>>? submenu;
}

/// Opens a menu anchored at [anchor] (global rect): below it, above when there is no room, never
/// off screen. Arrows, Home/End, type-ahead, Enter, Esc, and `→` / `←` for submenus. Resolves with
/// the chosen entry's value; focus returns to the trigger.
Future<T?> showCineMenu<T>(BuildContext context, {required Rect anchor, required List<CineMenuEntry<T>> entries}) {
  final trigger = FocusManager.instance.primaryFocus;
  cineFeedback(context, HapticEvent.longpressOpen);
  return Navigator.of(context, rootNavigator: true).push(_CineMenuRoute<T>(
    anchor: anchor,
    entries: entries,
    reduced: CineMotion.reduced(context),
    restoreFocus: trigger,
  ),);
}

/// The global rect of [context]'s box, for the anchor.
Rect cineAnchorRect(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _CineMenuRoute<T> extends PopupRoute<T> {
  _CineMenuRoute({required this.anchor, required this.entries, required this.reduced, this.restoreFocus});

  final Rect anchor;
  final List<CineMenuEntry<T>> entries;
  final bool reduced;
  final FocusNode? restoreFocus;
  bool _above = false;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close menu';
  @override
  Duration get transitionDuration => reduced ? CineDur.reduced : CineDur.clip;
  @override
  Duration get reverseTransitionDuration => reduced ? CineDur.reduced : CineDur.snap;

  @override
  void dispose() {
    final node = restoreFocus;
    if (node != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (node.context != null && node.canRequestFocus) node.requestFocus();
      });
    }
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: CustomSingleChildLayout(
        delegate: _MenuLayout(anchor, MediaQuery.paddingOf(context), (above) => _above = above),
        child: _CineMenuPanel<T>(entries: entries, onPick: (e) {
          Navigator.of(context).pop(e.value);
          e.onSelected?.call();
        }, onClose: () => Navigator.of(context).maybePop(),),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (reduced) return FadeTransition(opacity: animation, child: child);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        if (leaving) return Opacity(opacity: animation.value.clamp(0.0, 1.0), child: child);
        final t = CineCurves.settle.transform(animation.value.clamp(0.0, 1.0));
        return ClipRect(clipper: _Reveal(t, _above), child: child);
      },
    );
  }
}

class _Reveal extends CustomClipper<Rect> {
  const _Reveal(this.t, this.above);
  final double t;
  final bool above;
  @override
  Rect getClip(Size s) => above ? Rect.fromLTRB(0, s.height * (1 - t), s.width, s.height) : Rect.fromLTRB(0, 0, s.width, s.height * t);
  @override
  bool shouldReclip(_Reveal o) => o.t != t || o.above != above;
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.padding, this.onAbove);
  final Rect anchor;
  final EdgeInsets padding;
  final void Function(bool above) onAbove;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints(minWidth: 224, maxWidth: (c.maxWidth - 16).clamp(224, 420), maxHeight: c.maxHeight * 0.6);

  @override
  Offset getPositionForChild(Size size, Size child) {
    final below = anchor.bottom + child.height <= size.height - padding.bottom - 8;
    final above = !below && anchor.top - child.height >= padding.top + 8;
    onAbove(above);
    var y = above ? anchor.top - child.height : anchor.bottom;
    y = y.clamp(padding.top + 8, (size.height - padding.bottom - child.height - 8).clamp(padding.top + 8, size.height));
    final x = anchor.left.clamp(8.0, (size.width - child.width - 8).clamp(8.0, size.width));
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout o) => o.anchor != anchor || o.padding != padding;
}

class _CineMenuPanel<T> extends StatefulWidget {
  const _CineMenuPanel({required this.entries, required this.onPick, required this.onClose});
  final List<CineMenuEntry<T>> entries;
  final void Function(CineMenuEntry<T>) onPick;
  final VoidCallback onClose;

  @override
  State<_CineMenuPanel<T>> createState() => _CineMenuPanelState<T>();
}

class _CineMenuPanelState<T> extends State<_CineMenuPanel<T>> {
  final _focus = FocusNode(debugLabel: 'cine-menu');
  int _at = -1;
  int? _open;
  String _typed = '';
  DateTime _typedAt = DateTime.fromMillisecondsSinceEpoch(0);

  List<CineMenuEntry<T>> get _list => widget.entries;

  @override
  void initState() {
    super.initState();
    _at = _list.indexWhere((e) => !e.disabled);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _move(int dir) {
    if (_list.isEmpty) return;
    var i = _at;
    for (var n = 0; n < _list.length; n++) {
      i = (i + dir) % _list.length;
      if (i < 0) i += _list.length;
      if (!_list[i].disabled) break;
    }
    setState(() => _at = i);
  }

  void _activate(int i) {
    final e = _list[i];
    if (e.disabled) return;
    if (e.submenu != null) {
      setState(() => _open = i);
    } else {
      widget.onPick(e);
    }
  }

  KeyEventResult _key(FocusNode n, KeyEvent ev) {
    if (ev is KeyUpEvent) return KeyEventResult.ignored;
    final k = ev.logicalKey;
    if (_open != null) {
      if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.escape) {
        setState(() => _open = null);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (k == LogicalKeyboardKey.home) {
      setState(() => _at = _list.indexWhere((e) => !e.disabled));
    } else if (k == LogicalKeyboardKey.end) {
      setState(() => _at = _list.lastIndexWhere((e) => !e.disabled));
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.arrowRight) {
      if (_at >= 0 && (k != LogicalKeyboardKey.arrowRight || _list[_at].submenu != null)) _activate(_at);
    } else if (k == LogicalKeyboardKey.escape) {
      widget.onClose();
    } else if (ev.character != null && ev.character!.trim().isNotEmpty && !HardwareKeyboard.instance.isControlPressed) {
      final now = DateTime.now();
      _typed = now.difference(_typedAt) > const Duration(seconds: 1) ? ev.character! : _typed + ev.character!;
      _typedAt = now;
      final hit = _list.indexWhere((e) => !e.disabled && e.label.toLowerCase().startsWith(_typed.toLowerCase()));
      if (hit >= 0) setState(() => _at = hit);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return CineStock.raised(
      Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _key,
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: Container(
            decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorRule2)),
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < _list.length; i++) ...[
                    if (_list[i].separatorBefore && i > 0) Container(height: 1, color: c.ruleHair.color),
                    _item(context, i),
                    if (_open == i) _sub(context, _list[i]),
                  ],
                ],),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sub(BuildContext context, CineMenuEntry<T> parent) {
    final c = context.cine;
    return Container(
      margin: EdgeInsets.only(left: c.space4),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: c.colorRule2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final s in parent.submenu!) _plain(context, s, false, () => widget.onPick(s)),
      ],),
    );
  }

  Widget _item(BuildContext context, int i) {
    final e = _list[i];
    return _plain(context, e, i == _at && _open == null, () => _activate(i), onHover: () => setState(() => _at = i), trailingCaret: e.submenu != null);
  }

  Widget _plain(BuildContext context, CineMenuEntry<T> e, bool active, VoidCallback onTap, {VoidCallback? onHover, bool trailingCaret = false}) {
    final c = context.cine;
    final fg = e.disabled ? c.colorInk30 : (e.destructive ? c.colorProof : c.colorInk100);
    final minH = Theme.of(context).platform == TargetPlatform.android ? c.hitAndroid : 48.0;
    return Semantics(
      button: true,
      enabled: !e.disabled,
      checked: e.checked ? true : null,
      label: e.label,
      hint: e.disabledReason,
      excludeSemantics: true,
      onTap: e.disabled ? null : onTap,
      child: MouseRegion(
        cursor: e.disabled ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: (_) => onHover?.call(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: e.disabled ? null : onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: minH),
            color: active ? c.colorPaper4 : null,
            child: Row(children: [
              Container(width: 2, height: minH, color: active ? c.colorInk100 : const Color(0x00000000)),
              SizedBox(width: c.space3),
              SizedBox(
                width: 20,
                child: e.checked
                    ? CineGlyphIcon(CineGlyph.check, color: fg)
                    : (e.glyph != null ? CineGlyphIcon(e.glyph!, color: fg) : (e.icon != null ? CineIcon(e.icon!, size: 20, color: fg) : null)),
              ),
              SizedBox(width: c.space3),
              Expanded(child: Padding(padding: EdgeInsets.symmetric(vertical: c.space2), child: CineRoleText(e.label, c.typeUi, color: fg))),
              if (e.shortcut != null) ...[SizedBox(width: c.space3), CineKeycap(keys: e.shortcut!)],
              if (trailingCaret) Padding(padding: EdgeInsets.only(left: c.space2), child: CineGlyphIcon(CineGlyph.caretRight, size: 16, color: fg)),
              SizedBox(width: c.space4),
            ],),
          ),
        ),
      ),
    );
  }
}
