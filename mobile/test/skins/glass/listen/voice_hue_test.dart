import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_hue.dart';

void main() {
  double contrastOnBlack(Color c) => (relativeLuminance(c) + 0.05) / 0.05;

  test('every pitch holds at least 9:1 against black', () {
    for (final hz in [80.0, 190.0, 300.0, 40.0, 500.0]) {
      expect(contrastOnBlack(voiceHue(hz)), greaterThanOrEqualTo(9), reason: '$hz Hz');
    }
  });

  test('deep voices are blue-violet and bright voices warm', () {
    final deep = oklchFromColor(voiceHue(80)), bright = oklchFromColor(voiceHue(300));
    expect(deep.h, closeTo(250, 6));
    expect(bright.h, closeTo(40, 6));
    expect(deep.l, closeTo(0.80, 0.01));
  });

  test('pitch is clamped to 80-300 Hz', () {
    expect(voiceHue(10), voiceHue(80));
    expect(voiceHue(900), voiceHue(300));
  });

  test('the web twin\'s hexes match when its test exists', () {
    final f = File('../frontend/src/skins/glass/listen/voice-hue.test.ts');
    if (!f.existsSync()) return;
    final hexes = RegExp(r'#[0-9a-fA-F]{6}').allMatches(f.readAsStringSync()).map((m) => m.group(0)!.toUpperCase()).toList();
    String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    for (final hz in [80.0, 190.0, 300.0]) {
      expect(hexes, contains(hex(voiceHue(hz))));
    }
  });
}
