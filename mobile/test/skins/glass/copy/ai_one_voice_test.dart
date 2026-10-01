import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// glass 9.1.5: the AI lines live in `copy/ai.dart` only, and nothing under `skins/glass` (Dart) repeats them.
void main() {
  test('the section 9.1.5 lines appear only in copy/ai.dart', () {
    final root = Directory('lib/skins/glass');
    final lines = ['AI picks are off', "AI picks didn't load", 'AI picks need a connection', "AI isn't set up", "Today's AI asks are used up", "You've used today's AI asks", 'AI is busy, retrying', 'Too many requests in a row', "The AI service didn't answer"];
    final offenders = <String>[];
    for (final f in root.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (f.path.endsWith('copy/ai.dart')) continue;
      final text = f.readAsStringSync();
      for (final l in lines) {
        if (text.contains(l)) offenders.add('${f.path}: $l');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
