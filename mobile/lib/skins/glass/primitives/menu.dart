import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrim.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One row of a menu (glass 7.23). A [run] keeps the menu open with a trailing spinner until it finishes; a throw shows
/// [errorText] in place of the label for 2 s. [checked] non-null makes it a toggle (`Semantics(checked:)`); true adds the
/// trailing `iris400` check on the backing disc.
class GlassMenuEntry {
  const GlassMenuEntry({
    required this.label,
    this.icon,
    this.onSelected,
    this.run,
    this.destructive = false,
    this.checked,
    this.enabled = true,
    this.keyHint,
    this.separatorBefore = false,
    this.errorText,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onSelected;
  final Future<void> Function()? run;
  final bool destructive;
  final bool? checked;
  final bool enabled;
  final SingleActivator? keyHint;

  /// A 6 px gap before this row (groups are separated by gaps).
  final bool separatorBefore;
  final String? errorText;
}

/// The size and content of a menu body: T4 padding 6, min width 220, max 320, rows `hitMin` tall.
abstract final class GlassMenuMetrics {
  static Size sizeFor(BuildContext context, List<GlassMenuEntry> entries) {
    final hit = GlassFrame.hitMin(context);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    var w = 0.0;
    for (final e in entries) {
      final label = measureText(context, e.label, roleStyle(context, gt.typeBody, onGlass: true, maxScale: 1.5)).width;
      final key = wide && e.keyHint != null ? 12.0 + 26 * keycapLabel(e.keyHint!).length : 0.0;
      w = math.max(w, 16 + label + 12 + (e.icon != null ? 20 + 12 : 0) + (e.checked == true ? 28 : 0) + key + 16);
    }
    final gaps = entries.where((e) => e.separatorBefore).length * 6.0;
    return Size(w.clamp(220.0, 320.0), entries.length * hit + gaps + 12);
  }
}

/// The rows of a menu with keys, type-ahead, slide-to-select highlighting and every row state (glass 7.23).
class GlassMenuPanel extends ConsumerStatefulWidget {
  const GlassMenuPanel({
    super.key,
    required this.entries,
    required this.title,
    required this.onDone,
    this.slide,
    this.slideEnd,
    this.forceRow,
  });

  final List<GlassMenuEntry> entries;
  final String title;

  /// Closes the menu; called with the entry to run afterwards (null when a row's [GlassMenuEntry.run] already ran).
  final void Function(GlassMenuEntry? selected) onDone;

  /// Slide to select: the pointer's global position while a long press is held, and the release.
  final ValueNotifier<Offset?>? slide;
  final ValueNotifier<bool>? slideEnd;

  /// For captures: draw this row highlighted.
  final int? forceRow;

  @override
  ConsumerState<GlassMenuPanel> createState() => _GlassMenuPanelState();
}

enum _RowState { idle, loading, error }

class _GlassMenuPanelState extends ConsumerState<GlassMenuPanel> {
  late final List<FocusNode> _nodes = List.generate(widget.entries.length, (i) => FocusNode(debugLabel: 'menuRow$i'));
  late final List<GlobalKey> _keys = List.generate(widget.entries.length, (_) => GlobalKey());
  late final List<_RowState> _state = List.filled(widget.entries.length, _RowState.idle);
  int? _highlight;
  String _typed = '';
  Timer? _typedTimer;
  final List<Timer> _errTimers = [];

  @override
  void initState() {
    super.initState();
    widget.slide?.addListener(_onSlide);
    widget.slideEnd?.addListener(_onSlideEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Focus enters the menu on open (the ring only shows under a keyboard), so Esc and the arrows work at once.
      final i = widget.entries.indexWhere((e) => e.enabled);
      if (i >= 0) _nodes[i].requestFocus();
    });
  }

  @override
  void dispose() {
    widget.slide?.removeListener(_onSlide);
    widget.slideEnd?.removeListener(_onSlideEnd);
    _typedTimer?.cancel();
    for (final t in _errTimers) {
      t.cancel();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  int? _rowAt(Offset global) {
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize && widget.entries[i].enabled) {
        if ((box.localToGlobal(Offset.zero) & box.size).contains(global)) return i;
      }
    }
    return null;
  }

  void _onSlide() {
    final p = widget.slide?.value;
    if (p == null) return;
    final i = _rowAt(p);
    if (i != _highlight) {
      setState(() => _highlight = i);
      if (i != null) glassFire(ref, HapticEvent.select);
    }
  }

  void _onSlideEnd() {
    if (widget.slideEnd?.value != true) return;
    final i = _highlight;
    if (i != null) _activate(i);
  }

  Future<void> _activate(int i) async {
    final e = widget.entries[i];
    if (!e.enabled || _state[i] == _RowState.loading) return;
    if (e.run == null) {
      widget.onDone(e);
      return;
    }
    setState(() => _state[i] = _RowState.loading);
    try {
      await e.run!();
      if (mounted) widget.onDone(null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state[i] = _RowState.error);
      glassFire(ref, HapticEvent.error);
      announceAssertive(context, e.errorText ?? "Couldn't do that");
      _errTimers.add(Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _state[i] = _RowState.idle);
      }));
    }
  }

  void _move(int from, int dir) {
    var i = from + dir;
    while (i >= 0 && i < widget.entries.length && !widget.entries[i].enabled) {
      i += dir;
    }
    if (i >= 0 && i < widget.entries.length) _nodes[i].requestFocus();
  }

  void _typeAhead(String ch, int from) {
    _typedTimer?.cancel();
    _typed += ch.toLowerCase();
    _typedTimer = Timer(const Duration(milliseconds: 800), () => _typed = '');
    final n = widget.entries.length;
    for (var k = 1; k <= n; k++) {
      final i = (from + k) % n;
      if (widget.entries[i].enabled && widget.entries[i].label.toLowerCase().startsWith(_typed)) {
        _nodes[i].requestFocus();
        return;
      }
    }
    if (_typed.length > 1) _typed = ch.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final ios = Theme.of(context).platform != TargetPlatform.android;
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '${widget.title} actions',
      child: FocusScope(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.entries.length; i++) ...[
                if (widget.entries[i].separatorBefore) const SizedBox(height: 6),
                Focus(
                  skipTraversal: true,
                  onKeyEvent: (n, ev) {
                    if (ev is! KeyDownEvent) return KeyEventResult.ignored;
                    final k = ev.logicalKey;
                    if (k == LogicalKeyboardKey.arrowDown) {
                      _move(i, 1);
                      return KeyEventResult.handled;
                    }
                    if (k == LogicalKeyboardKey.arrowUp) {
                      _move(i, -1);
                      return KeyEventResult.handled;
                    }
                    if (k == LogicalKeyboardKey.escape) {
                      widget.onDone(null);
                      return KeyEventResult.handled;
                    }
                    final ch = ev.character;
                    if (ch != null && ch.length == 1 && RegExp(r'[A-Za-z0-9]').hasMatch(ch) && !HardwareKeyboard.instance.isControlPressed && !HardwareKeyboard.instance.isMetaPressed) {
                      _typeAhead(ch, i);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: _row(context, i, hit: hit, ios: ios, wide: wide),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int i, {required double hit, required bool ios, required bool wide}) {
    final e = widget.entries[i];
    final st = _state[i];
    final highlighted = _highlight == i || widget.forceRow == i;
    final icon = e.icon == null
        ? null
        : e.destructive
            ? GlassBacking(size: 28, child: Icon(e.icon, size: 20, color: gt.colorDanger))
            : Icon(e.icon, size: 20, color: e.enabled ? gt.colorOnGlass : gt.colorLabel4);
    final label = st == _RowState.error ? (e.errorText ?? "Couldn't do that") : e.label;
    final trailing = <Widget>[
      if (st == _RowState.loading) const Padding(padding: EdgeInsets.only(left: 8), child: GlassSpinner(size: 16)),
      if (e.checked == true && st != _RowState.loading) Padding(padding: const EdgeInsets.only(left: 8), child: GlassBacking(size: 28, child: Icon(PhosphorBold.check, size: 16, color: gt.colorIris400))),
      if (wide && e.keyHint != null) ...[const SizedBox(width: 12), for (final k in keycapLabel(e.keyHint!, platform: Theme.of(context).platform)) Padding(padding: const EdgeInsets.only(left: 2), child: GlassKeycap(k))],
      if (ios && icon != null && st == _RowState.idle) Padding(padding: const EdgeInsets.only(left: 12), child: icon),
    ];
    return Semantics(
      checked: e.checked,
      key: _keys[i],
      child: GlassPressable(
        focusNode: _nodes[i],
        material: GlassMaterial.content,
        growth: GlassGrowth.light,
        sink: 0.98,
        shape: GlassShape.superellipse(20),
        enabled: e.enabled,
        haptic: HapticEvent.select,
        semanticsLabel: label,
        toggled: null,
        checked: e.checked,
        loading: st == _RowState.loading,
        disabledReason: e.enabled ? null : '${e.label} is not available',
        onTap: () => _activate(i),
        builder: (context, info) => SizedBox(
          height: hit,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted || info.states.hovered ? gt.colorFill2 : const Color(0x00000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!ios && icon != null) Padding(padding: const EdgeInsets.only(right: 12), child: icon),
                  if (st == _RowState.error) Padding(padding: const EdgeInsets.only(right: 8), child: GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, size: 20, color: gt.colorDanger))),
                  Expanded(child: GlassText(label, role: gt.typeBody, onGlass: true, color: e.enabled ? null : gt.colorLabel4, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ...trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a menu opens: below the trigger, aligned to its trailing edge, or above it when there is no room.
Rect menuRectFor(Rect anchor, Size menu, Size screen, EdgeInsets pad) {
  const gap = 8.0, margin = 8.0;
  var left = anchor.right - menu.width;
  if (anchor.center.dx < screen.width / 2) left = anchor.left;
  left = left.clamp(margin, math.max(margin, screen.width - menu.width - margin));
  var top = anchor.bottom + gap;
  if (top + menu.height > screen.height - pad.bottom - margin) top = math.max(pad.top + margin, anchor.top - gap - menu.height);
  return Rect.fromLTWH(left, top, menu.width, menu.height);
}

/// A menu presented in the root overlay (glass 7.23). It is deliberately not a `Route`: pushing a route makes the
/// `Navigator` cancel the active pointers, which would end the slide-to-select long press and the poster throw that a
/// context menu opens under a finger. An anchored menu has no route and no URL state (glass 8.0.3).
///
/// It blooms out of its trigger on `springMorph` (one [SkinGlass] whose rect animates from the trigger's to the
/// menu's, whose tier goes from the trigger's to T4 and whose radius from the trigger's to 26); the content fades in
/// over the last 40 % of the bloom; dismissal reverses over 350 ms.
class GlassMenuSpec {
  const GlassMenuSpec({
    required this.anchor,
    required this.entries,
    required this.title,
    this.triggerTier = 3,
    this.triggerRadius = 22,
    this.slide,
    this.slideEnd,
    this.atPointer = false,
    this.onClosed,
    this.preview,
    this.previewRect,
    this.previewScale = 1,
    this.onPreviewDrag,
  });

  final Rect anchor;
  final List<GlassMenuEntry> entries;
  final String title;
  final int triggerTier;
  final double triggerRadius;

  /// Slide to select: the pointer's global position while a long press is held, and the release.
  final ValueNotifier<Offset?>? slide;
  final ValueNotifier<bool>? slideEnd;

  /// A secondary click: the menu opens at the pointer without the bloom from a trigger.
  final bool atPointer;
  final VoidCallback? onClosed;

  /// A context menu (glass 7.8): `dimContext` with a blur behind a raised copy of the pressed object at [previewRect]
  /// (scaled by [previewScale]); a drag on the preview is forwarded through [onPreviewDrag] and closes the menu.
  final Widget? preview;
  final Rect? previewRect;
  final double previewScale;
  final ValueChanged<DragUpdateDetails>? onPreviewDrag;
}

class _MenuOverlay extends ConsumerStatefulWidget {
  const _MenuOverlay({required this.spec, required this.remove});
  final GlassMenuSpec spec;
  final VoidCallback remove;

  @override
  ConsumerState<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends ConsumerState<_MenuOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 434), reverseDuration: const Duration(milliseconds: 350));
  late final Animation<double> _t;
  VoidCallback? _unblock;
  GlassMotionEntry? _move;
  bool _closing = false;
  bool _dragged = false;
  FocusNode? _prevFocus;
  GlassMenuEntry? _after;

  GlassMenuSpec get spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _prevFocus = FocusManager.instance.primaryFocus;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    _t = reduced ? CurvedAnimation(parent: _c, curve: Curves.linear) : CurvedAnimation(parent: _c, curve: SpringCurve(gt.springMorph, settleMs: 434), reverseCurve: gt.curveDematerialize.curve);
    if (reduced) _c.duration = const Duration(milliseconds: 150);
    final q = ref.read(overlayQueueProvider.notifier);
    scheduleMicrotask(() {
      if (mounted) _unblock = q.registerBlocker();
    });
    if (!reduced) _move = GlassMotion.recorder.begin(MotionName.bloom.label, 434);
    _c.forward().whenComplete(() {
      if (_move != null) GlassMotion.recorder.end(_move!);
      _move = null;
    });
  }

  @override
  void dispose() {
    final unblock = _unblock;
    scheduleMicrotask(() => unblock?.call()); // a provider cannot change while the tree is finalising
    _c.dispose();
    super.dispose();
  }

  void _close([GlassMenuEntry? selected]) {
    if (_closing) return;
    _closing = true;
    _after = selected;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (reduced) _c.reverseDuration = const Duration(milliseconds: 150);
    _c.reverse().whenComplete(() {
      widget.remove();
      spec.onClosed?.call();
      final f = _prevFocus;
      if (f != null && f.context != null && f.canRequestFocus) f.requestFocus();
      final cb = _after?.onSelected;
      if (cb != null) scheduleMicrotask(cb);
    });
  }

  List<Widget> _context(bool reduced) => [
        Positioned.fill(
          child: IgnorePointer(
            child: GlassScrimMark(
              label: 'dimContext',
              child: AnimatedBuilder(
                animation: _t,
                builder: (context, _) {
                  final t = _t.value.clamp(0.0, 1.0);
                  return BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12 * t, sigmaY: 12 * t),
                    child: ColoredBox(key: const ValueKey('glass-dim-context'), color: GlassColors.dimContext.withValues(alpha: GlassColors.dimContext.a * t)),
                  );
                },
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final src = spec.previewRect!;
            final s = reduced ? 1.0 : 1 + (spec.previewScale - 1) * _t.value.clamp(0.0, 1.2);
            return Positioned.fromRect(
              rect: Rect.fromCenter(center: src.center, width: src.width * s, height: src.height * s),
              child: GestureDetector(
                onPanUpdate: (d) {
                  spec.onPreviewDrag?.call(d);
                  if (!_dragged && spec.onPreviewDrag != null) {
                    _dragged = true;
                    _close();
                  }
                },
                child: DecoratedBox(
                  key: const ValueKey('glass-context-preview'),
                  decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))]),
                  child: spec.preview,
                ),
              ),
            );
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final menu = GlassMenuMetrics.sizeFor(context, spec.entries);
    final to = spec.atPointer
        ? Rect.fromLTWH(
            spec.anchor.left.clamp(8.0, math.max(8.0, size.width - menu.width - 8)),
            spec.anchor.top.clamp(pad.top + 8, math.max(pad.top + 8, size.height - menu.height - 8)),
            menu.width,
            menu.height,
          )
        : menuRectFor(spec.anchor, menu, size, pad);
    final from = spec.atPointer ? Rect.fromCenter(center: to.topLeft, width: 8, height: 8) : spec.anchor;
    final tier = _t.drive(Tween<double>(begin: spec.triggerTier.toDouble(), end: 4));

    Widget body = Stack(
      children: [
        // The barrier: a tap outside closes (the dim of a context menu is drawn under the preview).
        Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close, child: const SizedBox.expand())),
        if (spec.preview != null) ..._context(reduced),
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final t = _t.value;
            final rect = reduced ? to : Rect.lerp(from, to, t.clamp(0.0, 1.4))!;
            final radius = reduced ? gt.radiusXl : spec.triggerRadius + (gt.radiusXl - spec.triggerRadius) * t.clamp(0.0, 1.0);
            final content = reduced ? t.clamp(0.0, 1.0) : ((t - 0.6) / 0.4).clamp(0.0, 1.0);
            return Positioned.fromRect(
              rect: rect,
              child: Opacity(
                opacity: reduced ? t.clamp(0.0, 1.0) : 1,
                child: SkinGlass(
                  key: const ValueKey('glass-menu-surface'),
                  tierValue: tier,
                  shape: GlassShape.superellipse(radius),
                  layer: GlassLayerKind.overlays,
                  moving: t < 0.999,
                  debugLabel: 'GlassMenu',
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: menu.width,
                    maxWidth: menu.width,
                    minHeight: menu.height,
                    maxHeight: menu.height,
                    child: Opacity(
                      opacity: content,
                      child: GlassMenuPanel(entries: spec.entries, title: spec.title, onDone: _close, slide: spec.slide, slideEnd: spec.slideEnd),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
    if (Router.maybeOf(context) != null) {
      body = BackButtonListener(
        onBackButtonPressed: () async {
          _close();
          return true;
        },
        child: body,
      );
    }
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: FocusScope(child: FocusTraversalGroup(child: body)),
    );
  }
}

/// Opens a menu (bloom from [GlassMenuSpec.anchor], a trigger's global rect) in the root overlay. Completes when the
/// menu has closed.
Future<void> showGlassMenu(
  BuildContext context, {
  required Rect anchor,
  required List<GlassMenuEntry> entries,
  required String title,
  int triggerTier = 3,
  double triggerRadius = 22,
  ValueNotifier<Offset?>? slide,
  ValueNotifier<bool>? slideEnd,
  bool atPointer = false,
  VoidCallback? onClosed,
}) =>
    presentGlassMenu(
      context,
      GlassMenuSpec(
        anchor: anchor,
        entries: entries,
        title: title,
        triggerTier: triggerTier,
        triggerRadius: triggerRadius,
        slide: slide,
        slideEnd: slideEnd,
        atPointer: atPointer,
        onClosed: onClosed,
      ),
    );

/// Presents [spec] in the root overlay (used by [showGlassMenu] and the context menu).
Future<void> presentGlassMenu(BuildContext context, GlassMenuSpec spec) {
  final completer = Completer<void>();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MenuOverlay(
      spec: GlassMenuSpec(
        anchor: spec.anchor,
        entries: spec.entries,
        title: spec.title,
        triggerTier: spec.triggerTier,
        triggerRadius: spec.triggerRadius,
        slide: spec.slide,
        slideEnd: spec.slideEnd,
        atPointer: spec.atPointer,
        onClosed: () {
          spec.onClosed?.call();
          if (!completer.isCompleted) completer.complete();
        },
        preview: spec.preview,
        previewRect: spec.previewRect,
        previewScale: spec.previewScale,
        onPreviewDrag: spec.onPreviewDrag,
      ),
      remove: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

/// What a trigger gets to open its menu.
class GlassMenuHandle {
  GlassMenuHandle._(this._open, this.isOpen);
  final VoidCallback _open;
  final ValueListenable<bool> isOpen;
  void open() => _open();
}

/// A pull-down menu around a trigger (glass 7.23). The trigger's own glass hides while the menu is open (the menu blooms
/// from it). A long press opens it and, without lifting, sliding onto a row highlights it (`select` per row) and
/// releasing selects; a menu opened with a tap stays open.
class GlassMenu extends ConsumerStatefulWidget {
  const GlassMenu({
    super.key,
    required this.entries,
    required this.title,
    required this.builder,
    this.triggerTier = 3,
    this.triggerRadius = 22,
    this.slideToSelect = true,
  });

  final List<GlassMenuEntry> entries;
  final String title;
  final Widget Function(BuildContext context, GlassMenuHandle menu) builder;
  final int triggerTier;
  final double triggerRadius;
  final bool slideToSelect;

  @override
  ConsumerState<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends ConsumerState<GlassMenu> {
  final ValueNotifier<bool> _open = ValueNotifier(false);
  final GlobalKey _key = GlobalKey();
  ValueNotifier<Offset?>? _slide;
  ValueNotifier<bool>? _slideEnd;

  Rect? get _rect {
    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _show({bool sliding = false}) {
    final r = _rect;
    if (r == null || _open.value) return;
    _open.value = true;
    if (sliding) {
      _slide = ValueNotifier(null);
      _slideEnd = ValueNotifier(false);
    }
    unawaited(showGlassMenu(
      context,
      anchor: r,
      entries: widget.entries,
      title: widget.title,
      triggerTier: widget.triggerTier,
      triggerRadius: widget.triggerRadius,
      slide: _slide,
      slideEnd: _slideEnd,
      onClosed: () {
        if (_disposed) return;
        _open.value = false;
        _slide = null;
        _slideEnd = null;
      },
    ));
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handle = GlassMenuHandle._(_show, _open);
    Widget trigger = ValueListenableBuilder<bool>(
      valueListenable: _open,
      builder: (context, open, _) => Opacity(opacity: open ? 0 : 1, child: KeyedSubtree(key: _key, child: widget.builder(context, handle))),
    );
    if (widget.slideToSelect) {
      trigger = GestureDetector(
        onLongPressStart: (d) => _show(sliding: true),
        onLongPressMoveUpdate: (d) => _slide?.value = d.globalPosition,
        onLongPressEnd: (d) {
          _slide?.value = d.globalPosition;
          _slideEnd?.value = true;
        },
        child: trigger,
      );
    }
    return trigger;
  }
}
