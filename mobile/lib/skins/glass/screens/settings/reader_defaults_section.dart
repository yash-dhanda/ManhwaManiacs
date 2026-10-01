import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_settings_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Direction control of the manga group: Vertical is the strip layout, the other two open Single paged in that direction (glass 8.14.1).
enum MangaDirection { ltr, rtl, vertical }

MangaDirection mangaDirectionOf(SeriesDefaults d) => d.layout == 'strip' ? MangaDirection.vertical : (d.direction == 'rtl' ? MangaDirection.rtl : MangaDirection.ltr);

SeriesDefaults applyMangaDirection(SeriesDefaults d, MangaDirection m) => switch (m) {
      MangaDirection.vertical => d.copyWith(layout: 'strip'),
      MangaDirection.ltr => d.copyWith(layout: d.layout == 'strip' ? 'single' : d.layout, direction: 'ltr'),
      MangaDirection.rtl => d.copyWith(layout: d.layout == 'strip' ? 'single' : d.layout, direction: 'rtl'),
    };

/// The steps of the Listen speed slider (0.5 to 3.0 in 0.05) and its magnet at 1.0x within 0.08.
double snapListenSpeed(double v) {
  final s = ((v.clamp(0.5, 3.0)) * 20).round() / 20;
  return (s - 1.0).abs() <= 0.08 ? 1.0 : s;
}

const List<(String, String)> kSleepChoices = [
  ('off', 'Off'),
  ('5', '5 min'),
  ('10', '10 min'),
  ('15', '15 min'),
  ('30', '30 min'),
  ('45', '45 min'),
  ('60', '60 min'),
  ('chapter', 'End of chapter'),
  ('nextChapter', 'End of next chapter'),
];

const List<(String, String, Color)> kNovelPapers = [
  ('paper', 'Paper', Color(0xFFF4EFE6)),
  ('sepia', 'Sepia', Color(0xFFE8D8B8)),
  ('parchment', 'Parchment', Color(0xFFD9C7A0)),
  ('grey', 'Grey', Color(0xFF8A8A8F)),
  ('slate', 'Slate', Color(0xFF2B2F3A)),
  ('ink', 'Ink', Color(0xFF14161C)),
  ('black', 'Black', Color(0xFF000000)),
];

/// Settings -> Reader (glass 8.25.3): Manga, Novels, Listen and Ambient defaults on one page. Each row writes the profile default
/// in the store that owns it; old keys are read, never rewritten.
class ReaderDefaultsSection extends ConsumerWidget {
  const ReaderDefaultsSection({super.key, this.platform});
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProfileGate(
        builder: (context) => Column(children: [
          _MangaGroup(platform: platform ?? defaultTargetPlatform),
          const _NovelsGroup(),
          const _ListenGroup(platform: null),
          const _AmbientGroup(),
        ],),
      );
}

class _MangaGroup extends ConsumerWidget {
  const _MangaGroup({required this.platform});
  final TargetPlatform platform;

  static const _scope = 'All series';

