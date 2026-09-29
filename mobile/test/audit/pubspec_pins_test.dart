import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// mobile/03 adds liquid_glass_widgets here.
const pins = {
  'haptic_feedback': '0.6.5',
  'gaimon': '1.5.0',
  'flutter_soloud': '4.1.7',
  'share_plus': '12.0.2',
  'audio_service': '0.18.19',
  'sensors_plus': '7.1.0',
  'flutter_dynamic_icon_plus': '1.4.1',
  'flutter_animate': '4.5.2',
  'swipeable_page_route': '0.4.8',
  'custom_refresh_indicator': '4.0.2',
  'flutter_reorderable_grid_view': '5.7.0',
};
const absent = ['phosphor_flutter', 'dependency_overrides', 'liquid_glass_widgets'];

void main() {
  final spec = File('pubspec.yaml').readAsStringSync();
  test('redesign packages are pinned exactly', () {
    for (final e in pins.entries) {
      expect(RegExp('^  ${e.key}: ${RegExp.escape(e.value)}\$', multiLine: true).hasMatch(spec), isTrue,
          reason: e.key);
    }
  });

  test('forbidden entries are absent', () {
    final live = spec.split('\n').where((l) => !l.trimLeft().startsWith('#')).join('\n');
    for (final a in absent) {
      expect(live, isNot(contains(a)), reason: a);
    }
  });
}
