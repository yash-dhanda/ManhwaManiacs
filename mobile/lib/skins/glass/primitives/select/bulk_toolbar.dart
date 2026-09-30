import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_copy.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/floating_bar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The outcome of one bulk action: how many succeeded and which ids failed (as strings).
class BulkResult {
  const BulkResult({required this.ok, this.failed = const []});
  final int ok;
  final List<String> failed;
}

/// One bulk action (glass 7.35): Favourite, Mark read, Add to collection, Download, Remove ...
class BulkAction<K> {
  const BulkAction({required this.id, required this.label, required this.glyph, this.destructive = false, required this.run, this.undo, this.verb});
  final String id;
  final String label;
  final IconData glyph;
  final bool destructive;
  final Future<BulkResult> Function(Set<K> ids, CancelToken cancel) run;

  /// Runs from the Undo toast of a destructive action.
  final Future<void> Function(Set<K> ids)? undo;

  /// The result verb: "marked read", "removed". Defaults to the lower-cased label.
  final String? verb;
}

/// The batch size a bulk run uses; a `batch_too_large` answer halves it for the next try (glass 8.0.10).
class BulkBatchSizer {
  int size = 1 << 30;
  void shrink(int chunk) => size = (chunk ~/ 2).clamp(1, 1 << 30);
}

/// Runs [a] over [ids] in chunks of [sizer] size, reporting progress. A chunk the server calls too large fails whole and
/// halves the size for the retry.
Future<BulkResult> runBulkBatched<K>(BulkAction<K> a, Set<K> ids, CancelToken cancel, BulkBatchSizer sizer, {void Function(int done, int total)? onProgress}) async {
  final list = ids.toList();
  var ok = 0;
  final failed = <String>[];
  var done = 0;
  final step = sizer.size;
  for (var i = 0; i < list.length && !cancel.isCancelled; i += step) {
    final chunk = list.sublist(i, (i + step).clamp(0, list.length)).toSet();
    try {
      final r = await a.run(chunk, cancel);
      ok += r.ok;
      failed.addAll(r.failed);
    } on ApiError catch (e) {
      if (e.code == 'batch_too_large') sizer.shrink(chunk.length);
      failed.addAll(chunk.map((e) => '$e'));
    } catch (_) {
      failed.addAll(chunk.map((e) => '$e'));
    }
    done += chunk.length;
    onProgress?.call(done, list.length);
  }
  return BulkResult(ok: ok, failed: failed);
}

/// The bulk toolbar on the floating bar (glass 7.35): "{n} selected", the actions as `fill2` icon buttons (labels on tablet and
/// desktop frames, tooltips on phones) and a plain Done. While a batch runs the capsule fills with liquid progress and a Stop.
class GlassBulkToolbar<K> extends ConsumerStatefulWidget {
  const GlassBulkToolbar({super.key, required this.controller, required this.actions, this.chunk});
  final GlassSelectModeController<K> controller;
  final List<BulkAction<K>> actions;

  /// Items per call of [BulkAction.run]; the running fill moves once per chunk (the Library uses 4, its bulk concurrency).
  final int? chunk;

  @override
  ConsumerState<GlassBulkToolbar<K>> createState() => _GlassBulkToolbarState<K>();
}

class _GlassBulkToolbarState<K> extends ConsumerState<GlassBulkToolbar<K>> {
  late final BulkBatchSizer _sizer = BulkBatchSizer()..size = widget.chunk ?? (1 << 30);
  CancelToken? _cancel;
  int _done = 0;
  int _total = 0;

  GlassSelectModeController<K> get c => widget.controller;
  bool get running => _cancel != null;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _run(BulkAction<K> a, Set<K> ids) async {
    if (running || ids.isEmpty) return;
    final cancel = CancelToken();
    setState(() {
      _cancel = cancel;
      _done = 0;
      _total = ids.length;
    });
    final r = await runBulkBatched(a, ids, cancel, _sizer, onProgress: (d, t) {
      if (mounted) setState(() => _done = d);
    },);
    if (!mounted) return;
    setState(() => _cancel = null);
    final copy = bulkToast(a.verb ?? a.label.toLowerCase(), r.ok, r.failed.length);
    final failedIds = {for (final id in ids) if (r.failed.contains('$id')) id};
    showGlassToast(
      ref,
      GlassToastSpec(
        copy.message,
        kind: r.failed.isEmpty ? GlassToastKind.success : GlassToastKind.warning,
        actionLabel: copy.action,
        onAction: failedIds.isEmpty ? null : () => unawaited(_run(a, failedIds)),
        undo: a.undo != null && r.ok > 0 ? () => unawaited(a.undo!(ids.difference(failedIds))) : null,
      ),
    );
    if (failedIds.isEmpty) {
      c.exit();
    } else {
      c.setSelected(failedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final hit = GlassFrame.hitMin(context);
    final Widget content;
    if (running) {
      content = Stack(children: [
        Positioned.fill(child: IgnorePointer(child: LiquidProgress(value: _total == 0 ? 0 : _done / _total, height: 52))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: Semantics(liveRegion: true, child: GlassText('$_done of $_total', role: gt.typeSubhead, onGlass: true))),
            GlassButton(label: 'Stop', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: () => _cancel?.cancel('stopped')),
          ],),
        ),
      ],);
    } else {
      content = Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(children: [
          Semantics(label: '${c.count} selected', excludeSemantics: true, child: Row(mainAxisSize: MainAxisSize.min, children: [
            GlassText('${c.count}', role: gt.typeMono, onGlass: true),
            GlassText(' selected', role: gt.typeSubhead, onGlass: true),
          ],),),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final a in widget.actions) _BulkButton(action: a, wide: wide, hit: hit, onTap: () => unawaited(_run(a, c.selected))),
              ],),
            ),
          ),
          GlassButton(label: 'Done', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: c.exit),
        ],),
      );
    }
    return GlassFloatingBar(visible: c.active, debugLabel: 'GlassBulkToolbar', child: content);
  }
}

class _BulkButton<K> extends StatelessWidget {
  const _BulkButton({required this.action, required this.wide, required this.hit, required this.onTap});
  final BulkAction<K> action;
  final bool wide;
  final double hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive ? gt.colorDanger : gt.colorOnGlass;
    final button = GlassPressable(
      material: GlassMaterial.content,
      sink: 0.92,
      onTap: onTap,
      semanticsLabel: action.label,
      builder: (context, info) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: hit, minHeight: hit),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 8, vertical: 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(action.glyph, size: 20, color: color),
                if (wide) ...[const SizedBox(width: 6), GlassText(action.label, role: gt.typeCaption1, wght: 600, color: color, onGlass: true)],
              ],),
            ),
          ),
        ),
      ),
    );
    return Padding(padding: const EdgeInsets.only(left: 4), child: wide ? button : GlassTooltip(message: action.label, child: button));
  }
}

/// The standard actions' glyphs, so a screen does not pick its own (glass 7.35).
abstract final class BulkGlyphs {
  static IconData get favourite => GlassGlyph28.star.regular;
  static IconData get unfavourite => GlassGlyph28.starHalf.regular;
  static IconData get markRead => GlassGlyph28.checkCircle.regular;
  static IconData get markUnread => GlassGlyph28.circleDashed.regular;
  static IconData get addToCollection => GlassGlyph28.folderSimplePlus.regular;
  static IconData get download => GlassGlyph28.cloudArrowDown.regular;
  static IconData get remove => GlassGlyph28.trashSimple.regular;
}
