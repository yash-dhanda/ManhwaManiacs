import 'package:flutter/widgets.dart';

/// What a screen publishes about itself for the depth observer and the stack overview (`GlassScaffold` writes it).
class GlassRouteMeta extends ChangeNotifier {
  String title = '';
  bool mature = false;
  Color? rimTint;

  void publish({String? title, bool? mature, Color? rimTint}) {
    final t = title ?? this.title, m = mature ?? this.mature;
    if (t == this.title && m == this.mature && rimTint == this.rimTint) return;
    this.title = t;
    this.mature = m;
    this.rimTint = rimTint;
    notifyListeners();
  }
}

/// `GlassRouteFrame` registers its meta here under the route's frame key; the depth observer reads it on push.
abstract final class GlassRouteMetaRegistry {
  static final Map<Object, GlassRouteMeta> _byKey = {};
  static GlassRouteMeta register(Object key) => _byKey.putIfAbsent(key, GlassRouteMeta.new);
  static GlassRouteMeta? of(Object key) => _byKey[key];
  static void unregister(Object key) => _byKey.remove(key);
}

/// Installed by `GlassRouteFrame`; `GlassScaffold` finds its route's meta here.
class GlassRouteMetaScope extends InheritedWidget {
  const GlassRouteMetaScope({super.key, required this.meta, required super.child});
  final GlassRouteMeta meta;

  static GlassRouteMeta? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassRouteMetaScope>()?.meta;

  @override
  bool updateShouldNotify(GlassRouteMetaScope old) => old.meta != meta;
}
