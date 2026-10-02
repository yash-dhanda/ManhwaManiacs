import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/engine/menu_open.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fill_slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_sheet.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The Glass reader's values for one series, read live from the stores the settings sheet writes (glass 8.14.5, 8.25.3).
class GlassReaderSettingsView {
  const GlassReaderSettingsView({required this.prefs, required this.values, required this.cruiseSpeed, required this.device});
  final ReaderPrefs prefs;
  final GlassReaderValueSet values;
  final double cruiseSpeed;
  final ReaderDefaults device;
}

final glassReaderSettingsProvider = Provider.autoDispose.family<GlassReaderSettingsView, String>((ref, seriesRef) {
  final profile = ref.watch(readerSettingsProvider);
  final shared = ref.watch(sharedPrefsProvider);
  final own = ref.watch(readerSeriesPrefsProvider).data[seriesRef];
  return GlassReaderSettingsView(
    prefs: ref.watch(readerPrefsProvider(seriesRef)),
    values: GlassReaderValueSet.resolve(profile, shared.get),
    cruiseSpeed: glassCruiseSpeedOf(own is Map ? JsonRecord(Map<String, dynamic>.from(own)) : null, profile),
    device: ref.watch(readerDefaultsProvider),
  );
});

/// Writes the sheet's rows to the right store: per series, per profile (shared fields and `glass.*`), or per device.
class GlassReaderSettingsWriter {
  GlassReaderSettingsWriter(this.ref, this.seriesRef);
  final WidgetRef ref;
  final String seriesRef;

  Future<void> series(Map<String, dynamic> patch) => ref.read(readerSeriesPrefsProvider.notifier).setFor(seriesRef, patch);
  Future<void> profile(Map<String, dynamic> patch) => ref.read(readerSettingsProvider.notifier).put(patch);
  Future<void> glass(Map<String, dynamic> fields) => profile(glassPatch(ref.read(readerSettingsProvider), fields));
}

/// The reader settings (glass 8.14.5): a sheet at `medium` on phones and tablet frames (changes apply live), inline in the right
/// panel's Settings tab on desktop frames. Every row names its scope.
class ReaderSettingsBody extends ConsumerWidget {
  const ReaderSettingsBody({super.key, required this.seriesRef, this.readAll = false, this.onTapsChanged, this.onOpenSheet, this.inPanel = false});
  final String seriesRef;
  final bool readAll;

  /// Ambient rows that open something else (`soundscape`, `guided`): the host closes this sheet first.
  final ValueChanged<String>? onOpenSheet;

  /// Inline in the desktop frame's right panel: the Soundscape section opens the tab (glass 8.14.11).
  final bool inPanel;

