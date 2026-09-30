import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

/// The friend orbs a poster can be thrown onto (glass 7.8, 7.26): each registers a way to read its centre,
/// and a poster asks for the current `Magnet` targets when it is lifted.
class GlassMagnetRegistry {
  final Map<Object, Offset? Function()> _centres = {};
  final Map<Object, Object?> _owners = {};

  /// [owner] identifies who registered: a glass group can mount a child twice for a moment, and the copy that goes must not take the
  /// survivor's registration with it.
  void register(Object id, Offset? Function() centre, {Object? owner}) {
    _centres[id] = centre;
    _owners[id] = owner;
  }

  void unregister(Object id, {Object? owner}) {
    if (owner != null && _owners[id] != owner) return;
    _centres.remove(id);
    _owners.remove(id);
  }

  /// The targets, in global coordinates, of every orb that is mounted.
  List<MagnetTarget> get targets => [
        for (final e in _centres.entries)
          if (e.value() != null) MagnetTarget(e.value()!, e.key),
      ];
}

class GlassMagnetScope extends InheritedWidget {
  const GlassMagnetScope({super.key, required this.registry, required super.child});
  final GlassMagnetRegistry registry;

  static GlassMagnetRegistry? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassMagnetScope>()?.registry;

  @override
  bool updateShouldNotify(GlassMagnetScope old) => old.registry != registry;
}
