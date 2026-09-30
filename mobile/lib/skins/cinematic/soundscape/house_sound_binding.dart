import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_match.dart';

/// The reader's side of the house sound (cinematic 9.4.2): with a soundscape set, the loop fades in
/// over 2000 ms when a reader opens, out over 600 ms on leaving and on `AppLifecycleState.paused`
/// (back in over 2000 ms on `resumed`), and ducks to 30 % or pauses under narration. Place it
/// anywhere in a reader's tree; it paints nothing.
class HouseSoundBinding extends ConsumerStatefulWidget {
  const HouseSoundBinding({super.key, required this.genres});

  /// The series' genres, for `MATCH THE MOOD`.
  final List<String> genres;

  @override
  ConsumerState<HouseSoundBinding> createState() => _HouseSoundBindingState();
}

class _HouseSoundBindingState extends ConsumerState<HouseSoundBinding> with WidgetsBindingObserver {
  late final HouseSound _house;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _house = ref.read(houseSoundProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _paused = true;
      unawaited(_house.fadeOutForExit());
    } else if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
      if (_wanted() != null) unawaited(_house.resume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the reader: out over 600 ms; the next reader resumes it with the 2000 ms fade.
    unawaited(_house.fadeOutForExit());
    super.dispose();
  }

  String? _wanted() {
    final sc = ref.read(readerSettingsProvider).soundscape;
    if (sc == 'off') return null;
    if (sc == 'match') return matchTheMood(widget.genres, ref.read(activeProfileProvider)?.mood ?? Mood.neutral);
    return sc;
  }

  void _apply() {
    if (!mounted) return;
    final want = _wanted();
    if (want != null && want == _house.loopId) {
      unawaited(_house.resume());
    } else {
      unawaited(_house.setLoop(want));
    }
  }

  void _narration(bool active) {
    final pause = ref.read(readerSettingsProvider).pauseSoundscapeForNarration;
    if (_house.loopId == null) return;
    if (pause) {
      unawaited(active ? _house.pause() : _house.resume());
    } else {
      unawaited(_house.duck(active));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(readerSettingsProvider.select((r) => r.soundscape), (_, __) => _apply());
    ref.listen<Mood?>(activeProfileProvider.select((p) => p?.mood), (_, __) => _apply());
    ref.listen<bool>(narrationActiveProvider, (_, active) => _narration(active));
    return const SizedBox.shrink();
  }
}
