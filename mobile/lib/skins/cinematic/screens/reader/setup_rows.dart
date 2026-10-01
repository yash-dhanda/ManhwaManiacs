import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/menu_open.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/auto_scroll_speed.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/speed_ruler.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_picker.dart';

/// Where a control is saved, as the caption under it (cinematic 8.14.8).
abstract final class SavedScope {
  static const series = 'Saved for this series';
  static const profile = 'Saved for this profile';
  static const device = 'Saved on this device';
  static const session = 'For this reading only';
}

/// What a row of Reading setup reads and writes.
class SetupCtx {
  const SetupCtx({
    required this.context,
    required this.ref,
    required this.seriesRef,
    required this.prefs,
    required this.engine,
    required this.readAll,
    required this.onShowZones,
  });

  final BuildContext context;
  final WidgetRef ref;
  final String seriesRef;
  final ReaderPrefs prefs;
  final ReaderEngine engine;
  final bool readAll;
  final VoidCallback onShowZones;

  bool get paged => !readAll && (prefs.layout == 'single' || prefs.layout == 'double');
  bool get guided => !readAll && prefs.layout == 'guided';
  bool get android => Theme.of(context).platform == TargetPlatform.android;
  bool get tablet => MediaQuery.sizeOf(context).width >= 600;
  ReaderSettingsNotifier get profile => ref.read(readerSettingsProvider.notifier);
  ReaderSeriesPrefsNotifier get series => ref.read(readerSeriesPrefsProvider.notifier);
  ReaderDefaultsController get device => ref.read(readerDefaultsProvider.notifier);
  ReaderDefaults get deviceValues => ref.watch(readerDefaultsProvider);

  String caption(String scope, [String? lead]) => lead == null ? scope : '$lead $scope.';
}

typedef SetupRow = Widget Function(SetupCtx c);

/// One tab: its folio, label and ordered rows. `mobile/23` appends its AMBIENT rows to [kSetupTabs]'s
/// `ambient` list; nothing else changes.
class SetupTab {
  const SetupTab(this.folio, this.label, this.rows);
  final String folio, label;
  final List<SetupRow> rows;
}

const _layouts = ['strip', 'single', 'double', 'guided'];
const _directions = ['ltr', 'rtl'];
const _fits = ['width', 'height', 'original'];
const _zoneValues = ['previous', 'menu', 'next'];
const _zoneLabels = ['PREVIOUS', 'MENU', 'NEXT'];
const _margins = [0, 5, 10, 15, 20, 25];

