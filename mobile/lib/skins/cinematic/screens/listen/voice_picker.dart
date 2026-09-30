import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/voice_row.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum VoicePickerMode {
  /// Casting a character or the narrator on a book.
  cast,

  /// Settings: browse the voices and hear them, no casting.
  browse,
}

/// What a voice is being picked for.
enum VoiceSubject { character, narrator }

/// "The cast list of 31" (cinematic 8.16.5): the voice picker.
///
/// Opened from a cast row (filtered to the character's gender) or from the narrator row, and by
/// Settings -> Listen -> Voices in [VoicePickerMode.browse]. Filters and their counts come from
/// the server (`GET /novels/voices`), never a hard-coded 18 and 13. `Hear` plays the sample
/// through [VoiceSamplePlayer]; `Cast` posts the voice and fires `voice.assign`.
class VoicePicker extends ConsumerStatefulWidget {
  const VoicePicker({
    super.key,
    this.chapter,
    this.subjectName,
    this.subject = VoiceSubject.character,
    this.mode = VoicePickerMode.cast,
    this.gender,
    this.currentVoiceId,
    this.onCast,
  });

  /// The book (and chapter) the cast belongs to; null in browse mode.
  final NovelChapterKey? chapter;

  /// The character's name (`A VOICE FOR KIM DOKJA`).
  final String? subjectName;
  final VoiceSubject subject;
  final VoicePickerMode mode;

  /// `male` / `female` filters the list to the character's gender; anything else shows all.
  final String? gender;

  /// The voice the subject has now (`CAST`); null is Automatic (or the book default).
  final String? currentVoiceId;

  /// Called after a voice was saved (`null` for Automatic / Book default).
  final ValueChanged<String?>? onCast;

