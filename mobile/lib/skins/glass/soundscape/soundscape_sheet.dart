import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/ambient_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/scene_orb.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The `?sheet=soundscape` page (glass 8.0.3, 9.4.2 Picker): `medium` on phones, draggable to `large`; landscape phones a centred
/// `min(560, width - 16)` window at screen height minus the safe top and 10.
GlassSheetPage<void> soundscapeSheetPage({String? seriesRef, required bool landscapePhone}) => GlassSheetPage<void>(
      key: const ValueKey('sheet:soundscape'),
      title: 'Soundscape',
      detents: landscapePhone ? const [GlassDetent.large] : const [GlassDetent.medium, GlassDetent.large],
      opening: landscapePhone ? GlassDetent.large : GlassDetent.medium,
      builder: (context) => SingleChildScrollView(child: SoundscapeSheetBody(seriesRef: seriesRef)),
    );

/// `?sheet=soundscape` outside a reader (Settings, the listen player): the same sheet, no series (so no "Remember for this series").
void registerSoundscapeSheet() {
  if (glassSheetRegistered('soundscape')) return;
  registerGlobalSheet(
    'soundscape',
    GlassSheetSpec(
      title: 'Soundscape',
      detents: const [GlassDetent.medium, GlassDetent.large],
      opening: GlassDetent.medium,
      builder: (context) => const SingleChildScrollView(child: SoundscapeSheetBody()),
    ),
  );
}

/// The sheet body, also the Soundscape section of the desktop frame's right panel (`inPanel`): seven orbs, the Bed - Detail - Tone mixer,
/// the master volume and three switches. T4 glass at `medium`, so its text is `onGlass`.
class SoundscapeSheetBody extends ConsumerStatefulWidget {
  const SoundscapeSheetBody({super.key, this.seriesRef});

  /// The open series (`source:series`), null outside a reader: "Remember for this series" shows only inside one.
  final String? seriesRef;

  @override
  ConsumerState<SoundscapeSheetBody> createState() => _SoundscapeSheetBodyState();
}

class _SoundscapeSheetBodyState extends ConsumerState<SoundscapeSheetBody> with SingleTickerProviderStateMixin {
  late final OrbClock _clock = OrbClock(this);
  late final SoundscapeController _controller = ref.read(soundscapeControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _controller.watchLevels(true);
    // The other scenes render one at a time in the background while the sheet is open.
    unawaited(ref.read(proceduralStoreProvider).prewarmAll().catchError((_) {}));
  }

  @override
  void dispose() {
    _controller.watchLevels(false);
    _clock.dispose();
    super.dispose();
  }

  SeriesSoundscape? get _own => widget.seriesRef == null ? null : ref.read(readerPrefsProvider(widget.seriesRef!)).soundscape;

  void _persistSeries(SoundScene? scene, MixLevels mix) {
    final r = widget.seriesRef;
    if (r == null || scene == null) return;
    unawaited(ref.read(readerSeriesPrefsProvider.notifier).setSoundscape(r, SeriesSoundscape(scene: scene.name, bed: mix.bed, detail: mix.detail, tone: mix.tone)));
  }

  void _select(SoundScene scene) {
    unawaited(_controller.start(scene));
    final v = ref.read(soundscapeControllerProvider);
    if (v.remember) _persistSeries(scene, v.mix);
  }

  void _setMix(SoundLayer l, double x) {
    _controller.setMix(l, x);
    final v = ref.read(soundscapeControllerProvider);
    if (v.remember) {
      _persistSeries(v.scene, v.mix);
    } else {
      unawaited(ref.read(soundscapeDefaultsRecordProvider.notifier).setMix(l.name, x));
    }
  }

