/// The full player's column (glass 8.16.2, E): the artwork with its parallax, the speaking orb and its chip, the three title lines, the
/// scrubber, the transport, the three tiles and the sentence list; shared by the phone sheet, the 560 px desktop window and the novel
/// reader's Listen tab. States of glass 8.16.8 (failed, preparing, buffering, offline) live here too.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/skins/glass/listen/artwork_parallax.dart';
import 'package:manhwamaniacs/skins/glass/listen/cast_line.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_tiles.dart';
import 'package:manhwamaniacs/skins/glass/listen/post_play_card.dart';
import 'package:manhwamaniacs/skins/glass/listen/scrubber.dart';
import 'package:manhwamaniacs/skins/glass/listen/sentence_list.dart';
import 'package:manhwamaniacs/skins/glass/listen/speaking_orb.dart';
import 'package:manhwamaniacs/skins/glass/listen/transport.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Where the column lives.
enum PlayerForm {
  /// The phone and tablet sheet (T5 at medium, solid2 at large): text `onGlass`, the list on solid2.
  sheet,

  /// The 560 px desktop window (T5): the list `onGlass` at wght 420 / 700.
  window,

  /// The novel reader's right-panel Listen tab: artwork 200.
  tab,
}

/// "Needs a connection or saved audio" when there is neither.
const String kNeedsConnectionReason = 'Needs a connection or saved audio';

/// The artwork's side: `min(0.6 x width, 240)` on phones, also kept under 13 % of the height so the transport and the tiles stay inside
/// the `medium` detent (52 % of a phone), 200 on the desktop frame. (glass 8.16.2 lists them all at `medium`; a 240 px plate cannot
/// share 52 % of a phone with them.)
double playerArtSize(PlayerForm form, Size screen) => form == PlayerForm.sheet ? math.min(math.min(0.6 * screen.width, 240), math.max(96, 0.13 * screen.height)) : 200;

/// The cast line's inputs from the chapter's attribution and the server's voice order.
String playerCastLine({required GlassNarrator narrator, required NovelAttribution? attribution, required List<NovelVoice> voices}) {
  final counts = <({String voiceName, int characters})>[];
  if (attribution != null) {
    for (final v in voices) {
      final n = attribution.cast.where((m) => m.voiceId == v.voiceId).length;
      if (n > 0) counts.add((voiceName: v.name, characters: n));
    }
  }
  return castLine(narratorVoiceName: narrator.voice?.name, voicedCounts: counts);
}

class GlassPlayerColumn extends ConsumerStatefulWidget {
  const GlassPlayerColumn({super.key, this.form = PlayerForm.sheet});
  final PlayerForm form;

  @override
  ConsumerState<GlassPlayerColumn> createState() => _GlassPlayerColumnState();
}

class _GlassPlayerColumnState extends ConsumerState<GlassPlayerColumn> {
  late final StateController<int> _open = ref.read(glassPlayerOpenProvider.notifier);