final List<SetupRow> layoutRows = [
  (c) => c.readAll
      ? const SizedBox.shrink()
      : segmentedRow('setup-layout', 'Layout', const ['STRIP', 'SINGLE', 'DOUBLE', 'GUIDED'], _layouts.contains(c.prefs.layout) ? _layouts.indexOf(c.prefs.layout) : 0,
          (i) => unawaited(c.series.setFor(c.seriesRef, {'layout': _layouts[i]})),
          description: SavedScope.series,),
  (c) => segmentedRow('setup-direction', 'Direction', const ['LEFT TO RIGHT', 'RIGHT TO LEFT'], _directions.indexOf(c.prefs.direction),
      (i) => unawaited(c.series.setFor(c.seriesRef, {'direction': _directions[i]})),
      description: 'Left to right: webtoons and western comics. Right to left: manga. ${SavedScope.series}.',),
  (c) => segmentedRow('setup-fit', 'Fit', const ['WIDTH', 'HEIGHT', 'ORIGINAL'], _fits.indexOf(c.prefs.fit),
      (i) => unawaited(c.series.setFor(c.seriesRef, {'fit': _fits[i]})),
      description: SavedScope.series,
      disabledReasons: c.paged
          ? const {}
          : const {1: 'Fit to height works in the paged layouts.', 2: 'Original size works in the paged layouts.'},),
  (c) => c.tablet
      ? const SizedBox.shrink()
      : slugRow('setup-side-margin', 'Side margin', [for (final m in _margins) CineSlug('$m', '$m %')], '${c.prefs.sideMarginPct}',
          (id) => unawaited(c.profile.put({'sideMargin': int.parse(id)})),
          description: SavedScope.profile,),
  (c) {
    if (!c.tablet) return const SizedBox.shrink();
    final sp = c.ref.watch(sharedPrefsProvider);
    c.ref.watch(stripWidthProvider);
    final v = (sp.getInt('mm.reader.device.stripWidthPx') ?? 720).clamp(480, 860);
    return sliderRow('setup-strip-width', 'Strip width', v.toDouble(), (x) => unawaited(c.ref.read(stripWidthProvider.notifier).set((x / 20).round() * 20)),
        min: 480, max: 860, divisions: 19, flag: (x) => '${x.round()} PX', description: SavedScope.device,);
  },
  (c) => stepperRow('setup-zoom', 'Zoom', (c.prefs.zoom * 100).round(), (v) {
        unawaited(c.series.setFor(c.seriesRef, {'zoom': v}));
        if (!c.paged) c.ref.read(readerUiProvider.notifier).setZoom(v / 100);
      }, min: 50, max: 300, step: 10, unit: '%', description: SavedScope.series,),
  (c) => quietAction('Reset zoom', (c.prefs.zoom * 100).round() == 100
      ? null
      : () {
          unawaited(c.series.setFor(c.seriesRef, {'zoom': 100}));
          if (!c.paged) c.ref.read(readerUiProvider.notifier).setZoom(1);
        },),
  (c) => switchRow('setup-gap', 'Gap between pages', c.prefs.gap, (v) => c.profile.put({'gap': v}),
      description: c.paged ? 'The strip only. ${SavedScope.profile}.' : SavedScope.profile, disabled: c.paged,),
  (c) => segmentedRow('setup-page-turn', 'Page turn', const ['CUT', 'SLIDE', 'FADE'], const ['cut', 'slide', 'fade'].indexOf(c.prefs.pageTurn),
      (i) => unawaited(c.profile.put({'pageTurn': const ['cut', 'slide', 'fade'][i]})),
      description: c.paged ? SavedScope.profile : 'The paged layouts only. ${SavedScope.profile}.', disabled: !c.paged,),
];

final List<SetupRow> imageRows = [
  (c) => sliderRow('setup-brightness', 'Brightness', c.prefs.brightness.toDouble(), (v) => unawaited(c.profile.put({'brightness': v.round()})),
      min: -75, max: 0, divisions: 75, flag: (v) => v.round() < 0 ? 'NIGHT −${-v.round()}' : '0',
      description: "Dims below your screen's lowest setting. ${SavedScope.profile}.",),
  (c) => sliderRow('setup-warmth', 'Warmth', c.prefs.warmthPct.toDouble(), (v) => unawaited(c.profile.put({'warmth': v.round()})),
      min: 0, max: 100, divisions: 100, flag: (v) => '${v.round()}', description: SavedScope.profile,),
  (c) => segmentedRow('setup-colour', 'Colour', const ['NORMAL', 'SEPIA', 'GREY'], const ['normal', 'sepia', 'grey'].indexOf(c.prefs.colour),
      (i) => unawaited(c.profile.put({'colour': const ['normal', 'sepia', 'grey'][i]})), description: SavedScope.profile,),
  (c) => segmentedRow('setup-ground', 'Ground', const ['BLACK', 'INK', 'SLATE'], const ['black', 'ink', 'slate'].indexOf(c.prefs.ground),
      (i) => unawaited(c.profile.put({'ground': const ['black', 'ink', 'slate'][i]})), description: SavedScope.profile,),
];

Widget _zoneRow(SetupCtx c, int i, String label) {
  final zones = resolveZones(c.prefs.tapZones, rtl: c.prefs.rtl);
  return segmentedRow('setup-zone-$i', label, _zoneLabels, _zoneValues.indexOf(zones[i]), (v) {
    final next = [...zones]..[i] = _zoneValues[v];
    unawaited(c.profile.put({'tapZone.left': next[0], 'tapZone.center': next[1], 'tapZone.right': next[2]}));
  },);
}

