import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audio_save_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `14 MIN` for the audio's length, rounded up.
String listenMinutes(int totalMs) => '${(totalMs / 60000).ceil().clamp(1, 9999)} MIN';

/// What the chapter opener shows under its facts line (cinematic 8.16.1): the `Listen │ 14 MIN`
/// split button with a small check when the audio is saved on this device, and the save-state row
/// when a downloads scope exists; for a chapter with no audio nothing, except that the owner sees
/// `NOT NARRATED` with a quiet `Narrate this chapter` (priority 9).
class ListenOpener extends ConsumerWidget {
  const ListenOpener({super.key, required this.chapter, required this.onListen, this.chapterNumber, this.title, this.seriesTitle, this.fixedHeight});

  final NovelChapterKey chapter;
  final VoidCallback onListen;
  final double? chapterNumber;
  final String? title, seriesTitle;

  /// Paged layout: the opener reserves this height on the first page (the paginator counts it),
  /// so the row is fixed and the save state lives in the mini player's overflow only.
  final double? fixedHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inner = _build(context, ref);
    final h = fixedHeight;
    return h == null ? inner : SizedBox(height: h, child: Align(alignment: Alignment.centerLeft, child: inner));
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final playable = ref.watch(playableNovelAudioProvider(chapter));
    final audio = playable.valueOrNull;
    if (audio != null) {
      final saved = ref.watch(savedAudioStateProvider(chapter)) == SavedAudioState.saved;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CineButton(
                key: const Key('opener-listen'),
                label: 'Listen',
                folio: listenMinutes(audio.audio.totalMs),
                variant: CineButtonVariant.split,
                size: CineButtonSize.sm,
                icon: CineIconRole.listen,
                onPressed: () {
                  cineFeedback(context, HapticEvent.listenToggle);
                  onListen();
                },
              ),
              if (saved) Padding(padding: EdgeInsets.only(left: c.space2), child: Semantics(label: 'Audio saved on this device', child: CineGlyphIcon(CineGlyph.check, size: 16, color: c.colorInk60))),
            ],
          ),
          if (fixedHeight == null) AudioSaveRow(chapter: chapter, chapterNumber: chapterNumber, title: title, seriesTitle: seriesTitle, compact: true),
        ],
      );
    }
    if (playable.isLoading) return const SizedBox.shrink();
    // Offline, a chapter that is narrated on the server but not saved here cannot be heard.
    final narrated = ref.watch(seriesAudioProvider((sourceId: chapter.sourceId, seriesKey: chapter.seriesKey))).valueOrNull?.rendered.contains(chapter.chapterKey) ?? false;
    if (narrated && !isOnline(ref)) {
      return CineRoleText("This chapter's audio isn't saved on this device.", context.cine.typeCaption, color: context.cine.colorInk60, key: const Key('opener-offline-no-audio'));
    }
    return _NotNarrated(chapter: chapter);
  }
}

class _NotNarrated extends ConsumerStatefulWidget {
  const _NotNarrated({required this.chapter});
  final NovelChapterKey chapter;

  @override
  ConsumerState<_NotNarrated> createState() => _NotNarratedState();
}

class _NotNarratedState extends ConsumerState<_NotNarrated> {
  bool _sent = false;

  Future<void> _narrate() async {
    final r = await ref.read(novelCastingWriterProvider).requestRender(widget.chapter, [widget.chapter.chapterKey], priority: 9);
    if (!mounted) return;
    final toasts = ref.read(cineToastsProvider.notifier);
    if (r.isErr) {
      toasts.error(r.error.userMessage);
    } else {
      setState(() => _sent = true);
      cineFeedback(context, HapticEvent.tapSecondary);
      toasts.info('Queued for narration.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isOwnerProvider)) return const SizedBox.shrink();
    final c = context.cine;
    final detail = ref.watch(seriesAudioDetailProvider((sourceId: widget.chapter.sourceId, seriesKey: widget.chapter.seriesKey))).valueOrNull;
    final canRender = detail?.canRender ?? true;
    return Column(
      key: const Key('opener-not-narrated'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CineRoleText('NOT NARRATED', c.typeKicker, color: c.colorInk60),
        CineButton(
          label: _sent ? 'Queued' : 'Narrate this chapter',
          variant: CineButtonVariant.quiet,
          size: CineButtonSize.sm,
          disabledReason: canRender ? null : "Narration of new chapters isn't available right now.",
          onPressed: _sent || !canRender ? null : () => unawaited(_narrate()),
        ),
      ],
    );
  }
}

/// The voices line under the text, right-aligned (cinematic 8.15.2): `VOICES IN THIS CHAPTER (5)`
/// in `type.kicker`, a button that opens the cast sheet. Present when the attribution has a cast
/// or a narrator, and only then.
class VoicesLine extends ConsumerWidget {
  const VoicesLine({super.key, required this.chapter, required this.muted, required this.onOpen});

  final NovelChapterKey chapter;
  final Color muted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(novelAttributionProvider(chapter)).valueOrNull;
    if (a == null || !(a.cast.isNotEmpty || a.narratorVoiceId != null)) return const SizedBox.shrink();
    final c = context.cine;
    final count = a.cast.length + (a.narratorVoiceId != null ? 1 : 0);
    final label = 'VOICES IN THIS CHAPTER ($count)';
    return Align(
      alignment: Alignment.centerRight,
      child: CinePressable(
        onTap: onOpen,
        builder: (context, st) => Semantics(
          container: true,
          button: true,
          label: 'Voices in this chapter, $count',
          excludeSemantics: true,
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: c.space2),
            child: CineRoleText(label, c.typeKicker, color: muted),
          ),
        ),
      ),
    );
  }
}

/// What the paged layout reserves under the opener's facts line for the Listen row (the 20 px gap
/// plus a 56 px row), whether or not the chapter has audio, so the pagination never moves when the
/// audio lookup answers.
const double kListenOpenerReserve = 76;
