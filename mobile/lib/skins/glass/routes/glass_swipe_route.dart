// Adapted from swipeable_page_route 0.4.8 (MIT, Copyright (c) 2020 Jonas Wanke) and Flutter's CupertinoPageRoute back gesture
// (BSD-3, Copyright 2014 The Flutter Authors). Glass changes: 615 ms durations with GlassPushTransition, a velocity-spring drag end,
// a full-width drag that yields to horizontal-drag owners, a 20 px reader strip, and threshold haptics.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show MaterialRouteTransitionMixin;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/transitions/glass_push_transition.dart';

/// The iOS route of Glass pages: full-width back swipe (`canOnlySwipeFromEdge: false`) unless [edgeOnly] is set.
class GlassSwipePage<T> extends Page<T> {
  const GlassSwipePage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.builder,
    this.canSwipe = true,
    this.edgeOnly,
    this.maintainState = true,
    this.instantEnter = false,
  });

  final WidgetBuilder builder;
  final bool canSwipe;

  /// Readers: the Dive carries the entrance, so the push itself is instant; the pop still runs the 615 ms transition.
  final bool instantEnter;

  /// Reader pages pass 20: only a drag starting inside that strip pops.
  final double? edgeOnly;
  final bool maintainState;

  @override
  Route<T> createRoute(BuildContext context) => GlassSwipePageRoute<T>(
        builder: builder,
        settings: this,
        canSwipe: canSwipe,
        edgeOnly: edgeOnly,
        maintainState: maintainState,
        instantEnter: instantEnter,
      );
}

class GlassSwipePageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  GlassSwipePageRoute({required this.builder, super.settings, this.canSwipe = true, this.edgeOnly, this.maintainState = true, this.instantEnter = false});

  final bool instantEnter;

  final WidgetBuilder builder;
  bool canSwipe;
  double? edgeOnly;

  @override
  final bool maintainState;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => null;

  @override
  Duration get transitionDuration => instantEnter ? Duration.zero : glassPageDuration();

  @override
  Duration get reverseTransitionDuration => glassPageDuration();

  @override
  bool get popGestureEnabled => _enabled(this, canSwipe);

  static bool _enabled<T>(PageRoute<T> route, bool canSwipe) {
    if (!canSwipe || route.isFirst || route.willHandlePopInternally) return false;
    if (route.popDisposition == RoutePopDisposition.doNotPop) return false;
    if (route.fullscreenDialog) return false;
    if (route.animation!.status != AnimationStatus.completed) return false;
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) return false;
    if (route.popGestureInProgress) return false;
    return true;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final wrapped = _GlassBackGestureDetector<T>(
      edgeOnly: edgeOnly,
      enabledCallback: () => _enabled(this, canSwipe),
      onStart: () => _GlassBackGestureController<T>(navigator: navigator!, controller: controller!, ref: _refOf(context)),
      child: child,
    );
    return GlassPushTransition(animation: animation, secondaryAnimation: secondaryAnimation, isGesture: popGestureInProgress, child: wrapped);
  }

  static ProviderContainer _refOf(BuildContext context) => ProviderScope.containerOf(context);
}

typedef _Enabled = bool Function();

class _GlassBackGestureDetector<T> extends StatefulWidget {
  const _GlassBackGestureDetector({required this.edgeOnly, required this.enabledCallback, required this.onStart, required this.child});
  final double? edgeOnly;
  final _Enabled enabledCallback;
  final _GlassBackGestureController<T> Function() onStart;
  final Widget child;

  @override
  State<_GlassBackGestureDetector<T>> createState() => _GlassBackGestureDetectorState<T>();
}

