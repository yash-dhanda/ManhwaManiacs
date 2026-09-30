import 'dart:async';

import 'package:flutter/widgets.dart';

/// The one 60 s timer of the Circle (cinematic 9.3.8). It runs while at least one registered scope is
/// visible (an enabled `TickerMode`: offstage branches and covered routes are not) and the app is
/// resumed; [onTick] refetches what the Circle polls.
class CirclePollController with WidgetsBindingObserver {
  CirclePollController({required this.onTick, this.period = const Duration(seconds: 60)});

  final void Function() onTick;
  final Duration period;
  final Map<Object, bool> _scopes = {};
  bool _resumed = true;
  Timer? _timer;

  /// Whether the timer is armed.
  bool get running => _timer != null;

  void register(Object scope, {required bool visible}) {
    _scopes[scope] = visible;
    _sync();
  }

  void setVisible(Object scope, bool visible) => register(scope, visible: visible);

  void unregister(Object scope) {
    _scopes.remove(scope);
    _sync();
  }

  void setResumed(bool resumed) {
    _resumed = resumed;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => setResumed(state == AppLifecycleState.resumed);

  void _sync() {
    final want = _resumed && _scopes.containsValue(true);
    if (want && _timer == null) {
      _timer = Timer.periodic(period, (_) => onTick());
    } else if (!want) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _scopes.clear();
  }
}