  Future<void> _reset(WidgetRef ref) async {
    await ref.read(readerSettingsProvider.notifier).reset();
    final d = ref.read(readerDefaultsProvider.notifier);
    await d.setLockControls(false);
    await d.setVolumeKeyNavigation(false);
    await d.setRefreshRate(ReaderRefreshRate.auto);
    await d.setTapZones(null);
    settingsToast(ref, 'Reader settings reset');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(readerSettingsProvider);
    final n = ref.read(readerSettingsProvider.notifier);
    final dev = ref.watch(readerDefaultsProvider);
    final devN = ref.read(readerDefaultsProvider.notifier);
    final apps = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final android = platform == TargetPlatform.android;
    final sd = r.seriesDefaults;
    final zones = ReaderPrefs.resolve(r, null).tapZones;
    // The reader resolves the profile key first and falls back to the device K07 (GlassReaderValueSet).
    final lock = r.glass.data.containsKey(GlassReaderKeys.lockControls) ? r.glass.boolOf(GlassReaderKeys.lockControls, false) : dev.lockControls;
    String pct(double v) => '${(v * 100).round()}%';
    Future<void> glass(Map<String, dynamic> f) => n.put(glassPatch(r, f));
    return SettingsGroup(id: 'reading-manga', header: 'Manga', footer: _scope, children: [
      SettingsSegmentedBlock<MangaDirection>(
        id: 'reader-direction',
        title: 'Direction',
        segments: const [GlassSegment(value: MangaDirection.ltr, label: 'Left to right'), GlassSegment(value: MangaDirection.rtl, label: 'Right to left'), GlassSegment(value: MangaDirection.vertical, label: 'Vertical')],
        selected: mangaDirectionOf(sd),
        onSelected: (m) => unawaited(n.setSeriesDefaults(applyMangaDirection(sd, m))),
      ),
      SettingsSliderBlock(id: 'reader-brightness', title: 'Brightness default', value: r.glassBrightness, min: 0.2, divisions: 16, format: pct, onChanged: (v) => unawaited(glass({GlassReaderKeys.brightness: (v * 20).round() / 20}))),
      SettingsSliderBlock(id: 'reader-warmth', title: 'Warmth default', value: r.glassWarmth, divisions: 20, format: pct, onChanged: (v) => unawaited(glass({GlassReaderKeys.warmth: (v * 20).round() / 20}))),
      SettingsSegmentedBlock<String>(
        id: 'reader-fit',
        title: 'Fit',
        segments: const [GlassSegment(value: 'width', label: 'Width'), GlassSegment(value: 'height', label: 'Height'), GlassSegment(value: 'original', label: 'Original')],
        selected: sd.fit,
        onSelected: (v) => unawaited(n.setSeriesDefaults(sd.copyWith(fit: v))),
      ),
      SettingsBlock(
        id: 'reader-tap-zones',
        title: 'Tap zones',
        caption: 'Tap a band to cycle Previous, Menu, Next. Double-tap Menu to show the controls.',
        // The profile tapZone.* keys the Glass reader resolves (ReaderPrefs), shown with the reader sheet's own diagram.
        child: TapZonesDiagram(
          zones: zones ?? (sd.direction == 'rtl' ? const ['next', 'menu', 'previous'] : const ['previous', 'menu', 'next']),
          custom: zones != null,
          onChanged: (z) => unawaited(n.put(z == null
              ? {'tapZone.left': null, 'tapZone.center': null, 'tapZone.right': null}
              : {'tapZone.left': z[0], 'tapZone.center': z[1], 'tapZone.right': z[2]},),),
        ),
      ),
      SettingsSegmentedBlock<String>(
        id: 'reader-chapters',
        title: 'Chapters',
        segments: const [GlassSegment(value: 'continuous', label: 'Continuous'), GlassSegment(value: 'single', label: 'One at a time')],
        selected: r.glass.stringOf('chapters', 'continuous'),
        onSelected: (v) => unawaited(glass({'chapters': v})),
      ),
      SettingsSwitchRow(id: 'reader-page-gap', title: 'Page gap', value: r.gap, onChanged: (v) => unawaited(n.put({'gap': v}))),
      SettingsSwitchRow(id: 'reader-cinema', title: 'Cinema mode by default', value: r.cinema, onChanged: (v) => unawaited(n.put({'cinema': v}))),
      if (apps) SettingsSwitchRow(id: 'reader-keep-awake', title: 'Keep screen awake', value: r.glassKeepAwake, onChanged: (v) => unawaited(glass({GlassReaderKeys.keepAwake: v}))),
      SettingsSwitchRow(id: 'reader-auto-next', title: 'Auto next chapter', value: r.autoNextChapter, onChanged: (v) => unawaited(n.put({'autoNextChapter': v}))),
      SettingsSwitchRow(id: 'reader-lock', title: 'Lock reader controls', caption: 'Tap the centre 5 times to unlock', value: lock, onChanged: (v) => unawaited(glass({GlassReaderKeys.lockControls: v}))),
      if (android) SettingsSwitchRow(id: 'reader-volume-keys', title: 'Volume keys turn pages', value: dev.volumeKeyNavigation, onChanged: (v) => unawaited(devN.setVolumeKeyNavigation(v))),
      if (android)
        SettingsBlock(
          id: 'reader-refresh-rate',
          title: 'Refresh rate',
          caption: 'Auto uses the highest rate your screen supports',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final rate in ReaderRefreshRate.values)
              GlassChip(label: rate == ReaderRefreshRate.auto ? 'Auto' : '${rate.targetHz!.round()}', inChoiceGroup: true, selected: dev.refreshRate == rate, onPressed: () => unawaited(devN.setRefreshRate(rate))),
          ],),
        ),
      SettingsAnchor(
        id: 'reader-reset',
        child: Padding(padding: const EdgeInsets.all(16), child: HoldToConfirm(label: 'Reset reader settings', fallbackLabel: 'Reset', onConfirm: () => unawaited(_reset(ref)))),
      ),
    ],);
  }
}