  /// The layout changed: the reader shows its three-pane tap overlay.
  final VoidCallback? onTapsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(glassReaderSettingsProvider(seriesRef));
    final w = GlassReaderSettingsWriter(ref, seriesRef);
    final p = v.prefs;
    final strip = p.layout == 'strip' || p.layout == 'guided' || readAll;
    final android = defaultTargetPlatform == TargetPlatform.android;
    final apps = android || defaultTargetPlatform == TargetPlatform.iOS;
    const thisSeries = 'This series', allSeries = 'All series';
    final record = ref.watch(readerSettingsProvider);
    final menu = MenuOpen.of(record);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // At text scale above 1.3 the cruise button has left the bottom capsule: it is the first row here (glass 3.3 rule 4).
        if (strip && MediaQuery.textScalerOf(context).scale(17) / 17 > 1.3)
          _SwitchRow(
            title: 'Cruise',
            scope: thisSeries,
            value: ref.watch(cruiseControllerProvider).running,
            onChanged: (_) => ref.read(cruiseControllerProvider.notifier).toggle(),
          ),
        if (inPanel) ...[
          const _Section('Soundscape'),
          SoundscapeSheetBody(seriesRef: seriesRef),
        ],
        const _Section('Layout'),
        if (!readAll)
          _Row(
            title: 'Layout',
            scope: thisSeries,
            child: GlassSegmented<String>(
              segments: const [GlassSegment(value: 'strip', label: 'Strip'), GlassSegment(value: 'single', label: 'Single'), GlassSegment(value: 'double', label: 'Double')],
              selected: p.layout == 'guided' ? 'strip' : p.layout,
              onSelected: (x) {
                unawaited(w.series({'layout': x}));
                onTapsChanged?.call();
              },
            ),
          ),
        _Row(
          title: 'Direction',
          scope: thisSeries,
          child: GlassSegmented<String>(
            segments: const [GlassSegment(value: 'ltr', label: 'Left to right'), GlassSegment(value: 'rtl', label: 'Right to left')],
            selected: p.direction,
            onSelected: (x) => unawaited(w.series({'direction': x})),
          ),
        ),
        _Row(
          title: 'Fit',
          scope: thisSeries,
          caption: strip ? 'Strip pages always fit the width' : null,
          child: GlassSegmented<String>(
            segments: const [GlassSegment(value: 'width', label: 'Width'), GlassSegment(value: 'height', label: 'Height'), GlassSegment(value: 'original', label: 'Original')],
            selected: strip ? 'width' : p.fit,
            enabled: !strip,
            onSelected: (x) => unawaited(w.series({'fit': x})),
          ),
        ),
        _Row(
          title: 'Zoom',
          scope: thisSeries,
          child: Row(
            children: [
              Expanded(
                child: GlassStepper(
                  label: 'Zoom',
                  value: (p.zoom * 100).round(),
                  min: 50,
                  max: 300,
                  step: 10,
                  format: (z) => '$z %',
                  onChanged: (z) => unawaited(w.series({'zoom': z})),
                ),
              ),
              const SizedBox(width: 8),
              GlassChip(label: 'Reset', onPressed: () => unawaited(w.series({'zoom': 100}))),
            ],
          ),
        ),
        _Row(
          title: 'Chapters',
          scope: allSeries,
          child: GlassSegmented<String>(
            segments: const [GlassSegment(value: 'continuous', label: 'Continuous'), GlassSegment(value: 'single', label: 'One at a time')],
            selected: v.values.chapters,
            onSelected: (x) => unawaited(w.glass({GlassReaderKeys.chapters: x})),
          ),
        ),
        if (strip) _SwitchRow(title: 'Page gap', scope: allSeries, value: p.gap, onChanged: (x) => unawaited(w.profile({'gap': x}))),
        const _Section('Motion'),
        if (!strip)
          _Row(
            title: 'Page transition',
            scope: allSeries,
            child: GlassSegmented<String>(
              segments: const [GlassSegment(value: 'slide', label: 'Slide'), GlassSegment(value: 'fade', label: 'Fade'), GlassSegment(value: 'none', label: 'None')],
              selected: v.values.pageTransition,
              onSelected: (x) => unawaited(w.glass({GlassReaderKeys.pageTransition: x})),
            ),
          ),
        _SwitchRow(title: 'Auto next', scope: allSeries, value: p.autoNextChapter, onChanged: (x) => unawaited(w.profile({'autoNextChapter': x}))),
        _SwitchRow(title: 'Swipe sideways to change chapter', scope: allSeries, value: v.values.swipeChapter, onChanged: (x) => unawaited(w.glass({GlassReaderKeys.swipeChapter: x}))),
        const _Section('Taps'),
        _Row(
          title: 'Open menu with',
          scope: allSeries,
          caption: 'Edge: a tap along the top or bottom of the page. Manga and novels.',
          child: GlassSegmented<MenuOpen>(
            segments: const [
              GlassSegment(value: MenuOpen.tap, label: 'Tap'),
              GlassSegment(value: MenuOpen.doubleTap, label: 'Double tap'),
              GlassSegment(value: MenuOpen.edge, label: 'Edge'),
            ],
            selected: menu,
            onSelected: (m) => unawaited(w.profile({'menuOpen': m.name})),
          ),
        ),
        _SwitchRow(
          title: 'Show menu at chapter end',
          scope: allSeries,
          value: menuAtChapterEnd(record),
          onChanged: (x) => unawaited(w.profile({'menuAtChapterEnd': x})),
        ),
        _Row(
          title: 'Tap zones',
          scope: allSeries,
          caption: menu.help,
          child: TapZonesDiagram(
            zones: p.tapZones ?? (p.rtl ? const ['next', 'menu', 'previous'] : const ['previous', 'menu', 'next']),
            custom: p.tapZones != null,
            onChanged: (z) => unawaited(w.profile(z == null
                ? {'tapZone.left': null, 'tapZone.center': null, 'tapZone.right': null}
                : {'tapZone.left': z[0], 'tapZone.center': z[1], 'tapZone.right': z[2]},),),
          ),
        ),
        if (strip) _SwitchRow(title: 'Tap to scroll', scope: allSeries, value: v.values.tapToScroll, onChanged: (x) => unawaited(w.glass({GlassReaderKeys.tapToScroll: x}))),
        const _Section('Light'),
        _Row(
          title: 'Brightness and warmth',
          scope: allSeries,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassFillSlider(
                label: 'Brightness',
                value: (v.values.brightness - 0.2) / 0.8,
                onChanged: (x) => unawaited(w.glass({GlassReaderKeys.brightness: 0.2 + 0.8 * x})),
              ),
              const SizedBox(width: 24),
              GlassFillSlider(
                label: 'Warmth',
                value: v.values.warmth,
                onChanged: (x) => unawaited(w.glass({GlassReaderKeys.warmth: x})),
              ),
            ],
          ),
        ),
        _Row(
          title: 'Colour',
          scope: allSeries,
          child: GlassSegmented<String>(
            segments: const [GlassSegment(value: 'normal', label: 'Normal'), GlassSegment(value: 'sepia', label: 'Sepia'), GlassSegment(value: 'grey', label: 'Grey')],
            selected: p.colour,
            onSelected: (x) => unawaited(w.profile({'colour': x})),
          ),
        ),
        _Row(
          title: 'Background',
          scope: allSeries,
          child: GlassSegmented<String>(
            segments: const [GlassSegment(value: 'black', label: 'Black'), GlassSegment(value: 'graphite', label: 'Graphite')],
            selected: v.values.background,
            onSelected: (x) => unawaited(w.glass({GlassReaderKeys.background: x})),
          ),
        ),
        const _Section('Ambient'),
        _SwitchRow(title: 'Page-tinted chrome', scope: allSeries, value: v.values.pageTinted, onChanged: (x) => unawaited(w.glass({GlassReaderKeys.pageTinted: x}))),
        _Row(
          title: 'Cruise speed',
          scope: thisSeries,
          trailing: GlassText('${v.cruiseSpeed.toStringAsFixed(2)}×', role: gt.typeMono, onGlass: true),
          child: GlassSlider(
            label: 'Cruise speed',
            value: cruiseToTrack(v.cruiseSpeed),
            format: (t) => '${trackToCruise(t).toStringAsFixed(2)}×',
            onChanged: (t) => unawaited(w.series({GlassReaderKeys.cruiseSpeed: cruiseMagnet(trackToCruise(t))})),
          ),
        ),
        if (!inPanel)
          _NavRow(title: 'Soundscape', value: ref.watch(soundscapeControllerProvider).summary, onTap: () => onOpenSheet?.call('soundscape')),
        if (strip) _NavRow(title: 'Guided view', value: null, onTap: () => onOpenSheet?.call('guided')),
        const _Section('Screen'),
        _SwitchRow(title: 'Cinema mode', scope: allSeries, value: p.cinema, onChanged: (x) => unawaited(w.profile({'cinema': x}))),
        if (p.cinema)
          _SwitchRow(title: 'Hide progress', scope: allSeries, value: v.values.hideCinemaProgress, onChanged: (x) => unawaited(w.glass({GlassReaderKeys.hideCinemaProgress: x}))),
        if (apps) _SwitchRow(title: 'Keep screen awake', scope: allSeries, value: v.values.keepAwake, onChanged: (x) => unawaited(w.glass({GlassReaderKeys.keepAwake: x}))),
        if (android)
          _Row(
            title: 'Refresh rate',
            scope: 'This device',
            caption: 'Auto uses the highest rate your screen supports',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rate in ReaderRefreshRate.values)
                  GlassChip(
                    label: rate == ReaderRefreshRate.auto ? 'Auto' : '${rate.targetHz!.round()}',
                    inChoiceGroup: true,
                    selected: v.device.refreshRate == rate,
                    onPressed: () => unawaited(ref.read(readerDefaultsProvider.notifier).setRefreshRate(rate)),
                  ),
              ],
            ),
          ),
        if (android)
          _SwitchRow(
            title: 'Volume keys turn pages',
            scope: 'This device',
            value: v.device.volumeKeyNavigation,
            onChanged: (x) => unawaited(ref.read(readerDefaultsProvider.notifier).setVolumeKeyNavigation(x)),
          ),
        _SwitchRow(
          title: 'Lock reader controls',
          scope: allSeries,
          caption: 'Tap the centre 5 times to unlock',
          value: v.values.lockControls,
          onChanged: (x) => unawaited(w.glass({GlassReaderKeys.lockControls: x})),
        ),
        const _Section('Help'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: HoldToConfirm(
            label: 'Reset reader settings',
            fallbackLabel: 'Reset',
            onConfirm: () async {
              final rec = ref.read(readerSettingsProvider);
              final keep = Map<String, dynamic>.of(rec.data)..remove('glass');
              await ref.read(readerSettingsProvider.notifier).reset();
              // Cinematic's fields survive a Glass reset; only the Glass object and the shared reader rows go.
              keep.removeWhere((k, _) => const {'gap', 'colour', 'cinema', 'autoNextChapter', 'tapZone.left', 'tapZone.center', 'tapZone.right'}.contains(k));
              if (keep.isNotEmpty) await ref.read(readerSettingsProvider.notifier).put(keep);
              await ref.read(readerSeriesPrefsProvider.notifier).put({seriesRef: <String, dynamic>{}});
              showGlassToast(ref, const GlassToastSpec('Reader settings reset'));
            },
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Semantics(header: true, child: GlassText(title, role: gt.typeHeadline, onGlass: true)),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.scope, required this.child, this.caption, this.trailing});
  final String title, scope;
  final String? caption;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true)),
                if (trailing != null) trailing!,
                const SizedBox(width: 8),
                GlassText(scope, role: gt.typeCaption1, onGlass: true),
              ],
            ),
            if (caption != null) GlassText(caption!, role: gt.typeFootnote, onGlass: true),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

