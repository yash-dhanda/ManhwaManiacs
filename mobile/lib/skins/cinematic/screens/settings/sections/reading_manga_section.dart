import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/recap_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';

const _tapLabels = ['PREVIOUS', 'MENU', 'NEXT'];
const _tapValues = ['previous', 'menu', 'next'];

/// Reading: manga (cinematic 8.30.2 row 3, 8.14.8): edits the records the reader reads.
class ReadingMangaSection extends ConsumerWidget {
  const ReadingMangaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(readerSettingsProvider);
    final n = ref.read(readerSettingsProvider.notifier);
    final d = r.seriesDefaults;
    final dev = ref.watch(readerDefaultsProvider);
    final devN = ref.read(readerDefaultsProvider.notifier);
    final android = Theme.of(context).platform == TargetPlatform.android;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final stripWidth = ref.watch(stripWidthProvider);
    const profile = 'Saved for this profile';
    const device = 'Saved on this device';

    Widget tapRow(String side, String label) => segmentedRow(
          'tap-zones-$side',
          label,
          _tapLabels,
          _tapValues.indexOf(r.tapZone(side)),
          (i) => n.put({'tapZone.$side': _tapValues[i]}),
        );

    Future<void> reset() async {
      final ok = await showCineConfirm(
        context,
        title: 'Restore every reader setting to its default?',
        confirmLabel: 'Restore defaults',
        destructive: true,
      );
      if (!ok) return;
      await n.reset();
      await devN.setKeepScreenAwake(false);
      await devN.setLockControls(false);
      await devN.setVolumeKeyNavigation(false);
      await devN.setRefreshRate(ReaderRefreshRate.auto);
      await ref.read(stripWidthProvider.notifier).set(680);
      ref.read(cineToastsProvider.notifier).info('Reader settings reset.');
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('EVERY SERIES'),
      segmentedRow('layout', 'Layout', const ['STRIP', 'SINGLE', 'DOUBLE', 'GUIDED'], SeriesDefaults.layouts.indexOf(d.layout),
          (i) => n.setSeriesDefaults(d.copyWith(layout: SeriesDefaults.layouts[i])),
          description: 'A series you have not set up yourself opens like this. $profile.',),
      segmentedRow('direction', 'Direction', const ['LEFT TO RIGHT', 'RIGHT TO LEFT'], SeriesDefaults.directions.indexOf(d.direction),
          (i) => n.setSeriesDefaults(d.copyWith(direction: SeriesDefaults.directions[i])),
          description: 'Left to right: webtoons and western comics. Right to left: manga.',),
      segmentedRow('fit', 'Fit', const ['WIDTH', 'HEIGHT', 'ORIGINAL'], SeriesDefaults.fits.indexOf(d.fit),
          (i) => n.setSeriesDefaults(d.copyWith(fit: SeriesDefaults.fits[i])),),
      stepperRow('zoom', 'Zoom', d.zoom, (v) => n.setSeriesDefaults(d.copyWith(zoom: v)), min: 50, max: 300, step: 10, unit: '%'),
      quietAction('Reset zoom', d.zoom == 100 ? null : () => n.setSeriesDefaults(d.copyWith(zoom: 100))),
      const SettingsKicker('THE PAGE'),
      if (!tablet)
        segmentedRow('side-margin', 'Side margin', const ['0', '5', '10', '15', '20', '25'], [0, 5, 10, 15, 20, 25].indexOf(r.sideMargin),
            (i) => n.put({'sideMargin': i * 5}),
            description: '$profile. Percent of the screen width.',),
      if (tablet)
        sliderRow('strip-width', 'Strip width', stripWidth.toDouble(), (v) => ref.read(stripWidthProvider.notifier).set(v.round()),
            min: 480, max: 860, divisions: 19, flag: (v) => '${v.round()} dp', description: device,),
      switchRow('gap', 'Gap between pages', r.gap, (v) => n.put({'gap': v}), description: profile),
      segmentedRow('page-turn', 'Page turn', const ['CUT', 'SLIDE', 'FADE'], const ['cut', 'slide', 'fade'].indexOf(r.pageTurn),
          (i) => n.put({'pageTurn': const ['cut', 'slide', 'fade'][i]}),),
      sliderRow('brightness', 'Brightness', r.brightness.toDouble(), (v) => n.put({'brightness': v.round()}),
          min: -75, max: 0, divisions: 75, flag: (v) => '${v.round()}', description: "Dims below your screen's lowest setting.",),
      sliderRow('warmth', 'Warmth', r.warmth.toDouble(), (v) => n.put({'warmth': v.round()}), min: 0, max: 100, divisions: 100, flag: (v) => '${v.round()}'),
      segmentedRow('colour', 'Colour', const ['NORMAL', 'SEPIA', 'GREY'], const ['normal', 'sepia', 'grey'].indexOf(r.colour),
          (i) => n.put({'colour': const ['normal', 'sepia', 'grey'][i]}),),
      segmentedRow('ground', 'Ground', const ['BLACK', 'INK', 'SLATE'], const ['black', 'ink', 'slate'].indexOf(r.ground),
          (i) => n.put({'ground': const ['black', 'ink', 'slate'][i]}),),
      const SettingsKicker('TAPS AND SWIPES'),
      const JumpRow(id: 'tap-zones', child: SettingsCaption('Tap zones: what each side of the page does.')),
      tapRow('left', 'LEFT'),
      tapRow('center', 'CENTRE'),
      tapRow('right', 'RIGHT'),
      quietAction('Reset tap zones', () => n.put({'tapZone.left': 'previous', 'tapZone.center': 'menu', 'tapZone.right': 'next'})),
      segmentedRow('strip-taps', 'Strip taps', const ['MENU', 'TAP TO SCROLL'], r.stripTaps == 'menu' ? 0 : 1, (i) => n.put({'stripTaps': i == 0 ? 'menu' : 'scroll'})),
      switchRow('swipe-sideways', 'Swipe sideways to change chapter', r.swipeSideways, (v) => n.put({'swipeSideways': v}), description: profile),
      switchRow('cinema', 'Cinema mode', r.cinema, (v) => n.put({'cinema': v}), description: profile),
      switchRow('auto-next', 'Auto next chapter', r.autoNextChapter, (v) async {
        await n.put({'autoNextChapter': v});
        await devN.setAutoNextChapter(v);
      }, description: profile,),
      const SettingsKicker('THIS PHONE'),
      switchRow('keep-awake', 'Keep screen awake', dev.keepScreenAwake, devN.setKeepScreenAwake, description: device),
      switchRow('lock-controls', 'Lock controls', dev.lockControls, devN.setLockControls,
          description: 'The reader opens locked. Tap the centre five times to unlock. $device.',),
      if (android) switchRow('volume-keys', 'Volume keys turn pages', dev.volumeKeyNavigation, devN.setVolumeKeyNavigation, description: device),
      if (android)
        segmentedRow('refresh-rate', 'Refresh rate', const ['AUTO', '30', '60', '90', '120'], dev.refreshRate.index,
            (i) => devN.setRefreshRate(ReaderRefreshRate.values[i]), description: device,),
      const RecapRows(),
      JumpRow(id: 'reset-reader', child: quietAction('Reset reader settings', () => unawaited(reset()))),
    ],);
  }
}
