/// One voice of the orbit (glass 8.16.4, F2): a 160 x 220 `surface1` slab, radius 26, padding 12: a 72 px orb filled with the voice's
/// [voiceHue] holding its initial in black (it pulses with the sample's RMS while it plays), the name in `title3`, "Female · warm"
/// in `footnote`, a pitch scale ("deeper" to "brighter"), the five-dot expressiveness meter, the "In use for Kade" / "Narrator" tag, the
/// clip's duration over 3 s, and the licence in `caption2`. A 44 px play button when previews do not auto-play, always a visible
/// `pause` stop while it plays.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/orbit_math.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_hue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "0:07" for a clip longer than 3 s, else null.
String? voiceDuration(double seconds) {
  if (seconds <= 3) return null;
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "Female · warm", "Male" when the voice has no character words.
String voiceSubtitle(NovelVoice v) {
  final g = switch (v.gender) { 'female' => 'Female', 'male' => 'Male', _ => 'Unknown' };
  return v.character.isEmpty ? g : '$g · ${v.character}';
}

/// The card's semantics label: "Aurora, 3 of 31, female, warm, in use for Kade".
String voiceCardLabel(NovelVoice v, int position, int total, {String? tag}) =>
    '${v.name}, $position of $total, ${v.gender}${v.character.isEmpty ? '' : ', ${v.character}'}${tag == null ? '' : ', ${tag.toLowerCase()}'}';

class GlassVoiceCard extends ConsumerWidget {
  const GlassVoiceCard({
    super.key,
    required this.voice,
    required this.position,
    required this.total,
    required this.dots,
    required this.sample,
    required this.autoPlay,
    required this.onPlay,
    required this.onStop,
    this.tag,
    this.selected = false,
  });

  final NovelVoice voice;
  final int position, total, dots;

  /// The sample player's state for this voice (idle when another voice plays).
  final SampleState sample;

  /// Previews auto-play: the play button is then hidden until the sample plays (the stop button always shows).
  final bool autoPlay;
  final VoidCallback onPlay, onStop;
  final String? tag;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hue = voiceHue(voice.pitchHz);
    final playing = sample.isPlaying(voice.voiceId);
    final fetching = sample.isFetching(voice.voiceId);
    final failed = sample.voiceId == voice.voiceId && sample.failed;
    final pulse = ref.read(voiceSamplePlayerProvider.notifier).pulse;
    final dur = voiceDuration(voice.seconds);
    return Semantics(
      container: true,
      label: voiceCardLabel(voice, position, total, tag: tag),
      selected: selected,
      child: Container(
        width: kOrbitCardWidth,
        height: kOrbitCardHeight,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(color: gt.colorSurface1, shape: const GlassShape.superellipse(26).border(const Size(kOrbitCardWidth, kOrbitCardHeight))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: pulse,
                  builder: (context, v, _) => Transform.scale(
                    scale: playing ? 1 + 0.10 * v : 1,
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(center: const Alignment(-0.4, -0.5), radius: 0.95, colors: [hue, hue.withValues(alpha: 0.75)]),
                        boxShadow: playing ? [BoxShadow(color: hue.withValues(alpha: 0.4), blurRadius: 20)] : null,
                      ),
                      child: ExcludeSemantics(child: Text(voice.name.isEmpty ? '?' : voice.name.characters.first.toUpperCase(), style: roleStyle(context, gt.typeTitle2, wght: 700, maxScale: 1).copyWith(color: const Color(0xFF000000)), textScaler: TextScaler.noScaling)),
                    ),
                  ),
                ),
                const Spacer(),
                if (playing || (!autoPlay) || fetching)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: GlassPressable(
                      material: GlassMaterial.content,
                      sink: 0.92,
                      shape: const GlassShape.circle(),
                      minHit: false,
                      onTap: playing || fetching ? onStop : onPlay,
                      semanticsLabel: playing || fetching ? 'Stop preview of ${voice.name}' : 'Play a preview of ${voice.name}',
                      builder: (context, info) => Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorFill2),
                          child: fetching ? const Center(child: GlassSpinner()) : Icon(playing ? PhosphorFill.pause : PhosphorFill.play, size: 18, color: gt.colorLabel1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            GlassText(voice.name, role: gt.typeTitle3, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.3),
            GlassText(voiceSubtitle(voice), role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.3),
            if (dur != null) GlassText(dur, role: gt.typeMono, size: 11, color: gt.colorLabel3, maxLines: 1),
            const SizedBox(height: 6),
            _PitchScale(position: pitchPosition(voice.pitchHz), hue: hue),
            const SizedBox(height: 6),
            Row(children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(right: 4), child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: i < dots ? gt.colorLabel2 : gt.colorFill1)))]),
            const Spacer(),
            if (failed)
              GlassText('No preview available', role: gt.typeCaption1, color: gt.colorWarning, maxLines: 1)
            else if (tag != null)
              GlassText(tag!, role: gt.typeCaption1, wght: 600, color: gt.colorIris300, maxLines: 1, overflow: TextOverflow.ellipsis)
            else if (voice.license.isNotEmpty || voice.attribution.isNotEmpty)
              GlassText([voice.license, voice.attribution].where((e) => e.isNotEmpty).join(' · '), role: gt.typeCaption2, color: gt.colorLabel3, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PitchScale extends StatelessWidget {
  const _PitchScale({required this.position, required this.hue});
  final double position;
  final Color hue;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Pitch, ${(position * 100).round()} percent from deeper to brighter',
        excludeSemantics: true,
        child: SizedBox(
          height: 10,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 0, right: 0, top: 4, height: 2, child: DecoratedBox(decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(1)))),
                Positioned(left: (c.maxWidth - 8) * position, top: 1, width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: hue, shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
      );
}