class _GlassBackGestureDetectorState<T> extends State<_GlassBackGestureDetector<T>> {
  _GlassBackGestureController<T>? _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: {
              _OwnerAwareDragRecognizer: GestureRecognizerFactoryWithHandlers<_OwnerAwareDragRecognizer>(
                () => _OwnerAwareDragRecognizer(
                  debugOwner: this,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                  started: () => _controller != null,
                  enabled: widget.enabledCallback,
                  edgeOnly: () => widget.edgeOnly,
                  owned: (p, right) => ProviderScope.containerOf(context).read(glassDragOwnerRegistryProvider).ownsDragAt(p, movingRight: right),
                ),
                (_OwnerAwareDragRecognizer r) => r
                  ..onStart = (DragStartDetails _) {
                    _controller = widget.onStart();
                  }
                  ..onUpdate = (DragUpdateDetails d) {
                    _controller?.update(_logical(d.primaryDelta! / context.size!.width));
                  }
                  ..onEnd = (DragEndDetails d) {
                    _controller?.end(_logical(d.velocity.pixelsPerSecond.dx / context.size!.width), context.size!.width);
                    _controller = null;
                  }
                  ..onCancel = () {
                    _controller?.end(0, context.size?.width ?? 1);
                    _controller = null;
                  },
              ),
            },
          ),
        ),
      ],
    );
  }

  double _logical(double v) => Directionality.of(context) == TextDirection.rtl ? -v : v;
}

class _OwnerAwareDragRecognizer extends HorizontalDragGestureRecognizer {
  _OwnerAwareDragRecognizer({required this.rtl, required this.started, required this.enabled, required this.edgeOnly, required this.owned, super.debugOwner});
  final bool rtl;
  final bool Function() started;
  final _Enabled enabled;
  final double? Function() edgeOnly;
  final bool Function(Offset global, bool movingRight) owned;

  @override
  void handleEvent(PointerEvent event) {
    if (_should(event)) {
      super.handleEvent(event);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  bool _should(PointerEvent event) {
    if (started()) return true;
    if (!enabled()) return false;
    final right = event.delta.dx > 0;
    if (!(rtl ? event.delta.dx <= 0 : event.delta.dx >= 0)) return false;
    if (event is PointerDownEvent) {
      final strip = edgeOnly();
      if (strip != null && !rtl && event.localPosition.dx > strip) return false;
      if (strip == null && owned(event.position, !rtl && (right || event.delta.dx == 0))) return false;
    }
    return true;
  }
}

class _GlassBackGestureController<T> {
  _GlassBackGestureController({required this.navigator, required this.controller, required this.ref}) {
    navigator.didStartUserGesture();
    _crossed = controller.value < 0.5;
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final ProviderContainer ref;
  late bool _crossed;

  void update(double delta) {
    controller.value -= delta;
    final crossed = controller.value < 0.5;
    if (crossed != _crossed) {
      _crossed = crossed;
      unawaited(ref.read(glassHapticsProvider).fire(crossed ? HapticEvent.thresholdCross : HapticEvent.thresholdBack));
    }
  }

  /// [velocity] is in screen widths per second, positive toward the trailing edge (a pop).
  void end(double velocity, double width) {
    final v = velocity;
    final pop = v.abs() >= 1 ? v > 0 : controller.value < 0.5;
    // The controller value falls while the page leaves, so its velocity is -v.
    final spring = springOf(pop ? GlassSprings.dismiss : GlassSprings.settle);
    if (pop) {
      navigator.pop();
      if (controller.isAnimating) {
        unawaited(controller.animateWith(SpringSimulation(spring, controller.value, 0, -v)));
      }
    } else {
      unawaited(controller.animateWith(SpringSimulation(spring, controller.value, 1, math.max(-v, 0))));
    }
    if (controller.isAnimating) {
      late AnimationStatusListener l;
      l = (s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          navigator.didStopUserGesture();
          controller.removeStatusListener(l);
        }
      };
      controller.addStatusListener(l);
    } else {
      navigator.didStopUserGesture();
    }
  }
}


/// The Android page: a Material route whose transition theme is the Glass push and predictive-back card (glass 8.0.5).
class GlassMaterialPage<T> extends Page<T> {
  const GlassMaterialPage({super.key, super.name, super.arguments, super.restorationId, required this.builder, this.instantEnter = false, this.maintainState = true});
  final WidgetBuilder builder;
  final bool instantEnter;
  final bool maintainState;

  @override
  Route<T> createRoute(BuildContext context) => _GlassMaterialRoute<T>(this);
}

class _GlassMaterialRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _GlassMaterialRoute(GlassMaterialPage<T> page) : super(settings: page);

  GlassMaterialPage<T> get _page => settings as GlassMaterialPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.builder(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  Duration get transitionDuration => _page.instantEnter ? Duration.zero : glassPageDuration();

  @override
  Duration get reverseTransitionDuration => glassPageDuration();
}
