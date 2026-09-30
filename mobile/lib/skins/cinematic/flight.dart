import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One poster in flight: [key] is `'{source_id}:{series_key}'`, [rect] where it was on the wall.
class FlightItem {
  const FlightItem({required this.key, required this.image, required this.rect});
  final String key;
  final ui.Image image;
  final Rect rect;
}

enum FlightStatus { idle, armed, flying, landed }

class FlightState {
  const FlightState({this.status = FlightStatus.idle, this.items = const [], this.targets = const {}, this.landedKeys = const {}});
  final FlightStatus status;
  final List<FlightItem> items;
  final Map<String, Rect> targets;

  /// Copies that have arrived; their Tonight slots show again.
  final Set<String> landedKeys;

  bool get active => status == FlightStatus.armed || status == FlightStatus.flying;

  /// Whether Tonight's slot for [key] stays hidden right now.
  bool hides(String key) => active && items.any((i) => i.key == key) && !landedKeys.contains(key);
}

/// Cut to home (cinematic 4.5): the wall arms it, Tonight lands it. Nothing here paints; the
/// `FlightLayer` above the Navigator does.
class CineFlightNotifier extends Notifier<FlightState> {
  @override
  FlightState build() => const FlightState();

  void arm(List<FlightItem> items) => state = FlightState(status: FlightStatus.armed, items: items);

  void land(Map<String, Rect> targets) {
    if (state.status != FlightStatus.armed) return;
    state = FlightState(status: FlightStatus.flying, items: state.items, targets: targets);
  }

  void landedOne(String key) {
    if (!state.active) return;
    state = FlightState(status: state.status, items: state.items, targets: state.targets, landedKeys: {...state.landedKeys, key});
  }

  /// The last copy landed: Tonight plays its Front page moment.
  void done() => state = const FlightState(status: FlightStatus.landed);

  void reset() => state = const FlightState();
}

final cineFlightProvider = NotifierProvider<CineFlightNotifier, FlightState>(CineFlightNotifier.new, name: 'cineFlight');

final Map<String, GlobalKey> _slotKeys = {};

/// A stable key per `'{source_id}:{series_key}'`: Tonight's `first_picks` slots carry it.
GlobalKey flightSlotKey(String key) => _slotKeys.putIfAbsent(key, GlobalKey.new);

/// The flight's duration for [n] posters: 480 ms each, 60 ms apart.
Duration flightDuration(int n) => Duration(milliseconds: 480 + 60 * (n < 1 ? 0 : n - 1));
