import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';

/// One open sheet, registered with the [GlassRecedeController]: how far it is toward `large`.
class GlassSheetEntry {
  GlassSheetEntry(this.id);
  final int id;

  /// 0 at `medium` or lower, 1 at `large`, following the sheet's offset every frame (never time).
  final ValueNotifier<double> largeProgress = ValueNotifier(0);

  /// The sheet's own detent state, for the stacking rule.
  bool atLarge = false;
}

/// Owns the stack of open sheets. Only the lowest sheet recedes the page; the ones above it recede the
/// sheet under them (glass 15.3 Stacking).
class GlassRecedeController {
  final List<GlassSheetEntry> _stack = [];
  final ValueNotifier<double> sheetProgress = ValueNotifier(0);

  /// The detail window's presentation progress (the covered page recedes to 0.97, blur 8, 50 %).
  final ValueNotifier<double> windowProgress = ValueNotifier(0);
  final ValueNotifier<int> count = ValueNotifier(0);
  int _nextId = 0;
  bool _dead = false;

  GlassSheetEntry? get lowest => _stack.isEmpty ? null : _stack.first;
  int get depth => _stack.length;

  GlassSheetEntry open() {
    assert(!_dead);
    final e = GlassSheetEntry(++_nextId);
    _stack.add(e);
    _rebind();
    return e;
  }

  void close(GlassSheetEntry e) {
    if (_dead) return;
    final was = lowest;
    _stack.remove(e);
    if (was == e) was?.largeProgress.removeListener(_follow);
    _rebind();
  }

  bool hasAbove(GlassSheetEntry e) => _stack.isNotEmpty && _stack.last != e && _stack.contains(e);

  void _rebind() {
    for (final s in _stack) {
      s.largeProgress.removeListener(_follow);
    }
    lowest?.largeProgress.addListener(_follow);
    sheetProgress.value = lowest?.largeProgress.value ?? 0;
    count.value = _stack.length;
  }

  void _follow() => sheetProgress.value = lowest?.largeProgress.value ?? 0;

  void dispose() {
    _dead = true;
    sheetProgress.dispose();
    windowProgress.dispose();
    count.dispose();
  }
}

/// Above the navigator (`GlassRoot`): the sheets register here and [GlassRecede] reads it.
class GlassRecedeScope extends StatefulWidget {
  const GlassRecedeScope({super.key, required this.child});
  final Widget child;

  static GlassRecedeController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RecedeInherited>()?.controller;

  @override
  State<GlassRecedeScope> createState() => _GlassRecedeScopeState();
}

class _GlassRecedeScopeState extends State<GlassRecedeScope> {
  final GlassRecedeController _c = GlassRecedeController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RecedeInherited(controller: _c, child: widget.child);
}

class _RecedeInherited extends InheritedWidget {
  const _RecedeInherited({required this.controller, required super.child});
  final GlassRecedeController controller;
  @override
  bool updateShouldNotify(_RecedeInherited old) => old.controller != controller;
}

/// Wraps a page: `Transform.scale(1 - 0.06 p)`, `ClipRSuperellipse` radius `12 p`, blur `8 p` and a black
/// overlay at `0.4 p` (60 % brightness at `large`). Under reduced motion: the dim only.
class GlassRecede extends ConsumerWidget {
  const GlassRecede({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = GlassRecedeScope.maybeOf(context);
    if (scope == null) return child;
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return ListenableBuilder(
      listenable: Listenable.merge([scope.sheetProgress, scope.windowProgress]),
      child: child,
      builder: (context, child) {
        final p = scope.sheetProgress.value;
        final w = scope.windowProgress.value;
        if (p <= 0 && w <= 0) return child!;
        final dim = _max(0.4 * p, 0.5 * w);
        final overlay = IgnorePointer(
          child: ColoredBox(key: const ValueKey('glass-recede-dim'), color: Color.fromRGBO(0, 0, 0, dim)),
        );
        Widget stacked = Stack(fit: StackFit.passthrough, children: [child!, Positioned.fill(child: overlay)]);
        if (reduced) return stacked;
        final blur = _max(8 * p, 8 * w);
        if (blur > 0.01) {
          stacked = ImageFiltered(
            key: const ValueKey('glass-recede-blur'),
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
            child: stacked,
          );
        }
        return Transform.scale(
          key: const ValueKey('glass-recede-scale'),
          scale: (1 - 0.06 * p) * (1 - 0.03 * w),
          child: ClipRSuperellipse(
            key: const ValueKey('glass-recede-clip'),
            borderRadius: BorderRadius.circular(_max(12 * p, 12 * w)),
            child: stacked,
          ),
        );
      },
    );
  }
}

double _max(double a, double b) => a > b ? a : b;
