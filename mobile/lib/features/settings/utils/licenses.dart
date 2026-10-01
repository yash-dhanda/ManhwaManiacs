import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/settings/utils/package_versions.g.dart';

/// The package prefix of the CC0 art and sound entries (glass 12.7, 9.4.2).
const String kArtLicencePrefix = 'art:';

/// Registers one `art:{name}` licence per `assets/licenses/art_and_sounds.json` entry, each followed by the CC0 legal code.
Future<void> registerArtLicences(AssetBundle bundle) async {
  LicenseRegistry.addLicense(() async* {
    final cc0 = await bundle.loadString('assets/licenses/CC0-1.0.txt');
    final list = jsonDecode(await bundle.loadString('assets/licenses/art_and_sounds.json')) as List<dynamic>;
    for (final e in list.cast<Map<String, dynamic>>()) {
      yield LicenseEntryWithLineBreaks(['$kArtLicencePrefix${e['name']}'], '${e['text']}\n\n$cc0');
    }
  });
}

/// The tag capsule of a licence text (glass 8.25.14).
String licenceTag(String text, {String package = ''}) {
  if (package.startsWith(kArtLicencePrefix) || text.contains('CC0 1.0 Universal')) return 'CC0';
  if (text.contains('SIL OPEN FONT LICENSE')) return 'OFL-1.1';
  if (text.contains('Apache License') && text.contains('Version 2.0')) return 'Apache-2.0';
  if (text.contains('Redistribution and use in source and binary forms') && text.contains('Neither the name')) return 'BSD-3-Clause';
  if (text.contains('Permission is hereby granted, free of charge')) return 'MIT';
  return 'Other';
}

/// One row of the sheet.
@immutable
class LicenceItem {
  const LicenceItem({required this.name, required this.version, required this.tag, required this.text});
  final String name, tag, text;
  final String? version;
}

/// Fonts, App packages or Artwork and sounds.
@immutable
class LicenceGroup {
  const LicenceGroup(this.title, this.items);
  final String title;
  final List<LicenceItem> items;
}

/// Merges the paragraphs of every entry per package (a package may register several), then groups and sorts them.
List<LicenceGroup> groupLicences(Iterable<LicenseEntry> entries) {
  final texts = <String, List<String>>{};
  for (final e in entries) {
    final body = e.paragraphs.map((p) => p.text).join('\n');
    for (final pkg in e.packages) {
      texts.putIfAbsent(pkg, () => []).add(body);
    }
  }
  final fonts = <LicenceItem>[], art = <LicenceItem>[], apps = <LicenceItem>[];
  for (final MapEntry(key: pkg, value: parts) in texts.entries) {
    final text = parts.join('\n\n');
    final tag = licenceTag(text, package: pkg);
    if (pkg.startsWith(kArtLicencePrefix)) {
      art.add(LicenceItem(name: pkg.substring(kArtLicencePrefix.length), version: null, tag: 'CC0', text: text));
    } else {
      final item = LicenceItem(name: pkg, version: kPackageVersions[pkg], tag: tag, text: text);
      (tag == 'OFL-1.1' ? fonts : apps).add(item);
    }
  }
  int byName(LicenceItem a, LicenceItem b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return [
    LicenceGroup('Fonts', fonts..sort(byName)),
    LicenceGroup('App packages', apps..sort(byName)),
    LicenceGroup('Artwork and sounds', art..sort(byName)),
  ];
}

/// Every registered licence, grouped (glass 8.25.14).
Future<List<LicenceGroup>> loadLicenceGroups() async => groupLicences(await LicenseRegistry.licenses.toList());

/// Case-insensitive over name and tag; empty groups are dropped.
List<LicenceGroup> filterLicences(List<LicenceGroup> groups, String q) {
  final s = q.trim().toLowerCase();
  return [
    for (final g in groups)
      if (g.items.any((i) => s.isEmpty || i.name.toLowerCase().contains(s) || i.tag.toLowerCase().contains(s)))
        LicenceGroup(g.title, [for (final i in g.items) if (s.isEmpty || i.name.toLowerCase().contains(s) || i.tag.toLowerCase().contains(s)) i]),
  ];
}
