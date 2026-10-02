import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who owns a horizontal drag (glass 8.0.5): a swipe row, a rail or a pager that scrolls sideways, or a chart scrub.
enum GlassDragOwnerKind { row, rail, pager }

/// The width of the strip at the leading screen edge that the iOS back swipe owns.
const double kBackSwipeStrip = 24;

class _Entry {
  _Entry(this.kind, this.rect, this.atLeadingEdge);
  final GlassDragOwnerKind kind;
  final Rect Function() rect;
  final ValueListenable<bool>? atLeadingEdge;
}

/// Where horizontal drags belong to a widget rather than the page back swipe. `mobile/29`'s back-swipe route asks
/// [ownsDragAt] at pointer down.
class GlassDragOwnerRegistry {
  final Map<Object, _Entry> _owners = {};

  /// Registers (or replaces) an owner. [rect] is read lazily, so scrolling never leaves it stale.
  void register(Object key, {required GlassDragOwnerKind kind, required Rect Function() rect, ValueListenable<bool>? atLeadingEdge}) =>
      _owners[key] = _Entry(kind, rect, atLeadingEdge);

  void unregister(Object key) => _owners.remove(key);

  int get length => _owners.length;

  /// True when [global] lies inside an owner and more than 24 px from the leading screen edge, except a pager or rail whose
  /// content is at its leading edge while the drag moves right (the drag then pops the page).
  bool ownsDragAt(Offset global, {required bool movingRight, double screenLeft = 0}) {
    if (global.dx - screenLeft <= kBackSwipeStrip) return false;
    for (final e in _owners.values) {
      if (!e.rect().contains(global)) continue;
      final passes = (e.kind == GlassDragOwnerKind.pager || e.kind == GlassDragOwnerKind.rail) && (e.atLeadingEdge?.value ?? false) && movingRight;
      if (!passes) return true;
    }
    return false;
  }
}

final glassDragOwnerRegistryProvider = Provider<GlassDragOwnerRegistry>((ref) => GlassDragOwnerRegistry());

/// Registers its global rect while mounted (glass 8.0.5).
class GlassDragOwner extends ConsumerStatefulWidget {
  const GlassDragOwner({super.key, required this.child, required this.kind, this.atLeadingEdge});
  final Widget child;
  final GlassDragOwnerKind kind;
  final ValueListenable<bool>? atLeadingEdge;

  @override
  ConsumerState<GlassDragOwner> createState() => _GlassDragOwnerState();
}

class _GlassDragOwnerState extends ConsumerState<GlassDragOwner> {
  late final GlassDragOwnerRegistry _registry = ref.read(glassDragOwnerRegistryProvider);

  /// False in an offstage tab branch or under an opaque route (both mute tickers): a hidden pager or rail there kept its full-screen
  /// rect and swallowed the back swipe of the page on top.
  bool _onstage = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onstage = TickerMode.valuesOf(context).enabled;
  }

  Rect _rect() {
    if (!_onstage || !mounted) return Rect.zero;
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.hasSize && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  void _register() => _registry.register(this, kind: widget.kind, rect: _rect, atLeadingEdge: widget.atLeadingEdge);

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(GlassDragOwner old) {
    super.didUpdateWidget(old);
    _register();
  }

  @override
  void dispose() {
    _registry.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