class _NovelsGroup extends ConsumerWidget {
  const _NovelsGroup();

  static const _faces = [('newsreader', 'Newsreader'), ('literata', 'Literata'), ('atkinson', 'Atkinson')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(novelSettingsProvider);
    final n = ref.read(novelSettingsProvider.notifier);
    final g = r.child('glass');
    Future<void> putGlass(Map<String, dynamic> f) => n.put({'glass': {...g.data, ...f}});
    final face = r.choice('face', kNovelFaces, 'newsreader');
    final paper = g.stringOf('paper', 'paper');
    return SettingsGroup(id: 'reading-novels', header: 'Novels', footer: 'Books and series without their own setting', children: [
      SettingsBlock(
        id: 'novel-face',
        title: 'Reading face',
        child: Row(children: [
          for (final f in _faces)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: face == f.$1,
                button: true,
                label: f.$2,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(n.put({'face': f.$1})),
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(12), border: face == f.$1 ? Border.all(color: gt.colorIris500, width: 2) : null),
                    child: Text('Aa', style: TextStyle(fontFamily: f.$1 == 'atkinson' ? 'AtkinsonHyperlegibleNext' : f.$2, fontSize: 22, color: gt.colorLabel1)),
                  ),
                ),
              ),
            ),
        ],),
      ),
      SettingsBlock(id: 'novel-size', title: 'Text size', child: GlassStepper(label: 'Text size', value: r.intOf('fontSize', 18).clamp(15, 30), min: 15, max: 30, onChanged: (v) => unawaited(n.put({'fontSize': v})))),
      SettingsSliderBlock(id: 'novel-line-height', title: 'Line height', value: r.doubleOf('lineHeight', 1.6).clamp(1.4, 2.1), min: 1.4, max: 2.1, divisions: 14, format: (v) => v.toStringAsFixed(2), onChanged: (v) => unawaited(n.put({'lineHeight': (v * 20).round() / 20}))),
      SettingsSliderBlock(id: 'novel-measure', title: 'Measure', value: r.intOf('measure', 66).clamp(48, 88).toDouble(), min: 48, max: 88, divisions: 40, format: (v) => '${v.round()} ch', onChanged: (v) => unawaited(n.put({'measure': v.round()}))),
      SettingsBlock(
        id: 'novel-paper',
        title: 'Paper',
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          for (final p in kNovelPapers)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: paper == p.$1,
              button: true,
              label: p.$2,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(putGlass({'paper': p.$1})),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.$3, border: Border.all(color: paper == p.$1 ? gt.colorIris500 : gt.colorFill3, width: paper == p.$1 ? 3 : 1)),
                ),
              ),
            ),
        ],),
      ),
      SettingsSegmentedBlock<String>(
        id: 'novel-mode',
        title: 'Scroll or paged',
        segments: const [GlassSegment(value: 'scroll', label: 'Scroll'), GlassSegment(value: 'paged', label: 'Paged')],
        selected: r.novelLayout,
        onSelected: (v) => unawaited(n.put({'layout': v})),
      ),
      SettingsSegmentedBlock<String>(
        id: 'novel-page-turn',
        title: 'Page turn',
        segments: const [GlassSegment(value: 'slide', label: 'Slide'), GlassSegment(value: 'lift', label: 'Lift'), GlassSegment(value: 'fade', label: 'Fade')],
        selected: g.choice('pageTurn', const ['slide', 'lift', 'fade'], 'slide'),
        onSelected: (v) => unawaited(putGlass({'pageTurn': v})),
      ),
    ],);
  }
}