  /// The Listen keys also work from the full player and the desktop window (glass 8.16.8): `p`, `[` `]`, Shift+`[` `]`, `<` `>`, `v`.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null && focus.findAncestorWidgetOfExactType<EditableText>() != null) return false;
    final narr = ref.read(narrationControllerProvider.notifier);
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.keyP) {
      unawaited(ref.read(glassNarrationActionsProvider).toggle());
    } else if (k == LogicalKeyboardKey.bracketLeft) {
      unawaited(shift ? narr.seekBy(const Duration(seconds: -15)) : narr.stepSentence(-1));
    } else if (k == LogicalKeyboardKey.bracketRight) {
      unawaited(shift ? narr.seekBy(const Duration(seconds: 15)) : narr.stepSentence(1));
    } else if (shift && (k == LogicalKeyboardKey.comma || k == LogicalKeyboardKey.period)) {
      unawaited(narr.setSpeed(ref.read(narrationControllerProvider).speed + (k == LogicalKeyboardKey.period ? 0.05 : -0.05)));
    } else if (k == LogicalKeyboardKey.keyV) {
      ref.read(glassNarrationActionsProvider).openSheet('cast');
    } else {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    final open = _open;
    Future<void>.microtask(() {
      try {
        open.state++;
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    final open = _open;
    Future<void>.microtask(() {
      try {
        open.state = open.state > 0 ? open.state - 1 : 0;
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    final onGlass = widget.form != PlayerForm.tab;
    if (t == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: GlassText('Nothing is being read aloud.', role: gt.typeCallout, onGlass: onGlass, textAlign: TextAlign.center)));
    }
    final narrator = ref.watch(glassNarratorProvider(t.key));
    final attribution = ref.watch(novelAttributionProvider(t.key)).valueOrNull;
    final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final saved = t.file != null || ref.watch(savedAudioStateProvider(t.key)) == SavedAudioState.saved;
    final reason = !online && !saved ? kNeedsConnectionReason : null;
    final screen = MediaQuery.sizeOf(context);
    final art = playerArtSize(widget.form, screen);
    final waiting = ref.watch(glassPostPlayProvider);
    final title = t.chapterTitle.isEmpty ? glassChapterWord(t) : t.chapterTitle;
    final failed = s.status == NarrationStatus.failed;
    final listForm = widget.form == PlayerForm.window;

    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: GlassText(title, role: gt.typeTitle2, onGlass: onGlass, maxLines: 2, overflow: TextOverflow.ellipsis, maxScale: 1.5)),
        GlassText(t.bookTitle, role: gt.typeFootnote, onGlass: onGlass, color: onGlass ? gt.colorOnGlass.withValues(alpha: 0.78) : gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
        GlassText(playerCastLine(narrator: narrator, attribution: attribution, voices: voices), role: gt.typeCaption1, onGlass: onGlass, color: onGlass ? gt.colorOnGlass.withValues(alpha: 0.78) : gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
        if (!online && saved) GlassText('Saved audio', role: gt.typeCaption1, wght: 600, onGlass: onGlass, maxLines: 1),
      ],
    );

    final compact = MediaQuery.textScalerOf(context).scale(1) >= 1.3 || screen.height < 700;
    final parts = <Widget>[
          Row(
            children: [
              GlassArtwork(sourceId: t.key.sourceId, seriesKey: t.key.seriesKey, size: art),
              const SizedBox(width: 16),
              const Expanded(child: Center(child: GlassSpeakingOrb())),
            ],
          ),
          const SizedBox(height: 10),
          titles,
          if (failed) _Failure(message: s.failure, owner: ref.watch(glassIsOwnerProvider), onGlass: onGlass, onRetry: () => unawaited(ref.read(narrationControllerProvider.notifier).retry())),
          const SizedBox(height: 4),
          const GlassScrubber(),
          GlassTransport(disabledReason: reason),
          const SizedBox(height: 8),
          const GlassPlayerTiles(),
          if (waiting != null) GlassPostPlayCard(key: ValueKey(waiting), onGlass: onGlass),
          const SizedBox(height: 8),
    ];
    // On a short screen or at large text the controls and the sentence list scroll together (the list keeps 240 px), so the
    // controls never overflow the sheet; otherwise the list fills what the controls leave.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: compact
          ? LayoutBuilder(builder: (context, c) => SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ...parts,
                  SizedBox(height: math.max(240.0, c.maxHeight.isFinite ? c.maxHeight * 0.45 : 240), child: GlassSentenceList(onGlass: listForm)),
                ],),
              ),)
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...parts, Expanded(child: GlassSentenceList(onGlass: listForm))]),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.owner, required this.onGlass, required this.onRetry});
  final String? message;
  final bool owner, onGlass;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final converting = (message ?? '').contains('audio_convert_failed');
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(child: GlassText(converting ? "This chapter's audio couldn't be prepared." : "Audio couldn't load", role: gt.typeCallout, onGlass: onGlass, color: gt.colorWarning, maxLines: 2, maxScale: 1.5)),
            const SizedBox(width: 8),
            GlassButton(label: converting ? (owner ? 'Render again' : 'Try again') : 'Retry', size: GlassButtonSize.small, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
