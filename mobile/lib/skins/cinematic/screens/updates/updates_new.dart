import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `CH 141`, `CH 141.5`; `NEW` for a chapter the source does not number.
String updateFolio(UpdateChapter c) {
  final n = c.chapterNumber;
  if (n == null) return 'NEW';
  return 'CH ${n == n.roundToDouble() ? n.round() : n}';
}

/// A day's date rule: a `type.kicker` over a `rule.hair`.
class UpdateDayRule extends StatelessWidget {
  const UpdateDayRule(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: CineRoleText(label, c.typeKicker, color: c.colorInk60)),
        SizedBox(height: c.space2),
        DecoratedBox(decoration: BoxDecoration(border: Border(top: c.ruleHair)), child: const SizedBox(width: double.infinity)),
      ],),
    );
  }
}

/// One series' new chapters of a day (cinematic 8.10): the 48 x 72 cover, the title with its `NEW`
/// count, the chapter folios (each its own 44 / 48 button, into the reader by Dip), the source and
/// time, `Read from 141` and `Mark read`. Fully read groups fade to `ink.45`; a swipe left marks
/// the group read and the row springs back.
class UpdateGroupRow extends StatefulWidget {
  const UpdateGroupRow({
    super.key,
    required this.group,
    required this.coverUrl,
    required this.sourceName,
    required this.now,
    required this.fresh,
    required this.onFolio,
    required this.onReadFrom,
    required this.onMarkRead,
    required this.onOpenSeries,
    required this.onTyped,
    this.enabled = true,
    this.focusNode,
  });

  final SeriesUpdate group;
  final String? coverUrl;
  final String sourceName;
  final DateTime now;

  /// Notification ids whose folios have not typed themselves yet this session.
  final Set<int> fresh;
  final void Function(UpdateChapter) onFolio;
  final VoidCallback onReadFrom, onMarkRead, onOpenSeries;

  /// The ids that finished typing.
  final ValueChanged<Set<int>> onTyped;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<UpdateGroupRow> createState() => _UpdateGroupRowState();
}

class _UpdateGroupRowState extends State<UpdateGroupRow> {
  final Set<int> _done = {};

  void _typed(int id, Set<int> all) {
    _done.add(id);
    if (_done.containsAll(all)) widget.onTyped(all);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final g = widget.group;
    final first = g.firstUnread;
    final ink = g.allRead ? c.colorInk45 : c.colorInk100;
    final tag = (g.sourceId, g.seriesKey);
    final freshIds = {for (final ch in g.chapters) if (widget.fresh.contains(ch.notificationId)) ch.notificationId};
    final ago = g.newestAt == null ? '' : ' · ${agoWords(g.newestAt!, widget.now)}';
    final readFrom = first == null ? null : 'Read from ${updateFolio(first).replaceFirst('CH ', '')}';
    final cover = SizedBox(
      width: 48,
      height: 72,
      child: Hero(tag: tag, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: widget.coverUrl, title: g.title))),
    );
    Widget body = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onOpenSeries, child: cover),
      SizedBox(width: c.space4),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: ink),
                duration: const Duration(milliseconds: 160),
                builder: (_, col, __) => CineRoleText(g.title, c.typeTitle, color: col, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (g.unread > 0) ...[SizedBox(width: c.space2), CineBadge.newCount(g.unread)],
          ],),
          Wrap(spacing: 8, children: [
            for (final ch in g.chapters)
              _Folio(
                key: ValueKey('folio-${ch.notificationId}'),
                label: updateFolio(ch),
                read: ch.read,
                typed: freshIds.contains(ch.notificationId),
                onDone: () => _typed(ch.notificationId, freshIds),
                onTap: widget.enabled ? () => widget.onFolio(ch) : null,
              ),
          ],),
          CineRoleText('${widget.sourceName}$ago', c.typeCaption, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (first != null) ...[
            SizedBox(height: c.space2),
            Wrap(spacing: 8, children: [
              CineButton(label: readFrom!, variant: CineButtonVariant.split, size: CineButtonSize.sm, onPressed: widget.enabled ? widget.onReadFrom : null, disabledReason: 'Needs a connection.'),
              CineButton(label: 'Mark read', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.enabled ? widget.onMarkRead : null, disabledReason: 'Needs a connection.'),
            ],),
          ],
        ],),
      ),
    ],);
    body = CineRowShell(
      minHeight: 104,
      focusNode: widget.focusNode,
      menu: [
        if (first != null) CineMenuEntry<Object?>(label: readFrom!, disabled: !widget.enabled, onSelected: widget.onReadFrom),
        if (first != null) CineMenuEntry<Object?>(label: 'Mark read', disabled: !widget.enabled, onSelected: widget.onMarkRead),
        CineMenuEntry<Object?>(label: 'Open series', onSelected: widget.onOpenSeries),
      ],
      semanticLabel: '${g.title}, ${g.unread} new, ${g.chapters.map(updateFolio).join(', ')}',
      child: body,
    );
    if (!widget.enabled) return body;
    return CineSwipeRow(id: 'update-${g.sourceId}-${g.seriesKey}-${g.newestAt?.millisecondsSinceEpoch}', kind: CineSwipeKind.markRead, dimmed: g.allRead, onCommit: widget.onMarkRead, child: body);
  }
}

/// One chapter folio: a button with its own 44 pt / 48 dp box; a fresh one types itself.
class _Folio extends StatelessWidget {
  const _Folio({super.key, required this.label, required this.read, required this.typed, required this.onDone, required this.onTap});
  final String label;
  final bool read, typed;
  final VoidCallback onDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final style = CineText.style(context, c.typeFolio).copyWith(color: read ? c.colorInk45 : c.colorInk100);
    final hit = cineHitMin(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        builder: (context, st) => ConstrainedBox(
          constraints: BoxConstraints(minWidth: hit, minHeight: hit),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: st.hovered || st.focused ? c.colorInk100 : const Color(0x00000000)))),
              child: typed ? TypedHeadline(label, style: style, onDone: onDone) : CineRoleText(label, c.typeFolio, color: read ? c.colorInk45 : c.colorInk100),
            ),
          ),
        ),
      ),
    );
  }
}