  @override
  ConsumerState<VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends ConsumerState<VoicePicker> {
  late String _filter = switch (widget.gender) { 'male' => 'male', 'female' => 'female', _ => 'all' };
  String _q = '';
  late String? _castId = widget.currentVoiceId;
  bool _saving = false;

  String get _kicker => widget.mode == VoicePickerMode.browse
      ? 'THE VOICES'
      : widget.subject == VoiceSubject.narrator
          ? 'A VOICE FOR THE NARRATOR'
          : 'A VOICE FOR ${(widget.subjectName ?? '').toUpperCase()}';

  Future<void> _cast(String? voiceId) async {
    final chapter = widget.chapter;
    if (chapter == null || _saving) return;
    setState(() => _saving = true);
    final writer = ref.read(novelVoiceWriterProvider);
    final error = widget.subject == VoiceSubject.narrator
        ? await writer.setNarrator(chapter, voiceId)
        : await writer.setCharacter(chapter, widget.subjectName ?? '', voiceId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ref.read(cineToastsProvider.notifier).error("That voice couldn't be saved. ${error.userMessage}");
      return;
    }
    cineFeedback(context, HapticEvent.voiceAssign, sound: SoundEvent.voiceAssign);
    setState(() => _castId = voiceId);
    widget.onCast?.call(voiceId);
  }

  bool _matches(NovelVoice v, Set<String> inUse) {
    if (_filter == 'female' && v.gender != 'female') return false;
    if (_filter == 'male' && v.gender != 'male') return false;
    if (_filter == 'inuse' && !inUse.contains(v.voiceId)) return false;
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();
    return v.name.toLowerCase().contains(q) || v.character.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final voices = ref.watch(novelVoicesProvider);
    final attribution = widget.chapter == null ? null : ref.watch(novelAttributionProvider(widget.chapter!)).valueOrNull;
    final sample = ref.watch(voiceSamplePlayerProvider);
    final player = ref.read(voiceSamplePlayerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).shortestSide >= 600;
    return voices.when(
      loading: () => Padding(
        padding: EdgeInsets.all(c.space6),
        child: CineRoleText('LOADING', c.typeKicker, color: c.colorInk60),
      ),
      error: (_, __) => Padding(padding: EdgeInsets.all(c.space6), child: CineRoleText("The voices didn't load.", c.typeUi)),
      data: (all) {
        if (all.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(c.space6),
            child: CineRoleText("No voices are installed on the server, so characters can't be cast from here yet.", c.typeUi, color: c.colorInk60),
          );
        }
        final inUse = <String>{
          if (attribution?.narratorVoiceId != null) attribution!.narratorVoiceId!,
          for (final m in attribution?.cast ?? const <NovelCastMember>[])
            if (m.voiceId != null) m.voiceId!,
        };
        final female = all.where((v) => v.gender == 'female').length;
        final male = all.where((v) => v.gender == 'male').length;
        final shown = [for (final v in all) if (_matches(v, inUse)) v];
        final expr = [for (final v in all) v.expressiveness];
        Widget row(NovelVoice v) => VoiceRow(
              key: ValueKey(v.voiceId),
              voice: v,
              bars: expressivenessBars(expr, v.expressiveness),
              sample: sample,
              pulse: player.pulse,
              selected: _castId == v.voiceId,
              onHear: () => unawaited(player.toggle(v.voiceId)),
              onCast: widget.mode == VoicePickerMode.cast ? () => unawaited(_cast(v.voiceId)) : null,
              onDetails: () => _details(context, v),
            );
        List<Widget> section(String label, List<NovelVoice> list) => [
              if (list.isNotEmpty) Padding(padding: EdgeInsets.only(top: c.space4, bottom: c.space1), child: CineRoleText(label, c.typeKicker, color: c.colorInk60)),
              for (final v in list) row(v),
            ];
        final males = [for (final v in shown) if (v.gender == 'male') v];
        final females = [for (final v in shown) if (v.gender == 'female') v];
        final others = [for (final v in shown) if (v.gender != 'male' && v.gender != 'female') v];
        final automatic = widget.mode == VoicePickerMode.cast
            ? _AutomaticRow(
                label: widget.subject == VoiceSubject.narrator ? 'Book default' : 'Automatic',
                caption: widget.subject == VoiceSubject.narrator ? 'The narrator is picked for the whole book' : 'Assigned by gender and speaking order',
                selected: _castId == null,
                onTap: () => unawaited(_cast(null)),
              )
            : null;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: c.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.mode != VoicePickerMode.browse) ...[
                CineRoleText(_kicker, c.typeKicker, color: c.colorInk60),
                SizedBox(height: c.space2),
              ],
              CineSlugLines(
                items: [
                  CineSlug('all', 'ALL', count: all.length),
                  CineSlug('female', 'FEMALE', count: female),
                  CineSlug('male', 'MALE', count: male),
                  const CineSlug('inuse', 'IN USE'),
                ],
                selected: {_filter},
                onChanged: (v) => setState(() => _filter = v),
              ),
              SizedBox(height: c.space2),
              CineSearchField(semanticLabel: 'Search voices', placeholder: 'Search voices', variant: CineSearchVariant.compact, onChanged: (v) => setState(() => _q = v)),
              if (automatic != null) automatic,
              if (shown.isEmpty)
                Padding(padding: EdgeInsets.symmetric(vertical: c.space6), child: CineRoleText('No voice matches.', c.typeUi, color: c.colorInk60))
              else if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(key: const Key('voices-male'), child: Column(children: section('MALE', males))),
                    SizedBox(width: c.space6),
                    Expanded(key: const Key('voices-female'), child: Column(children: section('FEMALE', females))),
                  ],
                )
              else ...[
                ...section('FEMALE', females),
                ...section('MALE', males),
                ...section('OTHER', others),
              ],
              Padding(
                padding: EdgeInsets.symmetric(vertical: c.space4),
                child: CineRoleText("Chapters already rendered keep the voice they were made with until they're rendered again.", c.typeCaption, color: c.colorInk60),
              ),
            ],
          ),
        );
      },
    );
  }

  void _details(BuildContext context, NovelVoice v) {
    final c = context.cine;
    unawaited(showCineDialog<void>(
      context,
      builder: (dialogContext) => CineDialog(
        title: v.name,
        onCancel: () => Navigator.of(dialogContext).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineRoleText('LICENCE', c.typeKicker, color: c.colorInk60),
            CineRoleText(v.license.isEmpty ? 'Not stated' : v.license, c.typeUi),
            SizedBox(height: c.space2),
            CineRoleText('ATTRIBUTION', c.typeKicker, color: c.colorInk60),
            CineRoleText(v.attribution.isEmpty ? 'Not stated' : v.attribution, c.typeUi),
          ],
        ),
        actions: [CineButton(label: 'Close', variant: CineButtonVariant.quiet, onPressed: () => Navigator.of(dialogContext).pop())],
      ),
    ),);
  }
}

class _AutomaticRow extends StatelessWidget {
  const _AutomaticRow({required this.label, required this.caption, required this.selected, required this.onTap});
  final String label, caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.symmetric(vertical: c.space2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.colorRule1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CineLit(label, CineFace.bodoni, 20, 26, italic: true, color: c.colorInk100),
                CineRoleText(caption, c.typeCaption, color: c.colorInk60),
              ],
            ),
          ),
          ListenAction(label: selected ? 'CAST' : 'Cast', filled: selected, semanticLabel: '$label voice', onTap: onTap),
        ],
      ),
    );
  }
}

/// Opens the picker as a sheet (from a cast row, the narrator row or the voices button).
Future<void> showVoicePicker(
  BuildContext context, {
  required NovelChapterKey chapter,
  required CineStockColors? stock,
  String? subjectName,
  VoiceSubject subject = VoiceSubject.character,
  String? gender,
  String? currentVoiceId,
  ValueChanged<String?>? onCast,
}) =>
    showListenSheet<void>(
      context,
      kicker: 'VOICES',
      title: 'Voices',
      stock: stock,
      builder: (_) => VoicePicker(
        chapter: chapter,
        subjectName: subjectName,
        subject: subject,
        gender: gender,
        currentVoiceId: currentVoiceId,
        onCast: onCast,
      ),
    );

/// Settings -> Listen -> Voices: the picker in browse mode (hear every voice, no casting).
Future<void> showVoiceBrowser(BuildContext context) => showListenSheet<void>(
      context,
      kicker: 'THE VOICES',
      title: 'The voices',
      builder: (_) => const VoicePicker(mode: VoicePickerMode.browse),
    );
