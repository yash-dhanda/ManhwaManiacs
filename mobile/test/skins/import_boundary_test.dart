import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Import-boundary rules of stack §2.3. Pure so the rules test themselves.
List<String> boundaryViolations(String path, String source) {
  final p = path.replaceAll('\\', '/');
  final imports =
      RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();
  final out = <String>[];
  final inCine = p.contains('lib/skins/cinematic/');
  final inGlass = p.contains('lib/skins/glass/');
  final inSkins = p.contains('lib/skins/') && !p.contains('lib/skins/legacy/');
  final bootFile = RegExp(
          r'lib/app/(app_restart|skin_app|skin_boot|skin_boot_check|switch_skin)\.dart$',)
      .hasMatch(p);
  for (final i in imports) {
    if (inCine || inGlass) {
      for (final banned in const [
        '/screens/',
        '/widgets/',
        'app/theme/',
        'app/router/',
        'app/app.dart',
        'skins/legacy/',
      ]) {
        // A skin's own screens/ and widgets/ folders are its own code.
        final own = (inCine && i.contains('skins/cinematic/')) ||
            (inGlass && i.contains('skins/glass/'));
        // Third-party packages have their own widgets/ folders; the ban is about the app's features.
        final external = i.startsWith('package:') && !i.startsWith('package:manhwamaniacs/');
        if (!own && !external && i.contains(banned)) {
          out.add('$p imports $i (banned: $banned)');
        }
      }
      if (inCine && i.contains('skins/glass/')) {
        out.add('$p imports $i (other skin)');
      }
      if (inGlass && i.contains('skins/cinematic/')) {
        out.add('$p imports $i (other skin)');
      }
    }
    if ((inSkins || bootFile) && i.contains('app/router/routes.dart')) {
      out.add('$p imports $i (build paths from contract.g.dart)');
    }
  }
  return out;
}

void main() {
  const cine = 'lib/skins/cinematic/x.dart';
  test('boundary rules self-check', () {
    expect(boundaryViolations(cine, "import 'package:flutter/material.dart';"),
        isEmpty,);
    for (final bad in [
      'package:manhwamaniacs/features/a/screens/b.dart',
      'package:manhwamaniacs/features/a/widgets/b.dart',
      'package:manhwamaniacs/app/theme/app_theme.dart',
      'package:manhwamaniacs/app/router/app_router.dart',
      'package:manhwamaniacs/app/app.dart',
      'package:manhwamaniacs/skins/legacy/legacy_skin.dart',
      'package:manhwamaniacs/skins/glass/router.dart',
      'package:manhwamaniacs/app/router/routes.dart',
    ]) {
      expect(boundaryViolations(cine, "import '$bad';"), isNotEmpty,
          reason: bad,);
    }
    expect(
        boundaryViolations('lib/skins/glass/x.dart',
            "import 'package:manhwamaniacs/skins/cinematic/router.dart';",),
        isNotEmpty,);
    expect(
        boundaryViolations('lib/app/switch_skin.dart',
            "import 'package:manhwamaniacs/app/router/routes.dart';",),
        isNotEmpty,);
    expect(
        boundaryViolations('lib/skins/legacy/x.dart',
            "import 'package:manhwamaniacs/app/router/app_router.dart';",),
        isEmpty,);
  });

  test('no file under lib breaks the boundaries', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final violations = [
      for (final f in files) ...boundaryViolations(f.path, f.readAsStringSync()),
    ];
    expect(violations, isEmpty);
  });

  test('no file under lib imports package:phosphor_flutter', () {
    final hits = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
        if (f.readAsStringSync().contains('package:phosphor_flutter')) f.path,
    ];
    expect(hits, isEmpty);
  });
}
