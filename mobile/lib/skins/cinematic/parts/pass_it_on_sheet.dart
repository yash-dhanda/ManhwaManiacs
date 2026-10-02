import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart' show CinePressable;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart' show CineLeaderDial;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart' show CineFieldUnderline;
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Recommend to... ("Pass it on", cinematic 9.3.4): a content-fit sheet with the recipients who can
/// receive the series, a note of up to 140 characters and `Send`. Resolves true once a letter went.
Future<bool> showPassItOnSheet(
  BuildContext context, {
  required String sourceId,
  required String seriesKey,
  required String title,
  String? coverUrl,
  int? preselectProfileId,
}) async =>
    await showCineSheet<bool>(
      context,
      kicker: 'PASS IT ON',
      title: 'Recommend',
      builder: (ctx) => Material(type: MaterialType.transparency, child: PassItOnBody(sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: coverUrl, preselectProfileId: preselectProfileId)),
    ) ??
    false;

/// The sheet's body (public so tests and the gallery can mount it).
class PassItOnBody extends ConsumerStatefulWidget {
  const PassItOnBody({super.key, required this.sourceId, required this.seriesKey, required this.title, this.coverUrl, this.preselectProfileId});
  final String sourceId, seriesKey, title;
  final String? coverUrl;
  final int? preselectProfileId;

  @override
  ConsumerState<PassItOnBody> createState() => _PassItOnBodyState();
}

class _PassItOnBodyState extends ConsumerState<PassItOnBody> {
  final _note = TextEditingController();
  final _noteFocus = FocusNode();
  final Set<int> _picked = {};
  final Set<int> _gone = {};
  bool _sending = false, _seeded = false;

  CircleSeriesKey get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  @override
  void initState() {
    super.initState();
    _noteFocus.addListener(() => setState(() {}));
    if (widget.preselectProfileId != null) _picked.add(widget.preselectProfileId!);
  }

  @override
  void dispose() {
    _note.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _send(List<CircleMember> recipients) async {
    setState(() => _sending = true);
    final toasts = ref.read(cineToastsProvider.notifier);
    final ids = [for (final m in recipients) if (_picked.contains(m.profileId)) m.profileId];
    final names = {for (final m in recipients) m.profileId: m.name};
    final err = await ref.read(circleActionsProvider).sendLetter(toProfileIds: ids, sourceId: widget.sourceId, seriesKey: widget.seriesKey, note: _note.text);
    if (!mounted) return;
    if (err == null) {
      cineFeedback(context, HapticEvent.recommendSend, sound: SoundEvent.recommendSend);
      toasts.info(sendToast([for (final id in ids) names[id] ?? '']));
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _sending = false);
    if (err is ApiError && err.code == 'recipient_unavailable') {
      final raw = err.details is Map ? (err.details! as Map)['profile_ids'] : null;
      final bad = <int>{for (final e in (raw as List? ?? const [])) (e as num).toInt()};
      setState(() {
        _picked.removeAll(bad);
        _gone.addAll(bad);
      });
      final who = [for (final id in bad) names[id] ?? 'They'];
      toasts.error(who.isEmpty ? "They aren't taking recommendations any more." : "${who.length == 1 ? who.first : who.join(' and ')} ${who.length == 1 ? "isn't" : "aren't"} taking recommendations any more.");
      return;
    }
    final who = sendToast([for (final id in ids) names[id] ?? '']).replaceFirst('Sent to ', '').replaceAll('.', '');
    toasts.error("Couldn't send to $who. Try again.");
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(recipientsProvider(_key));
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final base = ref.watch(apiBaseUrlProvider);
    final all = async.valueOrNull;
    final recipients = [for (final m in all ?? const <CircleMember>[]) if (!_gone.contains(m.profileId)) m];
    if (!_seeded && all != null) {
      _seeded = true;
      _picked.removeWhere((id) => !recipients.any((m) => m.profileId == id));
    }
    final dup = <String>{};
    final seen = <String>{};
    for (final m in recipients) {
      if (!seen.add(m.name)) dup.add(m.name);
    }
    final canSend = online && !_sending && _picked.isNotEmpty && recipients.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(width: 48, height: 72, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: historyCoverUrl(base, widget.coverUrl), title: widget.title))),
          SizedBox(width: c.space3),
          Expanded(child: CineRoleText(widget.title, c.typeTitle, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],),
        SizedBox(height: c.space4),
        if (async.isLoading && all == null)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CineLeaderDial(size: 24)))
        else if (async.hasError && all == null)
          CineRoleText("Couldn't load your circle.", c.typeCaption, color: c.colorProof)
        else if (recipients.isEmpty)
          CineRoleText('Nobody is taking recommendations right now.', c.typeBody, color: c.colorInk60)
        else
          Wrap(spacing: c.space4, runSpacing: c.space3, children: [
            for (final m in recipients)
              Semantics(
                button: true,
                toggled: _picked.contains(m.profileId),
                label: dup.contains(m.name) && m.username != null ? '${m.name} (@${m.username})' : m.name,
                excludeSemantics: true,
                onTap: () => setState(() => _picked.contains(m.profileId) ? _picked.remove(m.profileId) : _picked.add(m.profileId)),
                child: CinePressable(
                  key: ValueKey('recipient-${m.profileId}'),
                  hit: false,
                  onTap: () => setState(() => _picked.contains(m.profileId) ? _picked.remove(m.profileId) : _picked.add(m.profileId)),
                  builder: (context, st) => SizedBox(
                    width: 64,
                    child: Column(children: [
                      Padding(padding: const EdgeInsets.all(5), child: CineAvatar(avatarKey: m.avatarKey, selected: _picked.contains(m.profileId))),
                      CineRoleText(m.name, c.typeUi, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (dup.contains(m.name) && m.username != null) CineRoleText('@${m.username}', c.typeCaption, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],),
                  ),
                ),
              ),
          ],),
        SizedBox(height: c.space4),
        TextField(
          controller: _note,
          focusNode: _noteFocus,
          maxLength: 140,
          maxLines: null,
          minLines: 2,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [noteLimit],
          style: CineText.literal(context, CineFace.newsreader, 17, 28, italic: true).copyWith(color: c.colorInk100),
          cursorColor: c.colorSpot,
          decoration: InputDecoration.collapsed(hintText: 'Add a line…', hintStyle: CineText.literal(context, CineFace.newsreader, 17, 28, italic: true).copyWith(color: c.colorInk45)),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Padding(
            padding: EdgeInsets.only(top: c.space1),
            child: Align(alignment: Alignment.centerRight, child: CineRoleText('${noteLength(_note.text)} / $kLetterNoteMax', c.typeFolio, color: noteLength(_note.text) >= 130 ? c.colorInk100 : c.colorInk45)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        CineFieldUnderline(focused: _noteFocus.hasFocus),
        SizedBox(height: c.space4),
        Row(children: [
          CineButton(key: const Key('pass-send'), label: 'Send', onPressed: canSend ? () => unawaited(_send(recipients)) : null, loading: _sending),
          if (!online) ...[SizedBox(width: c.space3), Flexible(child: CineRoleText('Sending needs a connection.', c.typeCaption, color: c.colorInk45))],
        ],),
      ],),
    );
  }
}
