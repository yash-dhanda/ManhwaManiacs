// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Adapted from Flutter 3.44.6's `CupertinoScrollbar` (cupertino/scrollbar.dart): the same behaviour and metrics on both
// platforms, with the Glass colour `rgba(255,255,255,0.28)` and a 200 ms press before the thumb can be dragged.

import 'package:flutter/widgets.dart';

const double _kMinLength = 36;
const double _kMinOverscrollLength = 8;
const Duration _kTimeToFade = Duration(milliseconds: 1200);
const Duration _kFadeDuration = Duration(milliseconds: 250);
const Duration _kResizeDuration = Duration(milliseconds: 100);
const Color _kColor = Color(0x47FFFFFF);
const double _kMainAxisMargin = 3;
const double _kCrossAxisMargin = 3;

/// The scrollbar of Glass lists (glass 7.32): thickness 3, 8 while pressed, radius 1.5 and 4, colour
/// `rgba(255,255,255,0.28)`, draggable after a 200 ms press, shown while scrolling.
class GlassScrollbar extends RawScrollbar {
  const GlassScrollbar({
    super.key,
    required super.child,
    super.controller,
    bool? thumbVisibility,
    double super.thickness = 3,
    this.thicknessWhileDragging = 8,
    Radius super.radius = const Radius.circular(1.5),
    this.radiusWhileDragging = const Radius.circular(4),
    ScrollNotificationPredicate? notificationPredicate,
    super.scrollbarOrientation,
    super.mainAxisMargin = _kMainAxisMargin,
  }) : super(
          thumbVisibility: thumbVisibility ?? false,
          fadeDuration: _kFadeDuration,
          timeToFade: _kTimeToFade,
          pressDuration: const Duration(milliseconds: 200),
          notificationPredicate: notificationPredicate ?? defaultScrollNotificationPredicate,
        );

  final double thicknessWhileDragging;
  final Radius radiusWhileDragging;

  @override
  RawScrollbarState<GlassScrollbar> createState() => _GlassScrollbarState();
}

class _GlassScrollbarState extends RawScrollbarState<GlassScrollbar> {
  late AnimationController _thickness;

  double get _t => widget.thickness! + _thickness.value * (widget.thicknessWhileDragging - widget.thickness!);
  Radius get _r => Radius.lerp(widget.radius, widget.radiusWhileDragging, _thickness.value)!;

  @override
  void initState() {
    super.initState();
    _thickness = AnimationController(vsync: this, duration: _kResizeDuration);
    _thickness.addListener(updateScrollbarPainter);
  }

  @override
  void updateScrollbarPainter() {
    scrollbarPainter
      ..color = _kColor
      ..textDirection = Directionality.of(context)
      ..thickness = _t
      ..mainAxisMargin = widget.mainAxisMargin
      ..crossAxisMargin = _kCrossAxisMargin
      ..radius = _r
      ..padding = MediaQuery.paddingOf(context)
      ..minLength = _kMinLength
      ..minOverscrollLength = _kMinOverscrollLength
      ..scrollbarOrientation = widget.scrollbarOrientation;
  }

  @override
  void handleThumbPress() {
    if (getScrollbarDirection() == null) return;
    super.handleThumbPress();
    _thickness.forward();
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    if (getScrollbarDirection() == null) return;
    _thickness.reverse();
    super.handleThumbPressEnd(localPosition, velocity);
  }

  @override
  void dispose() {
    _thickness.dispose();
    super.dispose();
  }
}
