import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `21:04`, in local time.
String historyClock(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _num(double n) => n == n.roundToDouble() ? '${n.round()}' : '$n';

/// `CH 142 · p.12 OF 40`; a novel says `CH 142 · 42% IN`.
String historyCaption(ReadingHistoryItem i, {required bool novel}) {
  final ch = i.chapterNumber == null ? 'CHAPTER' : 'CH ${_num(i.chapterNumber!)}';
  if (novel) {
    final pct = i.pageCount <= 0 ? null : ((i.lastPage / i.pageCount) * 100).round().clamp(0, 100);
    return pct == null ? ch : '$ch · $pct% IN';
  }
  return i.pageCount > 0 ? '$ch · p.${i.lastPage} OF ${i.pageCount}' : '$ch · p.${i.lastPage}';
}

/// The action's folio: `p.12` for an unfinished chapter, `CH 143` for the one after a finished one.
String historyActionFolio(ReadingHistoryItem i, {required bool novel}) {
  if (i.isCompleted) return i.chapterNumber == null ? 'NEXT' : 'CH ${_num(i.chapterNumber! + 1)}';
  return novel ? '${i.pageCount <= 0 ? 0 : ((i.lastPage / i.pageCount) * 100).round()}%' : 'p.${i.lastPage}';
}

/// One row of the log (cinematic 8.12): the time in the left margin (40 px on phones, 56 on
/// tablets), a 40 x 60 cover, the title, `CH 142 · p.12 OF 40`, a 2 px progress rule, and the
/// continue action: an icon and folio on phones, `Continue` / `Next │ CH 143` on tablets.
class HistoryRow extends StatefulWidget {
  const HistoryRow({
    super.key,
    required this.item,
    required this.coverUrl,
    required this.novel,
    required this.wide,
    required this.onContinue,
    required this.onOpenSeries,
    this.focusNode,
    this.enabled = true,
  });

  final ReadingHistoryItem item;
  final String? coverUrl;
  final bool novel, wide, enabled;

  /// Resolves where to go and enters the reader; the row shows the busy segment until it returns.
  final Future<void> Function() onContinue;
  final VoidCallback onOpenSeries;
  final FocusNode? focusNode;

  @override
  State<HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<HistoryRow> {
  bool _busy = false;

  Future<void> _go() async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      await widget.onContinue();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final i = widget.item;
    final margin = widget.wide ? 56.0 : 40.0;
    final title = (i.seriesTitle?.trim().isEmpty ?? true) ? null : i.seriesTitle!.trim();
    final progress = i.isCompleted ? 1.0 : (i.pageCount <= 0 ? 0.0 : (i.lastPage / i.pageCount).clamp(0.0, 1.0));
    final folio = historyActionFolio(i, novel: widget.novel);
    final caption = historyCaption(i, novel: widget.novel);
    final action = widget.wide
        ? CineButton(
            label: i.isCompleted ? 'Next │ $folio' : 'Continue',
            folio: i.isCompleted ? null : folio,
            variant: CineButtonVariant.split,
            size: CineButtonSize.sm,
            loading: _busy,
            onPressed: widget.enabled ? _go : null,
            disabledReason: 'Needs a connection.',
          )
        : _PhoneAction(folio: folio, busy: _busy, onTap: widget.enabled ? _go : null, label: i.isCompleted ? 'Next, $folio' : 'Continue at $folio');
    return Semantics(
      container: true,
      label: '${title ?? 'Unknown series'}, $caption',
      child: CinePressable(
        hit: false,
        focusNode: widget.focusNode,
        onTap: widget.enabled ? _go : null,
        builder: (context, st) => Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: EdgeInsets.symmetric(vertical: c.space2),
          decoration: BoxDecoration(color: st.pressed ? c.colorPaper3 : null, border: Border(bottom: c.ruleHair, left: BorderSide(color: st.focused || st.hovered ? c.colorInk100 : const Color(0x00000000), width: 2))),
          child: Row(children: [
            SizedBox(width: margin, child: Padding(padding: const EdgeInsets.only(left: 4), child: CineRoleText(historyClock(i.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0)), c.typeFolio, color: c.colorInk45))),
            Semantics(
              button: true,
              label: 'Open ${title ?? 'series'}',
              excludeSemantics: true,
              onTap: widget.onOpenSeries,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenSeries,
                child: SizedBox(
                  width: cineHitMin(context),
                  height: 60,
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 60,
                      child: Hero(tag: (i.sourceId, i.seriesKey), child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: widget.coverUrl, title: title))),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: c.space3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                CineRoleText(title ?? 'Unknown series', c.typeTitle, color: title == null ? c.colorInk45 : c.colorInk100, maxLines: 2, overflow: TextOverflow.ellipsis),
                CineRoleText(caption, c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: c.space1),
                CineRuleProgress(value: progress),
              ],),
            ),
            SizedBox(width: c.space2),
            action,
            SizedBox(width: c.space2),
          ],),
        ),
      ),
    );
  }
}

class _PhoneAction extends StatelessWidget {
  const _PhoneAction({required this.folio, required this.busy, required this.onTap, required this.label});
  final String folio, label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    return Semantics(
      button: true,
      label: label,
      value: busy ? 'Loading' : null,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        builder: (context, st) => ConstrainedBox(
          constraints: BoxConstraints(minWidth: hit, minHeight: hit),
          child: Stack(alignment: Alignment.center, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              CineGlyphIcon(CineGlyph.play, color: onTap == null ? c.colorInk30 : c.colorInk100),
              SizedBox(width: c.space1),
              CineRoleText(folio, c.typeFolio, color: onTap == null ? c.colorInk30 : c.colorInk100),
            ],),
            if (busy) const Positioned(left: 0, right: 0, bottom: 4, child: CineIndeterminateRule()),
          ],),
        ),
      ),
    );
  }
}
