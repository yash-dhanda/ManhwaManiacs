import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/features/novels/providers/glass_novel_prefs_provider.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_orbs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// What the Aa rows read and write (H).
class NovelTypeContext {
  const NovelTypeContext({
    required this.values,
    required this.prefs,
    required this.pageTinted,
    required this.keepAwake,
    required this.setPageTinted,
    required this.setKeepAwake,
    required this.onPaper,
    required this.onReset,
    this.palette,
    this.phone = true,
  });
  final GlassNovelValues values;
  final GlassNovelPrefs prefs;
  final bool pageTinted, keepAwake;
  final ValueChanged<bool> setPageTinted, setKeepAwake;
  final void Function(GlassPaper paper, Offset orb) onPaper;
  final VoidCallback onReset;
  final CoverPalette? palette;
  final bool phone;
}

/// One row of the Aa sheet.
class NovelTypeRow {
  const NovelTypeRow(this.id, this.build);
  final String id;
  final Widget Function(BuildContext context, NovelTypeContext c) build;
}

/// The Aa rows in order (H1-H9). `mobile/37` and `mobile/44` append theirs to this list (the Soundscape row and the cruise default go
/// into the Ambient group after `pageTinted`).
List<NovelTypeRow> novelTypeRows() => [
      NovelTypeRow('caption-book', (context, c) => const _Caption('This book')),
      NovelTypeRow('faces', (context, c) => _Faces(c)),
      NovelTypeRow('size', (context, c) => _Stepper(
            label: 'Size',
            value: c.values.fontSize.round(),
            min: 15,
            max: 30,
            format: (v) => '$v px',
            larger: 'Larger text',
            smaller: 'Smaller text',
            onChanged: (v) => c.prefs.setBook({GlassNovelKeys.size: v}),
          ),),
      NovelTypeRow('line', (context, c) => _Stepper(
            label: 'Line height',
            value: (c.values.lineHeight * 100).round(),
            min: 140,
            max: 210,
            step: 5,
            format: (v) => (v / 100).toStringAsFixed(2),
            larger: 'More line height',
            smaller: 'Less line height',
            onChanged: (v) => c.prefs.setBook({GlassNovelKeys.line: v / 100}),
          ),),
      NovelTypeRow('measure', (context, c) => _Stepper(
            label: 'Measure',
            value: c.values.measure.round(),
            min: 48,
            max: 88,
            step: 2,
            format: (v) => '$v ch',
            larger: 'Wider column',
            smaller: 'Narrower column',
            onChanged: (v) => c.prefs.setBook({GlassNovelKeys.measure: v}),
          ),),
      NovelTypeRow('paragraph', (context, c) => _Stepper(
            label: 'Paragraph spacing',
            value: (c.values.paragraphSpacing * 10).round(),
            min: 0,
            max: 12,
            format: (v) => '${(v / 10).toStringAsFixed(1)} em',
            larger: 'More paragraph space',
            smaller: 'Less paragraph space',
            onChanged: (v) => c.prefs.setBook({GlassNovelKeys.para: v / 10}),
          ),),
      NovelTypeRow('letter', (context, c) => _Stepper(
            label: 'Character spacing',
            value: (c.values.letterSpacing * 100).round(),
            min: -2,
            max: 10,
            format: (v) => '${v > 0 ? '+' : ''}${(v / 100).toStringAsFixed(2)} em',
            larger: 'Wider letter spacing',
            smaller: 'Tighter letter spacing',
            onChanged: (v) => c.prefs.setBook({GlassNovelKeys.letter: v / 100}),
          ),),
      NovelTypeRow('reset', (context, c) => Align(alignment: Alignment.centerLeft, child: GlassButton(label: 'Reset', onPressed: c.onReset, variant: GlassButtonVariant.plain))),
      NovelTypeRow('caption-all', (context, c) => const _Caption('All books')),
      NovelTypeRow('justify', (context, c) => _Switch('Justify and hyphenate', c.values.justify, (v) => c.prefs.setProfile({GlassNovelKeys.justify: v}))),
      NovelTypeRow('bold', (context, c) => _Switch('Bold text', c.values.bold, (v) => c.prefs.setProfile({GlassNovelKeys.bold: v}))),
      NovelTypeRow('line-guide', (context, c) => _Switch('Line guide', c.values.lineGuide, (v) => c.prefs.setProfile({GlassNovelKeys.lineGuide: v}))),
      NovelTypeRow('mode', (context, c) => _Labelled(
            'Mode',
            GlassSegmented<bool>(
              segments: const [GlassSegment(value: false, label: 'Scroll'), GlassSegment(value: true, label: 'Paged')],
              selected: c.values.paged,
              onSelected: (v) => c.prefs.setProfile({GlassNovelKeys.layout: v ? 'paged' : 'scroll'}),
            ),
          ),),
      NovelTypeRow('page-turn', (context, c) => !c.values.paged
          ? const SizedBox.shrink()
          : _Labelled(
              'Page turn',
              GlassSegmented<GlassPageTurn>(
                segments: [for (final t in GlassPageTurn.values) GlassSegment(value: t, label: t.label)],
                selected: c.values.pageTurn,
                onSelected: (v) => c.prefs.setProfile({GlassNovelKeys.pageTurn: v.wire}),
              ),
            ),),
      NovelTypeRow('taps', (context, c) => !c.values.paged
          ? const SizedBox.shrink()
          : _Labelled(
              'Taps',
              GlassSegmented<GlassTapZones>(
                segments: [for (final t in GlassTapZones.values) GlassSegment(value: t, label: t.label)],
                selected: c.values.tapZones,
                onSelected: (v) => c.prefs.setProfile({GlassNovelKeys.tapZones: v.wire}),
              ),
            ),),
      NovelTypeRow('papers', (context, c) => _Labelled('Paper', NovelPaperOrbs(selected: c.values.paper, onSelected: c.onPaper, palette: c.palette))),
      NovelTypeRow('caption-ambient', (context, c) => const _Caption('Ambient · All books')),
      NovelTypeRow('page-tinted', (context, c) => _Switch('Page-tinted chrome', c.pageTinted, c.setPageTinted)),
      NovelTypeRow('caption-screen', (context, c) => c.phone ? const _Caption('Screen · All books') : const SizedBox.shrink()),
      NovelTypeRow('keep-awake', (context, c) => c.phone ? _Switch('Keep screen awake', c.keepAwake, c.setKeepAwake) : const SizedBox.shrink()),
    ];

