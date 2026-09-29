import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Source health, worst first: one block per source on phones; from 600 dp a table inside its own
/// horizontal scroll (720 minimum) so the page never scrolls sideways. `Enter` on a focused row
/// opens or closes its last error.
class SourceHealthList extends StatefulWidget {
  const SourceHealthList({super.key, required this.rows, required this.now, required this.loading, required this.nodeFor, this.error, this.onRetry});
  final List<SourceHealthRow> rows;
  final DateTime now;
  final bool loading;
  final FocusNode Function(String id) nodeFor;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<SourceHealthList> createState() => _SourceHealthListState();
}

class _SourceHealthListState extends State<SourceHealthList> {
  final Set<String> _open = {};

  void _toggle(String id) => setState(() => _open.contains(id) ? _open.remove(id) : _open.add(id));

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return StatusCard(
      kicker: 'SOURCE HEALTH',
      loading: widget.loading,
      greekRows: 5,
      error: widget.error,
      onRetry: widget.onRetry,
      child: widget.rows.isEmpty
          ? CineRoleText('No sources are installed on this server.', c.typeCaption, color: c.colorInk60)
          : (wide ? _table(context) : Column(children: [for (final r in widget.rows) _block(context, r)])),
    );
  }

  Widget _mark(CineTokens c, StatusState s) =>
      ExcludeSemantics(child: SizedBox(width: 6, height: 6, child: ColoredBox(color: stateColor(c, s))));

  Widget _demoted(CineTokens c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: c.colorInk60)),
        child: CineRoleText('DEMOTED', c.typeMicro, color: c.colorInk60),
      );

  String _probe(SourceHealthRow r) => r.lastCheckedAt == null ? 'NEVER PROBED' : 'LAST PROBE ${agoLabel(r.lastCheckedAt!, widget.now)}';

  Widget _error(BuildContext context, SourceHealthRow r) {
    final c = context.cine;
    final open = _open.contains(r.id);
    if (r.lastError == null || r.lastError!.isEmpty) return const SizedBox.shrink();
    final reduced = CineMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: 'Last error for ${r.name}',
          excludeSemantics: true,
          onTap: () => _toggle(r.id),
          child: CinePressable(
            onTap: () => _toggle(r.id),
            hit: false,
            builder: (_, __) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  CineRoleText('LAST ERROR', c.typeKicker, color: c.colorInk60),
                  SizedBox(width: c.space1),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: reduced ? Duration.zero : c.durLine,
                    child: CineGlyphIcon(CineGlyph.caretDown, size: 16, color: c.colorInk60),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) ErrorBlock(r.lastError!),
      ],
    );
  }

  Widget _block(BuildContext context, SourceHealthRow r) {
    final c = context.cine;
    return CineFocusRing(
      focusNode: widget.nodeFor(r.id),
      onActivate: () => _toggle(r.id),
      child: Container(
        key: ValueKey('source-${r.id}'),
        padding: EdgeInsets.symmetric(vertical: c.space3),
        decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              label: '${r.name}, ${stateWord(r.state).toLowerCase()}, ${r.message}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _mark(c, r.state),
                      SizedBox(width: c.space2),
                      Flexible(child: CineRoleText(r.name, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (r.demoted) ...[SizedBox(width: c.space2), _demoted(c)],
                    ],
                  ),
                  CineLit(r.id, CineFace.plexMono, 12, 16, wght: 500, color: c.colorInk60),
                  CineRoleText(_probe(r), c.typeFolio, color: c.colorInk60),
                  CineRoleText(r.message, c.typeCaption, color: c.colorInk80),
                ],
              ),
            ),
            _error(context, r),
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context) {
    final c = context.cine;
    Widget cell(double w, Widget child) => SizedBox(width: w, child: child);
    return SingleChildScrollView(
      key: const Key('source-table-scroll'),
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in widget.rows)
              CineFocusRing(
                focusNode: widget.nodeFor(r.id),
                onActivate: () => _toggle(r.id),
                child: Container(
                  key: ValueKey('source-${r.id}'),
                  padding: EdgeInsets.symmetric(vertical: c.space3),
                  decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cell(24, Padding(padding: const EdgeInsets.only(top: 6), child: _mark(c, r.state))),
                          cell(150, CineRoleText(r.name, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          cell(130, CineLit(r.id, CineFace.plexMono, 12, 16, wght: 500, color: c.colorInk60)),
                          cell(90, r.demoted ? Align(alignment: Alignment.centerLeft, child: _demoted(c)) : const SizedBox.shrink()),
                          cell(150, CineRoleText(_probe(r), c.typeFolio, color: c.colorInk60)),
                          SizedBox(width: 176, child: CineRoleText(r.message, c.typeCaption, color: c.colorInk80)),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(left: 24), child: SizedBox(width: 600, child: _error(context, r))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
