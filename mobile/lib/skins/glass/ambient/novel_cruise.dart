import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_auto_scroll.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_controller.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';

/// The novel's scroll column as a cruise source (glass 8.15.4): [NovelAutoScroll] moves the `ScrollPosition` at
/// `m x (wpm / 60) / wordsPerLine x lineHeightPx`. Flick-to-cruise is the manga strip's, so [engaged] never fires.
class NovelCruiseSource implements CruiseSource {
  NovelCruiseSource(this.auto, this.scroll);
  final NovelAutoScroll auto;
  final ScrollController scroll;

  @override
  Listenable get changes => Listenable.merge([auto, auto.controller]);
  @override
  bool get running => auto.running;
  @override
  AutoScrollController get autoScroll => auto.controller;

  /// A coasting drag counts as moving while the position is still scrolling by itself.
  @override
  double get scrollVelocity => scroll.hasClients && scroll.position.isScrollingNotifier.value ? 100 : 0;
  @override
  Stream<double> get engaged => const Stream<double>.empty();
  @override
  void armEngage() {}
  @override
  void start(double speed, Duration ramp) {
    auto.controller.configure(ramp: ramp);
    auto.speedX = speed;
    auto.start();
  }

  @override
  void setSpeed(double speed) {
    auto.speedX = speed;
    auto.refresh();
  }

  @override
  void stop() => auto.stop();
}