final List<SetupRow> controlsRows = [
  (c) => menuOpenRow(c.ref, 'setup-menu-open'),
  (c) => menuAtEndRow(c.ref, 'setup-menu-end'),
  (c) => SettingsCaption('Tap zones: what each side of the page does. ${MenuOpen.of(c.ref.watch(readerSettingsProvider)).help} Saved for this profile.'),
  (c) => _zoneRow(c, 0, 'LEFT'),
  (c) => _zoneRow(c, 1, 'CENTRE'),
  (c) => _zoneRow(c, 2, 'RIGHT'),
  (c) => Row(children: [
        quietAction('Reset', () => unawaited(c.profile.put({'tapZone.left': null, 'tapZone.center': null, 'tapZone.right': null}))),
        const SizedBox(width: 8),
        quietAction('Show zones', c.onShowZones),
      ],),
  (c) => segmentedRow('setup-strip-taps', 'Strip taps', const ['MENU', 'TAP TO SCROLL'], c.prefs.stripTaps == 'menu' ? 0 : 1,
      (i) => unawaited(c.profile.put({'stripTaps': i == 0 ? 'menu' : 'scroll'})), description: SavedScope.profile,),
  (c) => switchRow('setup-swipe', 'Swipe sideways to change chapter', c.prefs.swipeChapter, (v) => c.profile.put({'swipeSideways': v}), description: SavedScope.profile),
  (c) => switchRow('setup-cinema', 'Cinema mode', c.prefs.cinema, (v) => c.profile.put({'cinema': v}), description: SavedScope.profile),
  (c) => switchRow('setup-keep-awake', 'Keep screen awake', c.deviceValues.keepScreenAwake, c.device.setKeepScreenAwake, description: SavedScope.device),
  (c) => switchRow('setup-auto-next', 'Auto next chapter', c.prefs.autoNextChapter, (v) async {
        await c.profile.put({'autoNextChapter': v});
        await c.device.setAutoNextChapter(v);
      }, description: SavedScope.profile,),
  (c) => switchRow('setup-lock', 'Lock controls', c.deviceValues.lockControls, c.device.setLockControls,
      description: 'The reader opens locked. ${SavedScope.device}.',),
  (c) => c.android
      ? switchRow('setup-volume', 'Volume keys turn pages', c.deviceValues.volumeKeyNavigation, c.device.setVolumeKeyNavigation, description: SavedScope.device)
      : const SizedBox.shrink(),
  (c) => c.android
      ? segmentedRow('setup-refresh', 'Refresh rate', const ['AUTO', '30', '60', '90', '120'], c.deviceValues.refreshRate.index,
          (i) => unawaited(c.device.setRefreshRate(ReaderRefreshRate.values[i])), description: SavedScope.device,)
      : const SizedBox.shrink(),
];

