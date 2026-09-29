import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';

/// Registers its subtree as a scrim in the glass registry while mounted (glass 2.4.4: `dimContext` and the scroll
/// edges are backdrop filters that count as scrims, not layers).
class GlassScrimMark extends ConsumerStatefulWidget {
  const GlassScrimMark({super.key, required this.label, required this.child, this.kind = GlassLayerKind.overlays});
  final String label;
  final GlassLayerKind kind;
  final Widget child;

  @override
  ConsumerState<GlassScrimMark> createState() => _GlassScrimMarkState();
}

class _GlassScrimMarkState extends ConsumerState<GlassScrimMark> {
  late final GlassRegistryController _registry = ref.read(glassRegistryProvider.notifier);
  late final int _id = _registry.newId();
  bool _on = false;

  Rect? _rect() {
    if (!mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      if (!mounted) return;
      _on = true;
      _registry.registerSafe(GlassRegistration(id: _id, label: widget.label, kind: widget.kind, shapes: 0, rect: _rect, scrim: true));
    });
  }

  @override
  void dispose() {
    final r = _registry, id = _id;
    if (_on) scheduleMicrotask(() => r.unregisterSafe(id));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
