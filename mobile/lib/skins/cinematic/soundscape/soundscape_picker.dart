import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/ambient_section.dart' show kSoundscapeLoops;
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Whether `Hear` can play [id] now: cached, or online to fetch it.
final soundscapeHearableProvider = FutureProvider.autoDispose.family<bool, String>((ref, id) async {
  final files = ref.watch(soundscapeFilesProvider);
  if (await files.isCached(id)) return true;
  try {
    return await ref.watch(networkConnectivityProvider).isOnline();
  } catch (_) {
    return true;
  }
}, name: 'soundscapeHearable',);

/// The house-sound choice (cinematic 9.4.2): `OFF`, `MATCH THE MOOD` and the eight loops as a radio
/// group, each loop with its line and a `Hear` button, then the device volume. Shared by Reading
/// setup's AMBIENT tab, the novel Type sheet's `AMBIENT` group and Settings -> Ambient.
class SoundscapePicker extends ConsumerWidget {
  const SoundscapePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final r = ref.watch(readerSettingsProvider);
    final sc = r.soundscape;
    final house = ref.watch(houseSoundProvider);
    final vol = ref.watch(soundscapeVolumeProvider);

    Future<void> choose(String v) async {
      await ref.read(readerSettingsProvider.notifier).put({'soundscape': v});
      await ref.read(novelSettingsProvider.notifier).put({'soundscape': v});
    }

    Widget option(String id, String label, {String? line, bool hear = false}) {
      final hearable = hear ? ref.watch(soundscapeHearableProvider(id)).valueOrNull ?? true : true;
      final fetching = house.fetchingId == id;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: c.space1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: sc == id,
                child: CineRadio<String>(value: id, groupValue: sc, label: label, onChanged: choose),
              ),
              if (line != null) Padding(padding: const EdgeInsets.only(left: 36), child: CineRoleText(line, c.typeCaption, color: c.colorInk60)),
              if (hear && !hearable)
                Padding(padding: const EdgeInsets.only(left: 36), child: CineRoleText("Available when you're online.", c.typeCaption, color: c.colorInk60)),
            ],),
          ),
          if (hear)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CineButton(
                key: Key('hear-$id'),
                label: 'Hear',
                variant: CineButtonVariant.secondary,
                size: CineButtonSize.sm,
                loading: fetching,
                disabledReason: hearable ? null : "Available when you're online.",
                onPressed: hearable && !house.previewing ? () => unawaited(house.hear(id)) : null,
              ),
            ),
        ],),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsBlock(
        id: 'soundscape',
        label: 'Soundscape',
        description: 'Used by manga and novels. Saved for this profile.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          option('off', 'OFF'),
          option('match', 'MATCH THE MOOD'),
          for (final (id, label, line) in kSoundscapeLoops) option(id, label, line: line, hear: true),
        ],),
      ),
      sliderRow('soundscape-volume', 'Soundscape volume', vol * 100, (v) => ref.read(soundscapeVolumeProvider.notifier).set(v.round() / 100),
          min: 0, max: 100, divisions: 100, flag: (v) => '${v.round()} %', description: 'Saved on this device.',),
    ],);
  }
}