/// The rows' body (the sheet's and the desktop panel's Aa tab). Its text is `onGlass`; wells and steppers use `wellOnGlass`.
class NovelTypeBody extends StatelessWidget {
  const NovelTypeBody({super.key, required this.context0, this.rows, this.controller});
  final NovelTypeContext context0;
  final List<NovelTypeRow>? rows;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final all = rows ?? novelTypeRows();
    return GlassHost(
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [for (final r in all) KeyedSubtree(key: ValueKey('type-row-${r.id}'), child: Padding(padding: const EdgeInsets.only(bottom: 10), child: r.build(context, context0)))],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Semantics(header: true, child: GlassText(text, role: gt.typeCaption1, onGlass: true, maxScale: 1.3)),
      );
}

class _Labelled extends StatelessWidget {
  const _Labelled(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GlassText(label, role: gt.typeSubhead, onGlass: true, maxScale: 1.3), const SizedBox(height: 6), child],
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.format, required this.onChanged, required this.larger, required this.smaller, this.step = 1});
  final String label, larger, smaller;
  final int value, min, max, step;
  final String Function(int) format;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: GlassText(label, role: gt.typeBody, onGlass: true, maxScale: 1.3)),
          GlassStepper(value: value, min: min, max: max, step: step, label: label, format: format, onChanged: onChanged, increaseLabel: larger, decreaseLabel: smaller),
        ],
      );
}

class _Switch extends StatelessWidget {
  const _Switch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: GlassFrame.hitMin(context)),
        child: Row(
          children: [
            Expanded(child: GlassText(label, role: gt.typeBody, onGlass: true, maxScale: 1.3)),
            GlassSwitch(value: value, label: label, onChanged: onChanged),
          ],
        ),
      );
}

class _Faces extends StatelessWidget {
  const _Faces(this.c);
  final NovelTypeContext c;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final f in GlassFace.values) ...[
            if (f != GlassFace.literata) const SizedBox(width: 8),
            Expanded(child: _FaceTile(face: f, selected: c.values.face == f, onTap: () => c.prefs.setBook({GlassNovelKeys.face: f.wire}))),
          ],
        ],
      );
}

class _FaceTile extends StatelessWidget {
  const _FaceTile({required this.face, required this.selected, required this.onTap});
  final GlassFace face;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        label: face.label,
        excludeSemantics: true,
        onTap: onTap,
        child: GlassPressable(
          material: GlassMaterial.content,
          shape: const GlassShape.superellipse(14),
          noSemantics: true,
          onTap: onTap,
          builder: (context, info) => Container(
            height: 56,
            decoration: BoxDecoration(
              color: selected ? gt.colorFill2 : gt.colorWellOnGlass,
              borderRadius: BorderRadius.circular(14),
              border: selected ? Border.fromBorderSide(gt.borderSelectedRing) : null,
            ),
            child: Center(
              child: Text(
                face.label,
                textScaler: TextScaler.noScaling,
                style: glassFaceStyle(face, 17, 450).copyWith(fontSize: 17, color: gt.colorOnGlass),
              ),
            ),
          ),
        ),
      );
}
