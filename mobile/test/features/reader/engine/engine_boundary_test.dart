import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Import fragments the reader engine must never reach for: the engine is
/// skin-neutral, so no legacy widget, screen, theme, router or skin.
const _banned = [
  '/widgets/',
  '/screens/',
  'app/theme/',
  'app/router/',
  'features/reader/theme/',
  'skins/',
];

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Every banned import in [source], as `line: uri`.
List<String> bannedImports(String source) => [
      for (final match in _import.allMatches(source))
        if (_banned.any(match.group(1)!.contains)) match.group(1)!,
    ];

void main() {
  test('the scan catches a banned import (self-check)', () {
    const source = '''
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_controls.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
''';
    expect(
      bannedImports(source),
      [
        'package:manhwamaniacs/features/reader/widgets/reader_controls.dart',
        'package:manhwamaniacs/app/theme/app_presets.dart',
      ],
    );
  });

  test('nothing under lib/features/reader/engine/ imports legacy UI', () {
    final files = Directory('lib/features/reader/engine')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    final offenders = <String>[
      for (final file in files)
        for (final uri in bannedImports(file.readAsStringSync()))
          '${file.path}: $uri',
    ];
    expect(offenders, isEmpty);
  });
}
