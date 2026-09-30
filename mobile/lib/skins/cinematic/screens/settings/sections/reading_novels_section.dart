import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/recap_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const _faceLabels = {'newsreader': 'Newsreader', 'literata': 'Literata', 'sourceserif': 'Source Serif', 'archivo': 'Archivo', 'atkinson': 'Atkinson'};
const _faceFamily = {'newsreader': 'Newsreader', 'literata': 'Literata', 'sourceserif': 'SourceSerif4', 'archivo': 'Archivo', 'atkinson': 'AtkinsonHyperlegibleNext'};

/// (label, page, ink) of the seven stocks; Issue shows the fallback Nitrate sample.
const _stocks = <String, (String, Color, Color)>{
  'issue': ('Issue', Color(0xFF000000), Color(0xFFD9D6D0)),
  'nitrate': ('Nitrate', Color(0xFF000000), Color(0xFFD9D6D0)),
  'ink': ('Ink', Color(0xFF0B0B0C), Color(0xFFE6E3DD)),
  'sepiaNight': ('Sepia Night', Color(0xFF15110C), Color(0xFFE8D8BE)),
  'dusk': ('Dusk', Color(0xFF0D1117), Color(0xFFD3DAE3)),
  'moss': ('Moss', Color(0xFF0E130F), Color(0xFFD5DECF)),
  'rosewood': ('Rosewood', Color(0xFF160E10), Color(0xFFEBD5D8)),
};

/// Reading: novels (cinematic 8.30.2 row 4, 8.15.5).
class ReadingNovelsSection extends ConsumerWidget {
  const ReadingNovelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final r = ref.watch(novelSettingsProvider);
    final n = ref.read(novelSettingsProvider.notifier);
    final legible = ref.watch(legibleTextProvider);
    final d = readBookDefaults(r, legible: legible);
    const profile = 'Saved for this profile';

    Widget face(String id) {
      final on = d.face == id;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        container: true,
        excludeSemantics: true,
        label: '${_faceLabels[id]}${id == 'atkinson' ? ', designed for low vision' : ''}',
        onTap: () => n.setBookDefaults(d.copyWith(face: id)),
        child: CinePressable(
          key: Key('face-$id'),
          onTap: () => n.setBookDefaults(d.copyWith(face: id)),
          hit: false,
          builder: (context, st) => Container(
            constraints: BoxConstraints(minHeight: cineHitMin(context) > 56 ? cineHitMin(context) : 56),
            padding: EdgeInsets.symmetric(horizontal: c.space3, vertical: c.space2),
            decoration: BoxDecoration(
              border: Border(bottom: c.ruleHair, left: BorderSide(color: on ? c.colorSpot : const Color(0x00000000), width: 2)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(_faceLabels[id]!, style: TextStyle(fontFamily: _faceFamily[id], fontSize: 18, color: on ? c.colorInk100 : c.colorInk80)),
                  if (id == 'atkinson') CineRoleText('Designed for low vision', c.typeCaption, color: c.colorInk60),
                ],),
              ),
            ],),
          ),
        ),
      );
    }

    Widget swatch(String id) {
      final (label, page, ink) = _stocks[id]!;
      final on = r.novelStock == id;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        excludeSemantics: true,
        label: label,
        onTap: () => n.put({'stock': id}),
        child: CinePressable(
          key: Key('stock-$id'),
          onTap: () => n.put({'stock': id}),
          builder: (context, st) => Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: page, border: Border.all(color: on ? c.colorSpot : c.colorRule2, width: on ? 2 : 1)),
            child: Text('Aa', style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, color: ink)),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('EVERY BOOK'),
      SettingsBlock(
        id: 'face',
        label: 'Default face',
        description: 'A book you have not set up yourself opens like this. $profile.',
        child: Column(children: [for (final id in kNovelFaces) face(id)]),
      ),
      stepperRow('size', 'Size', d.fontSize, (v) => n.setBookDefaults(d.copyWith(fontSize: v)), min: 14, max: 40, unit: 'PX'),
      sliderRow('line-spacing', 'Line spacing', d.lineHeight, (v) => n.setBookDefaults(d.copyWith(lineHeight: (v * 20).round() / 20)),
          min: 1.30, max: 2.10, divisions: 16, flag: (v) => v.toStringAsFixed(2),),
      sliderRow('measure', 'Measure', d.measure.toDouble(), (v) => n.setBookDefaults(d.copyWith(measure: v.round())),
          min: 48, max: 88, divisions: 20, flag: (v) => '${v.round()} ch',),
      const SettingsKicker('THE PAGE'),
      segmentedRow('n-layout', 'Layout', const ['SCROLL', 'PAGED'], r.novelLayout == 'scroll' ? 0 : 1, (i) => n.put({'layout': i == 0 ? 'scroll' : 'paged'})),
      segmentedRow('n-page-turn', 'Page turn', const ['CUT', 'SLIDE', 'FADE'], const ['cut', 'slide', 'fade'].indexOf(r.novelPageTurn),
          (i) => n.put({'pageTurn': const ['cut', 'slide', 'fade'][i]}),),
      SettingsBlock(
        id: 'stock',
        label: 'Stock',
        description: 'Issue uses each book\'s own colour.',
        child: Wrap(spacing: c.space2, runSpacing: c.space2, children: [for (final id in _stocks.keys) swatch(id)]),
      ),
      switchRow('bold', 'Bold text', r.novelBold, (v) => n.put({'bold': v}), description: profile),
      switchRow('justify', 'Justify and hyphenate', r.novelJustify, (v) => n.put({'justify': v}), description: profile),
      switchRow('n-auto-next', 'Auto next chapter', r.novelAutoNext, (v) => n.put({'autoNextChapter': v}), description: profile),
      const RecapRows(prefix: 'n'),
    ],);
  }
}