/// A row that opens something: the title, its current value and a caret.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.value, required this.onTap});
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: title,
        value: value,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: GlassFrame.hitMin(context)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true)),
                  if (value != null) GlassText(value!, role: gt.typeFootnote, onGlass: true),
                  const SizedBox(width: 6),
                  Icon(GlassGlyph.caretRight.regular, size: 16, color: gt.colorOnGlass),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.scope, required this.value, required this.onChanged, this.caption});
  final String title, scope;
  final String? caption;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true),
                  GlassText(caption == null ? scope : '$caption · $scope', role: gt.typeCaption1, onGlass: true),
                ],
              ),
            ),
            GlassSwitch(value: value, onChanged: onChanged, label: title),
          ],
        ),
      );
}

/// The phone-silhouette tap diagram (glass 8.14.5): three bands; a tap cycles Previous, Menu, Next; "Reset to automatic".
class TapZonesDiagram extends StatelessWidget {
  const TapZonesDiagram({super.key, required this.zones, required this.custom, required this.onChanged});
  final List<String> zones;
  final bool custom;
  final ValueChanged<List<String>?> onChanged;

  static String _next(String a) => switch (a) { 'previous' => 'menu', 'menu' => 'next', _ => 'previous' };
  static String _label(String a) => switch (a) { 'previous' => 'Back', 'menu' => 'Menu', _ => 'Next' };

  @override
  Widget build(BuildContext context) {
    Widget band(int i, String name, double flex) => Expanded(
          flex: (flex * 10).round(),
          child: Semantics(
            button: true,
            label: '$name band: ${_label(zones[i])}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged([for (var j = 0; j < 3; j++) j == i ? _next(zones[j]) : zones[j]]),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: gt.colorWellOnGlass, borderRadius: BorderRadius.circular(10)),
                child: GlassText(_label(zones[i]), role: gt.typeFootnote, onGlass: true),
              ),
            ),
          ),
        );
    return Column(
      children: [
        Center(
          child: Container(
            width: 120,
            height: 200,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: gt.colorOnGlass.withValues(alpha: 0.4))),
            child: Row(children: [band(0, 'Left', 3), band(1, 'Centre', 4), band(2, 'Right', 3)]),
          ),
        ),
        if (custom)
          GestureDetector(
            onTap: () => onChanged(null),
            child: Padding(padding: const EdgeInsets.only(top: 8), child: GlassText('Reset to automatic', role: gt.typeFootnote, color: gt.colorIris400)),
          ),
      ],
    );
  }
}
