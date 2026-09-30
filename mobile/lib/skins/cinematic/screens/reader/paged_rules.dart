import 'dart:ui';

// The paged layouts' widget-free rules (cinematic 8.14.7, 8.14.8).

/// The device key holding the tap-zone layouts already shown as bands (`layout:left,centre,right`).
const kZonesSeenKey = 'mm.reader.zones-seen';

/// The device key of the one-time K01 migration toast.
const kK01ToastSeenKey = 'mm.reader.k01-toast-seen';

/// The toast's words.
const kK01ToastText = 'Sideways strips are now pages. Change it in Reading setup.';

/// Three of `previous | menu | next`, left to right: the user's own, else the automatic layout
/// (previous / menu / next, mirrored for right-to-left).
List<String> resolveZones(List<String>? custom, {required bool rtl}) =>
    custom ?? (rtl ? const ['next', 'menu', 'previous'] : const ['previous', 'menu', 'next']);

/// The zone a tap at [x] falls in on a screen [width] wide: 30 / 40 / 30 %.
int zoneIndex(double x, double width) {
  if (width <= 0) return 1;
  final r = x / width;
  if (r < 0.3) return 0;
  if (r > 0.7) return 2;
  return 1;
}

/// The action of the zone under [x].
String zoneAction(double x, double width, List<String> zones) => zones[zoneIndex(x, width)];

/// The key stored in [kZonesSeenKey] for [zones] in [layout] (`single` or `double`).
String zoneLayoutKey(String layout, List<String> zones) => '$layout:${zones.join(',')}';

/// Whether the labelled bands show: the first time this layout of zones is used on this device.
bool shouldShowBands(List<String> seen, String layout, List<String> zones) => !seen.contains(zoneLayoutKey(layout, zones));

/// [seen] with this layout of zones added.
List<String> markZonesSeen(List<String> seen, String layout, List<String> zones) =>
    seen.contains(zoneLayoutKey(layout, zones)) ? seen : [...seen, zoneLayoutKey(layout, zones)];

/// The band labels of the three zones (`BACK · MENU · NEXT`), left to right.
List<String> bandLabels(List<String> zones) => [
      for (final z in zones)
        switch (z) { 'previous' => 'BACK', 'next' => 'NEXT', _ => 'MENU' },
    ];

/// Whether the K01 toast shows: the legacy K01 was a sideways strip (which migrated to SINGLE) and
/// the toast has not been seen on this device.
bool shouldShowK01Toast({required String? legacyDirection, required bool seen}) =>
    !seen && (legacyDirection == 'leftToRight' || legacyDirection == 'rightToLeft');

/// The point a tap lands on a page turn: a `previous` zone turns back, `next` forward.
int? zoneStep(String action) => switch (action) { 'previous' => -1, 'next' => 1, _ => null };

/// Ruler and keys: the layout a hardware key selects, with its direction (`w` strip, `v` single,
/// `r` right-to-left single).
({String layout, String? direction})? layoutForKey(String key) => switch (key) {
      'w' => (layout: 'strip', direction: null),
      'v' => (layout: 'single', direction: 'ltr'),
      'r' => (layout: 'single', direction: 'rtl'),
      _ => null,
    };
