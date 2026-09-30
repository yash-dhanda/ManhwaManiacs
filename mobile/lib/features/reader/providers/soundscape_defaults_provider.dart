import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';

/// The seven Glass soundscape scenes (glass 9.4.2); `off` plays nothing.
const List<String> kSoundscapeScenes = ['off', 'rain', 'wind', 'ocean', 'hearth', 'stream', 'deep'];

/// `mm.soundscape.defaults.u{user}p{profile}` (glass 9.4.2, 15.5): what the soundscape player (`mobile/44`) starts from, saved on
/// this device. Unknown fields survive every write.
class SoundscapeDefaults {
  const SoundscapeDefaults({
    this.scene = 'off',
    this.matchStory = true,
    this.bed = 0.80,
    this.detail = 0.50,
    this.tone = 0.30,
    this.volumeDb = -12,
    this.lowerUnderNarration = true,
  });

  final String scene;
  final bool matchStory;
  final double bed, detail, tone;

  /// Master volume, -30 to 0 dB.
  final int volumeDb;
  final bool lowerUnderNarration;

  factory SoundscapeDefaults.of(JsonRecord r) {
    final mix = r.child('mix');
    double level(String k, double d) => mix.doubleOf(k, d).clamp(0.0, 1.0);
    return SoundscapeDefaults(
      scene: r.choice('scene', kSoundscapeScenes, 'off'),
      matchStory: r.boolOf('matchStory', true),
      bed: level('bed', 0.80),
      detail: level('detail', 0.50),
      tone: level('tone', 0.30),
      volumeDb: r.intOf('volumeDb', -12).clamp(-30, 0),
      lowerUnderNarration: r.boolOf('lowerUnderNarration', true),
    );
  }
}

class SoundscapeDefaultsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => 'mm.soundscape.defaults.';

  Future<void> setScene(String v) => put({'scene': kSoundscapeScenes.contains(v) ? v : 'off'});
  Future<void> setMatchStory(bool v) => put({'matchStory': v});
  Future<void> setLowerUnderNarration(bool v) => put({'lowerUnderNarration': v});
  Future<void> setVolumeDb(int v) => put({'volumeDb': v.clamp(-30, 0)});

  /// [layer] is `bed`, `detail` or `tone`; [v] is 0 to 1.
  Future<void> setMix(String layer, double v) {
    assert(const ['bed', 'detail', 'tone'].contains(layer));
    return put({'mix': {...state.child('mix').data, layer: v.clamp(0.0, 1.0)}});
  }
}

final soundscapeDefaultsRecordProvider = NotifierProvider<SoundscapeDefaultsNotifier, JsonRecord>(SoundscapeDefaultsNotifier.new, name: 'soundscapeDefaultsRecord');

final soundscapeDefaultsProvider = Provider<SoundscapeDefaults>((ref) => SoundscapeDefaults.of(ref.watch(soundscapeDefaultsRecordProvider)), name: 'soundscapeDefaults');