final List<SetupRow> ambientRows = [
  (c) => ValueListenableBuilder(
        valueListenable: c.engine,
        builder: (context, s, _) => JumpRow(
          id: 'setup-autoscroll',
          child: CineSettingsRow(
            label: 'Auto-scroll',
            description: c.paged && !c.guided ? 'Auto-scroll needs the strip.' : SavedScope.session,
            disabled: c.paged && !c.guided,
            control: CineButton(
              label: s.autoScrolling ? 'Pause' : 'Play',
              variant: CineButtonVariant.quiet,
              size: CineButtonSize.sm,
              disabledReason: c.paged && !c.guided ? 'Auto-scroll needs the strip.' : null,
              onPressed: c.paged && !c.guided ? null : c.engine.toggleAutoScroll,
            ),
          ),
        ),
      ),
  (c) {
    final h = MediaQuery.sizeOf(c.context).height;
    return SettingsBlock(
      id: 'setup-autoscroll-speed',
      label: 'Auto-scroll speed',
      description: SavedScope.series,
      child: SpeedRuler(
        value: c.prefs.autoScrollSpeedX,
        onChanged: c.engine.setAutoScrollSpeedX,
        onCommit: (x) {
          c.engine.setAutoScrollSpeedX(x);
          unawaited(c.series.setFor(c.seriesRef, {'autoScrollSpeed': x}));
        },
        pxCaption: (x) => '≈ ${autoScrollPxPerSecondX(x, h).round()} PX/S',
      ),
    );
  },
  (c) => switchRow('setup-resume-after', 'Resume after I let go', c.ref.watch(readerSettingsProvider).resumeAfterRelease,
      (v) => c.profile.put({'resumeAfterRelease': v}), description: 'Resumes 0.8 s after you lift your finger. ${SavedScope.profile}.',),
  (c) {
    final has = c.engine.ambient.hasDialogueText;
    return switchRow('setup-pace-dialogue', 'Pace by dialogue', c.ref.watch(readerSettingsProvider).paceByDialogue, (v) => c.profile.put({'paceByDialogue': v}),
        description: has ? 'Slows down on pages with more dialogue. ${SavedScope.profile}.' : "Needs this chapter's dialogue. Scan it from Downloads.",);
  },
  (c) => switchRow('setup-page-tint', 'Page-tinted chrome', c.ref.watch(readerSettingsProvider).pageTint, (v) => c.profile.put({'pageTint': v}),
      description: SavedScope.profile,),
  (c) => const SoundscapePicker(),
  (c) => switchRow('setup-pause-narration', 'Pause the soundscape during narration', c.ref.watch(readerSettingsProvider).pauseSoundscapeForNarration,
      (v) => c.profile.put({'pauseSoundscapeForNarration': v}), description: 'Otherwise it drops to 30 % while a chapter is read aloud.',),
  (c) => switchRow('setup-guided-advance', 'Guided view auto-advance', c.ref.watch(readerSettingsProvider).guidedAutoAdvance.on,
      (v) => c.profile.setGuided(on: v), description: SavedScope.profile,),
  (c) {
    final g = c.ref.watch(readerSettingsProvider).guidedAutoAdvance;
    return segmentedRow('setup-guided-mode', 'Advance', const ['PACE BY WORDS', 'FIXED'], g.mode == 'FIXED' ? 1 : 0,
        (i) => unawaited(c.profile.setGuided(mode: i == 1 ? 'FIXED' : 'PACE_BY_WORDS')), description: SavedScope.profile,);
  },
  (c) {
    final g = c.ref.watch(readerSettingsProvider).guidedAutoAdvance;
    return sliderRow('setup-guided-fixed', 'Fixed hold', g.fixedMs / 1000, (v) => unawaited(c.profile.setGuided(fixedMs: (v * 2).round() * 500)),
        min: 2, max: 10, divisions: 16, flag: (v) => '${v.toStringAsFixed(1)} s', description: SavedScope.profile,);
  },
];

/// The four tabs, in order. The Fullscreen row is web-only and is not built here.
final List<SetupTab> kSetupTabs = [
  SetupTab('01', 'LAYOUT', layoutRows),
  SetupTab('02', 'IMAGE', imageRows),
  SetupTab('03', 'CONTROLS', controlsRows),
  SetupTab('04', 'AMBIENT', ambientRows),
];

/// 'Open menu with' (Settings > Reading and the reader's setup sheet), for every reader of the profile.
Widget menuOpenRow(WidgetRef ref, String id) {
  final mode = MenuOpen.of(ref.watch(readerSettingsProvider));
  return segmentedRow(id, 'Open menu with', const ['TAP', 'DOUBLE TAP', 'EDGE'], mode.index,
      (i) => unawaited(ref.read(readerSettingsProvider.notifier).put({'menuOpen': MenuOpen.values[i].name})),
      description: 'Edge: a tap along the top or bottom of the page. Manga and novels. ${SavedScope.profile}.',);
}

/// 'Show menu at chapter end'.
Widget menuAtEndRow(WidgetRef ref, String id) => switchRow(id, 'Show menu at chapter end', menuAtChapterEnd(ref.watch(readerSettingsProvider)),
    (v) => ref.read(readerSettingsProvider.notifier).put({'menuAtChapterEnd': v}),
    description: 'The next-chapter controls come up by themselves. ${SavedScope.profile}.',);
