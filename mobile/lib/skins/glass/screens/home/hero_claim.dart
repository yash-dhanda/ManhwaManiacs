import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart';

/// One cover per series carries the shared-element tag on a screen (the same series can sit in the spotlight and in three rails, and
/// two heroes with one tag cannot fly). A cover claims its series while it is mounted; the first claimant wins.
class HomeHeroClaims {
  final Map<String, Object> _owners = {};

  bool claim(String key, Object owner) {
    final cur = _owners[key];
    if (cur == null || identical(cur, owner)) {
      _owners[key] = owner;
      return true;
    }
    return false;
  }

  void release(String key, Object owner) {
    if (identical(_owners[key], owner)) _owners.remove(key);
  }
}

class HomeHeroScope extends InheritedWidget {
  const HomeHeroScope({super.key, required this.claims, required super.child});
  final HomeHeroClaims claims;

  static HomeHeroClaims? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<HomeHeroScope>()?.claims;

  @override
  bool updateShouldNotify(HomeHeroScope old) => false;
}

/// [GlassCoverHero] for the first cover of a series on Home, the plain [child] for repeats.
class HomeHero extends StatefulWidget {
  const HomeHero({super.key, required this.sourceId, required this.seriesKey, required this.child});
  final String sourceId, seriesKey;
  final Widget child;

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  final Object _token = Object();
  HomeHeroClaims? _claims;
  bool _owns = false;

  String get _key => '${widget.sourceId}:${widget.seriesKey}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _claims ??= HomeHeroScope.maybeOf(context);
    _owns = _claims?.claim(_key, _token) ?? true;
  }

  @override
  void dispose() {
    _claims?.release(_key, _token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _owns ? GlassCoverHero(sourceId: widget.sourceId, seriesKey: widget.seriesKey, child: widget.child) : widget.child;
}
