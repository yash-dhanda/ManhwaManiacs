// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Adapted from Flutter 3.44.6's private `_PredictiveBackGestureDetector`
// (material/predictive_back_page_transitions_builder.dart): it forwards the
// engine's `PredictiveBackEvent`s to the route so Glass routes can shape the
// transition themselves. `GlassPageTransitionsBuilder` (mobile/29) reuses it.

import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:flutter/widgets.dart';

enum GlassPredictiveBackPhase { idle, start, update, commit, cancel }

typedef GlassPredictiveBackBuilder = Widget Function(
  BuildContext context,
  GlassPredictiveBackPhase phase,
  PredictiveBackEvent? startBackEvent,
  PredictiveBackEvent? currentBackEvent,
);

class GlassPredictiveBackDetector extends StatefulWidget {
  const GlassPredictiveBackDetector({super.key, required this.route, required this.builder});

  final PageRoute<dynamic> route;
  final GlassPredictiveBackBuilder builder;

  @override
  State<GlassPredictiveBackDetector> createState() => _GlassPredictiveBackDetectorState();
}

class _GlassPredictiveBackDetectorState extends State<GlassPredictiveBackDetector> with WidgetsBindingObserver {
  bool get _isEnabled => widget.route.isCurrent && widget.route.popGestureEnabled;

  GlassPredictiveBackPhase _phase = GlassPredictiveBackPhase.idle;
  set phase(GlassPredictiveBackPhase p) {
    if (_phase != p && mounted) setState(() => _phase = p);
  }

  PredictiveBackEvent? _start;
  PredictiveBackEvent? _current;

  void _events(PredictiveBackEvent? s, PredictiveBackEvent? c) {
    if ((_start != s || _current != c) && mounted) {
      setState(() {
        _start = s;
        _current = c;
      });
    }
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    phase = GlassPredictiveBackPhase.start;
    if (backEvent.isButtonEvent || !_isEnabled) return false;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    _events(backEvent, backEvent);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    phase = GlassPredictiveBackPhase.update;
    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    _events(_start, backEvent);
  }

  @override
  void handleCancelBackGesture() {
    phase = GlassPredictiveBackPhase.cancel;
    widget.route.handleCancelBackGesture();
    _events(null, null);
  }

  @override
  void handleCommitBackGesture() {
    phase = GlassPredictiveBackPhase.commit;
    widget.route.handleCommitBackGesture();
    _events(null, null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = widget.route.popGestureInProgress ? _phase : GlassPredictiveBackPhase.idle;
    return widget.builder(context, effective, _start, _current);
  }
}
