import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/features/novels/utils/voice_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// How many of the five meter squares [value] fills: the voice's rank among [all] (`expressiveness`
/// is a raw pitch spread with no fixed range), `ceil(5 x rank / n)` with rank 1..n.
int expressivenessBars(Iterable<double> all, double value) {
  final list = all.toList();
  if (list.isEmpty) return 0;
  final rank = list.where((v) => v <= value).length.clamp(1, list.length);
  return (5 * rank / list.length).ceil().clamp(1, 5);
}

/// The 80-300 Hz hairline ruler with a `spot` tick at the voice's pitch (semantics "Deeper" to
/// "Brighter").
class PitchScale extends StatelessWidget {
  const PitchScale({super.key, required this.pitchHz});
  final double pitchHz;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final t = ((pitchHz - 80) / 220).clamp(0.0, 1.0);
    return Semantics(
      label:
          'Pitch ${pitchHz.round()} hertz, on a scale from deeper to brighter',
      excludeSemantics: true,
      child: SizedBox(
        height: 12,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                      color: c.colorRule2, child: const SizedBox(height: 1),),),
              Positioned(
                  left: (box.maxWidth - 2) * t,
                  child: ColoredBox(
                      color: c.colorSpot,
                      child: const SizedBox(width: 2, height: 10),),),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five 6 x 6 squares, [filled] of them `ink.100`.
class ExpressivenessMeter extends StatelessWidget {
  const ExpressivenessMeter({super.key, required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      label: 'Expressiveness $filled of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: i < filled ? c.colorInk100 : null,
                      border: Border.all(
                          color: i < filled ? c.colorInk100 : c.colorRule2,
                          width: 0.5,),),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 40 px monogram circle filled with the pitch field, the initial in `ink.100`.
class VoiceMonogram extends StatelessWidget {
  const VoiceMonogram({super.key, required this.voice, this.size = 40});
  final NovelVoice voice;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final initial = voice.name.trim().isEmpty
        ? '?'
        : voice.name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: voiceMonogramField(voice.pitchHz),),
        child: CineRoleText(initial, c.typeTitle, color: c.colorInk100),
      ),
    );
  }
}

/// One voice of the cast list of 31 (cinematic 8.16.5): monogram, name in Bodoni Moda Italic 20,
/// the character line, the pitch scale, the expressiveness meter, `Hear` and `Cast`.
///
/// While the sample plays a highlighter band in `spot` at alpha 0.08 + 0.24 x RMS sits behind the
/// name (a static 0.20 under reduced motion; no bloom, no glow), a 2 px rule under the row runs
/// with the clip, and the voice's transcript appears under it in a live region.
class VoiceRow extends StatelessWidget {
  const VoiceRow({
    super.key,
    required this.voice,
    required this.bars,
    required this.sample,
    required this.pulse,
    required this.onHear,
    this.selected = false,
    this.onCast,
    this.onDetails,
  });

  final NovelVoice voice;
  final int bars;
  final SampleState sample;
  final ValueListenable<double> pulse;
  final VoidCallback onHear;

  /// The row's voice is the one cast now: the action reads `CAST`, filled.
  final bool selected;

  /// Null in browse mode (Settings): no `Cast`.
  final VoidCallback? onCast;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final id = voice.voiceId;
    final playing = sample.isPlaying(id);
    final fetching = sample.isFetching(id);
    final reduced = CineMotion.reduced(context);
    final name = CineLit(voice.name, CineFace.bodoni, 20, 26,
        italic: true,
        color: c.colorInk100,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,);
    final nameWidget = playing
        ? ValueListenableBuilder<double>(
            valueListenable: pulse,
            builder: (context, v, child) => DecoratedBox(
              key: const Key('voice-pulse-band'),
              decoration: BoxDecoration(
                  color: c.colorSpot
                      .withValues(alpha: pulseAlpha(v, reduced: reduced)),),
              child: child,
            ),
            child: name,
          )
        : name;
    final actions = <Widget>[
      ListenAction(
        label: playing ? 'Stop' : 'Hear',
        busy: fetching,
        semanticLabel:
            playing ? 'Stop the sample of ${voice.name}' : 'Hear ${voice.name}',
        onTap: onHear,
      ),
      if (onCast != null)
        ListenAction(
            label: selected ? 'CAST' : 'Cast',
            filled: selected,
            semanticLabel:
                selected ? '${voice.name} is cast' : 'Cast ${voice.name}',
            onTap: onCast,),
      if (onDetails != null)
        Semantics(
          button: true,
          label: 'Details of ${voice.name}',
          excludeSemantics: true,
          onTap: onDetails,
          child: GestureDetector(
            onTap: onDetails,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
                width: cineHitMin(context),
                height: cineHitMin(context),
                child: Icon(Icons.more_horiz, size: 18, color: c.colorInk60),),
          ),
        ),
    ];
    Widget scales() => Row(
          children: [
            Expanded(child: PitchScale(pitchHz: voice.pitchHz)),
            SizedBox(width: c.space3),
            ExpressivenessMeter(filled: bars),
          ],
        );
    return Semantics(
      container: true,
      label: '${voice.name}, ${voice.character}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: LayoutBuilder(
          builder: (context, box) {
            // Phones: the name and scales on top, the actions on their own line. Wider rows keep
            // everything on one line.
            final narrow = box.maxWidth < 460;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                nameWidget,
                if (voice.character.isNotEmpty)
                  CineRoleText(voice.character, c.typeCaption,
                      color: c.colorInk60,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,),
                SizedBox(height: c.space1),
                scales(),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: c.space2),
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              VoiceMonogram(voice: voice),
                              SizedBox(width: c.space3),
                              Expanded(child: info),
                            ],),
                            SizedBox(height: c.space2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (final (i, a) in actions.indexed) ...[
                                  if (i > 0) SizedBox(width: c.space2),
                                  a,
                                ],
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            VoiceMonogram(voice: voice),
                            SizedBox(width: c.space3),
                            Expanded(child: info),
                            SizedBox(width: c.space2),
                            for (final (i, a) in actions.indexed) ...[
                              if (i > 0) SizedBox(width: c.space2),
                              a,
                            ],
                          ],
                        ),
                ),
                if (playing || fetching)
                  SizedBox(
                    height: 2,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                          math.max(0.0, math.min(1.0, sample.progress)),
                      child: ColoredBox(
                          key: const Key('voice-progress-rule'),
                          color: c.colorSpot,),
                    ),
                  )
                else
                  ColoredBox(
                      color: c.colorRule1, child: const SizedBox(height: 1),),
                if (playing && voice.transcript.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: EdgeInsets.only(top: c.space1, bottom: c.space2),
                      child: CineRoleText(voice.transcript, c.typeCaption,
                          color: c.colorInk60,),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
