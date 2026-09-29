import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';

/// One lit object per screen (glass 2.4.2 rule 8). Mounted `tinted` objects register here; in debug, two
/// visible lit objects outside an overlay print one warning. Sheets and alerts (mobile/27) call
/// [suppressLit] so the screen's lit object drops to `glassThin` and its caustic fades over 180 ms.
abstract final class GlassLit {
  static final Set<Object> _screen = {};
  static final ValueNotifier<int> _suppress = ValueNotifier(0);
  static bool _warned = false;

  /// Visible lit objects outside an overlay.
  static int get count => _screen.length;

  static ValueListenable<int> get suppression => _suppress;

  static bool get suppressed => _suppress.value > 0;

  @visibleForTesting
  static void reset() {
    _screen.clear();
    _suppress.value = 0;
    _warned = false;
  }

  static void register(Object owner, {bool overlay = false}) {
    if (overlay) return;
    _screen.add(owner);
    if (kDebugMode && _screen.length > 1 && !_warned) {
      _warned = true;
      debugPrint('GlassLit: ${_screen.length} lit (tinted) objects are visible on one screen; the spec allows one (glass 2.4.2 rule 8).');
    }
  }

  static void unregister(Object owner) {
    _screen.remove(owner);
    if (_screen.length < 2) _warned = false;
  }

  /// Returns the release callback.
  static VoidCallback suppress() {
    _suppress.value++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      _suppress.value--;
    };
  }
}

/// Top-level convenience named in the spec.
VoidCallback suppressLit() => GlassLit.suppress();

/// Marks a subtree as an overlay: lit objects inside do not count against the screen's one.
class GlassLitOverlay extends InheritedWidget {
  const GlassLitOverlay({super.key, required super.child});
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassLitOverlay>() != null;
  @override
  bool updateShouldNotify(GlassLitOverlay old) => false;
}

/// Registers the state that owns a lit object and rebuilds it when suppression changes.
mixin GlassLitState<T extends StatefulWidget> on State<T> {
  bool _registered = false;

  bool get isLit;

  void syncLit() {
    final want = isLit && mounted;
    if (want && !_registered) {
      _registered = true;
      GlassLit.register(this, overlay: GlassLitOverlay.of(context));
    } else if (!want && _registered) {
      _registered = false;
      GlassLit.unregister(this);
    }
  }

  void _onSuppress() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    GlassLit.suppression.addListener(_onSuppress);
  }

  @override
  void dispose() {
    GlassLit.suppression.removeListener(_onSuppress);
    if (_registered) GlassLit.unregister(this);
    super.dispose();
  }
}

/// The caustic behind a lit object that fades out over 180 ms while lit is suppressed.
class GlassLitCaustic extends StatelessWidget {
  const GlassLitCaustic({super.key, required this.child, this.pressed = false});
  final Widget child;
  final bool pressed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: GlassLit.suppression,
        builder: (context, n, child) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: n > 0 ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: GlassCaustic(pressed: pressed, child: const SizedBox.expand()),
                ),
              ),
            ),
            child!,
          ],
        ),
        child: child,
      );
}
