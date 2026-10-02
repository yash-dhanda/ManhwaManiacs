/// The speaking orb (glass 8.16.2, E6): a 72 px twin sphere tinted with the narrator's [voiceHue] that breathes with the narration's
/// level (`1 + 0.10 x level` at 30 fps, the Speaking orb pulse) and takes each speaker's `spk` hue over 300 ms when a character's line
/// plays. A `fill2` chip under it names the voice. Reduced motion: the orb is static; the colour change stays.
library;

import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_level.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/features/novels/utils/voice_pulse.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart' show speakerHue;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The chapter's level envelope: decoded once in the background after the player opens ([NarrationLevel], A4). Null until ready.
final glassNarrationLevelProvider = FutureProvider.autoDispose<NarrationLevel?>((ref) async {
  final t = ref.watch(narrationControllerProvider.select((s) => s.target));
  if (t == null) return null;
  final file = t.file;
  return buildNarrationLevel(ref, (key: t.key, totalMs: t.audio.totalMs, segments: t.audio.segments, savedOgg: file == null ? null : File(file)));
}, name: 'glassNarrationLevel',);

/// Who is speaking at [positionMs]: the speaker's name (null for narration), its slot and the voice that reads it.
({String? speaker, int? slot, String? voiceId}) speakerAt(NarrationState s, NovelAttribution? attribution, int positionMs) {
  final audio = s.target?.audio;
  if (audio == null) return (speaker: null, slot: null, voiceId: null);
  final i = audio.segmentAt(positionMs);
  if (i < 0) return (speaker: null, slot: null, voiceId: null);
  final seg = audio.segments[i];
  final name = seg.isSpeech && (seg.speaker?.isNotEmpty ?? false) ? seg.speaker : null;
  final slot = name == null || attribution == null ? null : speakerSlots(attribution)[name]?.slot;
  return (speaker: name, slot: slot, voiceId: seg.voice);
}

/// "Narrator · Aurora" or "Mira · voiced by Ada".
String speakerChipText({required String? speaker, required String narratorName, String? voiceName}) =>
    speaker == null ? 'Narrator · $narratorName' : (voiceName == null || voiceName.isEmpty ? speaker : '$speaker · voiced by $voiceName');

class GlassSpeakingOrb extends ConsumerStatefulWidget {
  const GlassSpeakingOrb({super.key, this.size = 72});
  final double size;

  @override
  ConsumerState<GlassSpeakingOrb> createState() => _GlassSpeakingOrbState();
}

class _GlassSpeakingOrbState extends ConsumerState<GlassSpeakingOrb> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _hue = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  final VoicePulse _pulse = VoicePulse();
  final ValueNotifier<double> _scale = ValueNotifier(1);
  Duration _last = Duration.zero;
  Color _from = const Color(0xFF8F7EFF), _to = const Color(0xFF8F7EFF);
  String? _speaker;
  DateTime _announced = DateTime.fromMillisecondsSinceEpoch(0);
  late final NarrationController _narr = ref.read(narrationControllerProvider.notifier);
  NarrationLevel? _level;

  /// The pulse and the speaker hue run only while narration plays: an always-on ticker kept the full player (and every glass
  /// pass under it) rendering at the display rate while paused.
  void _syncTicker(bool run) {
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _scale.value = 1;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hue.dispose();
    _scale.dispose();
    super.dispose();
  }

  Color get _shown => Color.lerp(_from, _to, Curves.easeOut.transform(_hue.value))!;

  void _retarget(Color c) {
    if (c == _to) return;
    _from = _shown;
    _to = c;
    _hue.forward(from: 0);
  }

  void _onTick(Duration elapsed) {
    final s = ref.read(narrationControllerProvider);
    final t = s.target;
    if (t == null) return;
    final attribution = ref.read(novelAttributionProvider(t.key)).valueOrNull;
    final narrator = ref.read(glassNarratorProvider(t.key));
    final who = speakerAt(s, attribution, _narr.position.value);
    _retarget(who.slot == null ? narrator.hue : speakerHue(who.slot!));
    if (who.speaker != _speaker) {
      _speaker = who.speaker;
      final now = DateTime.now();
      if (who.speaker != null && now.difference(_announced) > const Duration(seconds: 5)) {
        _announced = now;
        listenAnnounce(context, 'Now speaking: ${who.speaker}');
      }
    }
    final dt = elapsed - _last;
    if (dt < const Duration(milliseconds: 33)) return;
    _last = elapsed;
    if (ref.read(glassReducedProvider)) {
      _scale.value = 1;
      return;
    }
    final lv = _level?.levelAt(Duration(milliseconds: _narr.position.value)) ?? 0;
    final v = _pulse.step(s.isPlaying ? lv : 0, dt);
    _scale.value = 1 + 0.10 * v;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    _syncTicker(t != null && s.isPlaying);
    _level = ref.watch(glassNarrationLevelProvider).valueOrNull;
    if (t == null) return SizedBox(width: widget.size, height: widget.size);
    final narrator = ref.watch(glassNarratorProvider(t.key));
    final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final attribution = ref.watch(novelAttributionProvider(t.key)).valueOrNull;
    final light = ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest;
    final who = speakerAt(s, attribution, _narr.position.value);
    final voiceName = voices.where((v) => v.voiceId == who.voiceId).firstOrNull?.name;
    final chip = speakerChipText(speaker: who.speaker, narratorName: narrator.name, voiceName: voiceName);
    final d = lightDirection(light);
    return Semantics(
      container: true,
      label: who.speaker == null ? 'Narrator, ${narrator.name}' : 'Now speaking: ${who.speaker}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scale, _hue]),
            builder: (context, _) {
              final c = _shown;
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gt.colorFill2,
                    gradient: RadialGradient(center: Alignment(-d.dx * 0.5, -d.dy * 0.5), radius: 0.95, colors: [c.withValues(alpha: 0.95), c.withValues(alpha: 0.55), c.withValues(alpha: 0.25)], stops: const [0, 0.55, 1]),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 24)],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.capsule().border(const Size(100, 24))),
            child: GlassText(chip, role: gt.typeCaption1, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
          ),
        ],
      ),
    );
  }
}