  void _setRemember(bool on) {
    _controller.setRemember(on);
    final r = widget.seriesRef;
    if (r == null) return;
    final v = ref.read(soundscapeControllerProvider);
    if (on) {
      _persistSeries(v.scene ?? v.matchedScene, v.mix);
    } else {
      unawaited(ref.read(readerSeriesPrefsProvider.notifier).setSoundscape(r, null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(soundscapeControllerProvider);
    final d = ref.watch(soundscapeDefaultsProvider);
    final reduced = ref.watch(glassMotionPrefsProvider.select((p) => p.reduced));
    _clock.run(!reduced);
    final hit = GlassFrame.hitMin(context);
    final selected = v.on ? v.scene : null;
    final inReader = widget.seriesRef != null;

    Widget orb(SoundScene s) => SceneOrb(
          scene: s,
          clock: _clock,
          selected: selected == s,
          matched: v.matchedScene == s,
          builtin: v.builtin,
          reduced: reduced,
          onSelect: () => _select(s),
          bars: selected == s ? LevelBars(levels: _controller.levels, mix: v.mix, reduced: reduced) : null,
        );
    // The grid fits a phone (and the 328 px panel); the one row needs 7 orbs of room.
    return LayoutBuilder(builder: (context, box) => _body(context, box.maxWidth < 680, v, d, reduced, hit, orb, selected, inReader));
  }

  Widget _body(BuildContext context, bool phone, SoundscapeView v, SoundscapeDefaults d, bool reduced, double hit, Widget Function(SoundScene) orb, SoundScene? selected, bool inReader) {
    final off = _OffControl(selected: !v.on, wide: !phone, onSelect: () => unawaited(_controller.stop()), side: math.max(44.0, hit));
    final orbs = phone
        ? Column(children: [
            Align(alignment: Alignment.centerLeft, child: off),
            const SizedBox(height: 12),
            for (final row in [SoundScene.values.sublist(0, 3), SoundScene.values.sublist(3)])
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final s in row) orb(s)])),
          ],)
        : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [off, for (final s in SoundScene.values) orb(s)]);

    final scope = v.remember && inReader ? 'This series' : 'All series · Saved on this device';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Soundscape',
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              orbs,
              const SizedBox(height: 8),
              _LayerSlider(label: 'Bed', value: v.mix.bed, onChanged: (x) => _setMix(SoundLayer.bed, x)),
              _LayerSlider(label: 'Detail', value: v.mix.detail, onChanged: (x) => _setMix(SoundLayer.detail, x)),
              _LayerSlider(label: 'Tone', value: v.mix.tone, onChanged: (x) => _setMix(SoundLayer.tone, x)),
              Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassText(scope, role: gt.typeCaption1, onGlass: true)),
              _Row(
                title: 'Volume',
                trailing: GlassText('${v.volumeDb < 0 ? '−' : ''}${v.volumeDb.abs()} dB', role: gt.typeMono, onGlass: true),
                child: GlassSlider(
                  label: 'Soundscape volume',
                  value: (v.volumeDb + 30) / 30,
                  divisions: 30,
                  format: (t) => '${(t * 30 - 30).round()} dB',
                  onChanged: (t) {
                    final db = (t * 30).round() - 30;
                    if (db == v.volumeDb) return;
                    _controller.setVolume(db);
                    unawaited(ref.read(soundscapeDefaultsRecordProvider.notifier).setVolumeDb(db));
                  },
                ),
              ),
              _SwitchRow(
                title: 'Match the story',
                value: d.matchStory,
                onChanged: (x) => unawaited(ref.read(soundscapeDefaultsRecordProvider.notifier).setMatchStory(x)),
              ),
              if (inReader) _SwitchRow(title: 'Remember for this series', value: v.remember || _own != null, onChanged: _setRemember),
              _SwitchRow(
                title: 'Lower under narration',
                value: d.lowerUnderNarration,
                onChanged: (x) => unawaited(ref.read(soundscapeDefaultsRecordProvider.notifier).setLowerUnderNarration(x)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Off choice: a 44 pt capsule radio above the grid on phones, the first 64 px orb on wider frames.
class _OffControl extends StatelessWidget {
  const _OffControl({required this.selected, required this.wide, required this.onSelect, required this.side});
  final bool selected, wide;
  final VoidCallback onSelect;
  final double side;

  @override
  Widget build(BuildContext context) {
    final inner = wide
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 64,
              height: 64,
              child: GlassPressable(
                material: GlassMaterial.content,
                shape: const GlassShape.circle(),
                minHit: false,
                noSemantics: true,
                onTap: onSelect,
                haptic: HapticEvent.select,
                selected: selected,
                builder: (context, info) => DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gt.colorFill2,
                    border: Border.all(color: selected ? gt.colorIris400 : const Color(0x38FFFFFF), width: selected ? 2 : 0.5),
                  ),
                  child: Center(child: Icon(AmbientGlyph.speakerSimpleSlash.regular, size: 28, color: gt.colorOnGlass)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            GlassText('Off', role: gt.typeFootnote, onGlass: true),
          ],)
        : GlassPressable(
            material: GlassMaterial.content,
            minHit: false,
            noSemantics: true,
            onTap: onSelect,
            haptic: HapticEvent.select,
            selected: selected,
            builder: (context, info) => Container(
              height: side,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(side / 2),
                color: gt.colorFill2,
                border: Border.all(color: selected ? gt.colorIris400 : const Color(0x38FFFFFF), width: selected ? 2 : 0.5),
              ),
              child: Center(widthFactor: 1, child: GlassText('Off', role: gt.typeSubhead, wght: 600, onGlass: true)),
            ),
          );
    return Semantics(container: true, inMutuallyExclusiveGroup: true, checked: selected, button: true, label: 'Off', onTap: onSelect, excludeSemantics: true, child: inner);
  }
}

class _LayerSlider extends StatelessWidget {
  const _LayerSlider({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
        title: label,
        trailing: GlassText('${(value * 100).round()} %', role: gt.typeMono, onGlass: true),
        child: GlassSlider(label: label, value: value, divisions: 10, format: (v) => '${(v * 100).round()} %', onChanged: onChanged),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true)), if (trailing != null) trailing!]),
            child,
          ],
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true)),
          GlassSwitch(value: value, onChanged: onChanged, label: title),
        ],),
      );
}