class _ListenGroup extends ConsumerWidget {
  const _ListenGroup({required this.platform});
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(listenSettingsProvider);
    final n = ref.read(listenSettingsProvider.notifier);
    final p = platform ?? defaultTargetPlatform;
    final apps = p == TargetPlatform.android || p == TargetPlatform.iOS;
    return SettingsGroup(id: 'listen', header: 'Listen', footer: 'Books and series without their own setting', children: [
      SettingsSliderBlock(id: 'listen-speed', title: 'Default speed', value: r.speed, min: 0.5, max: 3.0, divisions: 50, format: (v) => '${v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}×', onChanged: (v) => unawaited(n.put({'speed': snapListenSpeed(v)}))),
      SettingsSwitchRow(id: 'listen-continue', title: 'Continue to the next chapter', value: r.autoPlayNext, onChanged: (v) => unawaited(n.put({'autoPlayNext': v}))),
      SettingsBlock(
        id: 'listen-sleep',
        title: 'Sleep timer default',
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in kSleepChoices) GlassChip(label: s.$2, inChoiceGroup: true, selected: r.sleepDefault == s.$1, onPressed: () => unawaited(n.put({'sleepDefault': s.$1}))),
        ],),
      ),
      if (apps) SettingsSwitchRow(id: 'listen-shake', title: 'Shake to extend', caption: 'Works while ManhwaManiacs is open.', value: r.shakeToExtend, onChanged: (v) => unawaited(n.put({'shakeToExtend': v}))),
    ],);
  }
}

class _AmbientGroup extends ConsumerWidget {
  const _AmbientGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(readerSettingsProvider);
    final n = ref.read(readerSettingsProvider.notifier);
    return SettingsGroup(id: 'ambient', header: 'Ambient', footer: 'Books and series without their own setting', children: [
      SettingsSwitchRow(id: 'ambient-page-tint', title: 'Page-tinted chrome', value: r.glassPageTinted, onChanged: (v) => unawaited(n.put(glassPatch(r, {GlassReaderKeys.pageTinted: v})))),
      SettingsSliderBlock(
        id: 'ambient-cruise',
        title: 'Cruise default speed',
        value: cruiseToTrack(r.glassCruiseDefault),
        divisions: 100,
        format: (_) => '${r.glassCruiseDefault.toStringAsFixed(2)}×',
        onChanged: (t) => unawaited(n.put(glassPatch(r, {GlassReaderKeys.cruiseDefault: _magnet(trackToCruise(t))}))),
      ),
      SettingsSwitchRow(id: 'ambient-guided', title: 'Guided view by default', caption: 'For chapters with panels', value: r.glassGuidedDefault, onChanged: (v) => unawaited(n.put(glassPatch(r, {GlassReaderKeys.guidedDefault: v})))),
      SettingsRow(id: 'ambient-soundscape', title: 'Soundscape defaults', caret: true, onTap: () => GoRouter.of(context).go('/settings/feedback?row=soundscape')),
    ],);
  }

  static double _magnet(double v) => (v - 1.0).abs() <= 0.08 ? 1.0 : v;
}
