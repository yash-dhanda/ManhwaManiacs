import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';

/// How a touch opens the reading menu (Settings > Reading 'Open menu with'), one rule for every reader: strip, paged,
/// guided and both novel readers, in both skins. Stored per profile in the reader settings record as `menuOpen`.
enum MenuOpen {
  /// A single tap in the menu zone opens or closes it, at once (the default).
  tap('Tap'),

  /// A double tap in the menu zone.
  doubleTap('Double tap'),

  /// A tap in the band along the top or bottom edge; the centre does nothing (side zones still act).
  edge('Top or bottom edge');

  const MenuOpen(this.label);
  final String label;

  /// What the stored value reads as, `tap` when missing or unknown.
  static MenuOpen of(JsonRecord r) => MenuOpen.values.asNameMap()[r.data['menuOpen']] ?? MenuOpen.tap;

  /// Under VoiceOver/TalkBack every mode acts as [tap], so the menu stays one activation away.
  MenuOpen forScreenReader(bool on) => on ? MenuOpen.tap : this;

  /// The tap-zone help line.
  String get help => switch (this) {
        MenuOpen.tap => 'Tap Menu to show the controls.',
        MenuOpen.doubleTap => 'Double-tap Menu to show the controls.',
        MenuOpen.edge => 'Tap the top or bottom edge to show the controls.',
      };

  /// Whether a tap of [kind] toggles the menu: in the menu zone ([inMenuZone]) for [tap] and [doubleTap], in the
  /// top or bottom band ([inEdge], see [inMenuEdge]) for [edge].
  bool toggles(TapKind kind, {required bool inMenuZone, required bool inEdge}) => switch (this) {
        MenuOpen.tap => inMenuZone,
        MenuOpen.doubleTap => inMenuZone && kind == TapKind.double,
        MenuOpen.edge => inEdge,
      };
}

/// Whether [p] (in a box of [size] that sits under the [padding] safe areas) lies in the edge band that opens the
/// menu in [MenuOpen.edge]: 12 % of the height, at least 64, measured from inside each safe area.
bool inMenuEdge(Offset p, Size size, {EdgeInsets padding = EdgeInsets.zero}) {
  final band = math.max(64.0, size.height * 0.12);
  return p.dy <= padding.top + band || p.dy >= size.height - padding.bottom - band;
}

/// The reader settings record's `menuAtChapterEnd`: the menu shows by itself at the end of a chapter (default on).
bool menuAtChapterEnd(JsonRecord r) => r.boolOf('menuAtChapterEnd', true);
