import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/font_licenses.dart';

/// family -> asset paths, read from pubspec.yaml's `fonts:` block.
Map<String, List<String>> declaredFonts() {
  final out = <String, List<String>>{};
  String? family;
  var inFonts = false;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    if (RegExp(r'^  fonts:').hasMatch(line)) inFonts = true;
    if (!inFonts) continue;
    final f = RegExp(r'^    - family: (\w+)').firstMatch(line);
    if (f != null) {
      family = f.group(1);
      out[family!] = [];
    }
    final a = RegExp(r'^\s+- asset: (\S+)').firstMatch(line);
    if (a != null && family != null) out[family]!.add(a.group(1)!);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final declared = declaredFonts();

  test('every declared family has files that exist', () {
    expect(declared, isNotEmpty);
    for (final e in declared.entries) {
      expect(e.value, isNotEmpty, reason: e.key);
      for (final path in e.value) {
        expect(File(path).existsSync(), isTrue, reason: '${e.key}: $path');
      }
    }
  });

  test('the redesign families are declared', () {
    for (final f in const [
      'BodoniModa', 'Archivo', 'Newsreader', 'IBMPlexMono', 'Literata', 'LiterataMM', 'SourceSerif4',
      'AtkinsonHyperlegibleNext', 'GoogleSansFlexMM', 'GoogleSansCodeMM', 'CineGlyphs', 'GlassGlyphs',
      'PhosphorRegular', 'PhosphorThin', 'PhosphorLight', 'PhosphorBold', 'PhosphorFill', 'PhosphorDuotone',
    ]) {
      expect(declared, contains(f));
    }
  });

  test('every family the generated token and icon files name is declared', () {
    final used = <String>{};
    final files = [
      ...Directory('lib/skins').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.g.dart')),
    ];
    for (final f in files) {
      for (final m in RegExp(r"(?:family|fontFamily): '(\w+)'").allMatches(f.readAsStringSync())) {
        used.add(m.group(1)!);
      }
    }
    expect(used, isNotEmpty);
    for (final u in used) {
      expect(declared, contains(u), reason: u);
    }
  });

  test('loadAppFonts covers every declared family', () {
    final src = File('test/screenshots/support/shot_harness.dart').readAsStringSync();
    for (final f in declared.keys) {
      expect(src, contains("'$f':"), reason: f);
    }
  });

  test('the licence assets exist and are registered under the ten package names', () async {
    for (final path in kFontLicenseAssets.values) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    registerFontLicenses();
    final names = <String>{};
    await for (final l in LicenseRegistry.licenses) {
      names.addAll(l.packages);
    }
    expect(
      names,
      containsAll(const [
        'Bodoni Moda', 'Archivo', 'Newsreader', 'IBM Plex Mono', 'Literata', 'Source Serif 4',
        'Atkinson Hyperlegible Next', 'Google Sans Flex', 'Google Sans Code', 'Phosphor Icons',
      ]),
    );
  });
}
