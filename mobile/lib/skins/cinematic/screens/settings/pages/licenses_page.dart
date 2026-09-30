import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `TYPE`, `ICONS` or `SOFTWARE` for a package name.
String licenseGroupOf(String package) {
  final p = package.toLowerCase();
  const faces = ['bodoni', 'archivo', 'newsreader', 'plex', 'literata', 'source serif', 'sourceserif', 'atkinson', 'google sans', 'syne', 'dm sans', 'dmsans', 'inter', 'bebas', 'space mono'];
  if (faces.any(p.contains)) return 'TYPE';
  if (p.contains('phosphor') || p.contains('icon')) return 'ICONS';
  return 'SOFTWARE';
}

const List<String> kLicenseGroups = ['TYPE', 'ICONS', 'SOFTWARE', 'DEMO ART'];
const String kDemoArtLine = 'Edition previews use procedural demo covers made for ManhwaManiacs.';

/// Groups `(package, paragraphs)` pairs by [licenseGroupOf], packages sorted.
Map<String, Map<String, List<String>>> groupLicenses(Iterable<(String, List<String>)> entries) {
  final out = {for (final g in kLicenseGroups) g: <String, List<String>>{}};
  for (final (pkg, paras) in entries) {
    out[licenseGroupOf(pkg)]!.putIfAbsent(pkg, () => []).addAll(paras);
  }
  return {
    for (final e in out.entries) e.key: Map.fromEntries(e.value.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))),
  };
}

/// The Cinematic licence list (`/settings/about?licenses=1`), built from `LicenseRegistry`, which
/// already carries the fonts' OFL texts. The Material `LicensePage` is not used.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key, this.preview});

  /// Test and proof hook: entries instead of the registry.
  final List<(String, List<String>)>? preview;

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  Map<String, Map<String, List<String>>>? _groups;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final entries = <(String, List<String>)>[];
    if (widget.preview != null) {
      entries.addAll(widget.preview!);
    } else {
      await for (final e in LicenseRegistry.licenses) {
        final paras = [for (final p in e.paragraphs) p.text];
        for (final pkg in e.packages) {
          entries.add((pkg, paras));
        }
      }
    }
    if (mounted) setState(() => _groups = groupLicenses(entries));
  }

  void _open(String pkg, List<String> paras) {
    unawaited(Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: CineMotion.reduced(context) ? context.cine.durReduced : context.cine.durColumn,
      pageBuilder: (_, __, ___) => LicenseDetailPage(package: pkg, paragraphs: paras),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ),),);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final groups = _groups;
    if (groups == null) return Padding(padding: EdgeInsets.all(c.space4), child: CineRoleText('LOADING', c.typeKicker, color: c.colorInk60));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final g in kLicenseGroups) ...[
        SettingsKicker(g),
        if (g == 'DEMO ART')
          CineRoleText(kDemoArtLine, c.typeCaption, color: c.colorInk60)
        else
          for (final e in groups[g]!.entries)
            Semantics(
              button: true,
              container: true,
              excludeSemantics: true,
              label: e.key,
              onTap: () => _open(e.key, e.value),
              child: CinePressable(
                onTap: () => _open(e.key, e.value),
                hit: false,
                builder: (context, st) => Container(
                  constraints: BoxConstraints(minHeight: cineHitMin(context) > 48 ? cineHitMin(context) : 48),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(border: Border(bottom: c.ruleHair), color: st.pressed ? c.colorPaper3 : null),
                  child: Text(e.key, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: c.colorInk100)),
                ),
              ),
            ),
      ],
    ],);
  }
}

/// One package's licence text, Newsreader 16/24 on `paper.0`.
class LicenseDetailPage extends StatelessWidget {
  const LicenseDetailPage({super.key, required this.package, required this.paragraphs});
  final String package;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Scaffold(
      backgroundColor: c.colorPaper0,
      appBar: AppBar(
        backgroundColor: c.colorPaper0,
        foregroundColor: c.colorInk100,
        title: Text(package, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: c.colorInk100)),
      ),
      body: ListView(
        padding: EdgeInsets.all(c.space4),
        children: [
          for (final p in paragraphs)
            Padding(
              padding: EdgeInsets.only(bottom: c.space3),
              child: Text(p, style: TextStyle(fontFamily: 'Newsreader', fontSize: 16, height: 24 / 16, color: c.colorInk80)),
            ),
        ],
      ),
    );
  }
}
