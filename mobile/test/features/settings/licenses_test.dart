import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/utils/licenses.dart';
import 'package:manhwamaniacs/features/settings/utils/package_versions.g.dart';

void main() {
  test('licence tags', () {
    expect(licenceTag('Copyright 2020 ... SIL OPEN FONT LICENSE Version 1.1'), 'OFL-1.1');
    expect(licenceTag('Apache License\nVersion 2.0, January 2004'), 'Apache-2.0');
    expect(licenceTag('Redistribution and use in source and binary forms, with or without ... Neither the name of Google'), 'BSD-3-Clause');
    expect(licenceTag('Permission is hereby granted, free of charge, to any person'), 'MIT');
    expect(licenceTag('Creative Commons Legal Code\n\nCC0 1.0 Universal'), 'CC0');
    expect(licenceTag('anything', package: 'art:Onboarding art'), 'CC0');
    expect(licenceTag('Public domain, do what you want'), 'Other');
  });

  test('entries for one package merge with a blank line; art loses its prefix', () {
    final groups = groupLicences([
      const LicenseEntryWithLineBreaks(['dio'], 'Permission is hereby granted, free of charge, part one'),
      const LicenseEntryWithLineBreaks(['dio'], 'part two'),
      const LicenseEntryWithLineBreaks(['Literata'], 'SIL OPEN FONT LICENSE'),
      const LicenseEntryWithLineBreaks(['art:Onboarding art'], 'Onboarding art © ManhwaManiacs contributors, CC0'),
    ]);
    expect(groups.map((g) => g.title), ['Fonts', 'App packages', 'Artwork and sounds']);
    final dio = groups[1].items.single;
    expect(dio.text, 'Permission is hereby granted, free of charge, part one\n\npart two');
    expect(dio.tag, 'MIT');
    expect(dio.version, kPackageVersions['dio']);
    expect(groups[0].items.single.name, 'Literata');
    expect(groups[2].items.single.name, 'Onboarding art');
    expect(groups[2].items.single.tag, 'CC0');
  });

  test('filter drops empty groups, matches name or tag', () {
    const groups = [
      LicenceGroup('Fonts', [LicenceItem(name: 'Literata', version: null, tag: 'OFL-1.1', text: '')]),
      LicenceGroup('App packages', [LicenceItem(name: 'dio', version: '5', tag: 'MIT', text: '')]),
    ];
    expect(filterLicences(groups, 'DIO').map((g) => g.title), ['App packages']);
    expect(filterLicences(groups, 'ofl').single.items.single.name, 'Literata');
    expect(filterLicences(groups, 'zzz'), isEmpty);
    expect(filterLicences(groups, '').length, 2);
  });

  test('every direct main dependency has a version line', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final direct = RegExp(r'^  ([a-z0-9_]+):\n    dependency: "direct main"', multiLine: true).allMatches(lock).map((m) => m.group(1)!).toList();
    expect(direct, isNotEmpty);
    for (final d in direct) {
      expect(kPackageVersions[d], isNotNull, reason: d);
    }
  });

  test('every art and sound entry is CC0', () {
    final list = jsonDecode(File('assets/licenses/art_and_sounds.json').readAsStringSync()) as List<dynamic>;
    expect(list, isNotEmpty);
    for (final e in list.cast<Map<String, dynamic>>()) {
      expect(e['licence'], 'CC0');
    }
  });
}
