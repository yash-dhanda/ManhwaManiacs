import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/chapter_meta.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A chapter row (glass 7.17): the number in `mono` 15/20 in a 44 px column, the title, a meta line (date, "18/40" in
/// `iris400` while reading, "40 pages", "Read") and the download control trailing. Min height 56 (68 with a secondary
/// title). Read rows drop to `label3`; the in-progress row has a 2 px `iris500` bar under its number.
class GlassChapterRow extends ConsumerWidget {
  const GlassChapterRow({
    super.key,
    required this.number,
    this.title,
    this.secondaryTitle,
    this.date,
    this.now,
    this.pageCount,
    this.progress,
    this.read = false,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.selectMode = false,
    this.selected = false,
    this.error,
    this.disabledHint,
    this.forceStates = GlassWidgetStates.none,
    this.customActions = const {},
    this.focusNode,
  });

  final double? number;
  final String? title;
  final String? secondaryTitle;
  final DateTime? date;

  /// The clock for [date]; defaults to now.
  final DateTime? now;
  final int? pageCount;

  /// Pages read of [pageCount] while in progress.
  final int? progress;
  final bool read;

  /// The download control.
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool loading;
  final bool selectMode;
  final bool selected;
  final String? error;

  /// "Already on this device" for a saved row while selecting.
  final String? disabledHint;
  final GlassWidgetStates forceStates;
  final Map<CustomSemanticsAction, VoidCallback> customActions;
  final FocusNode? focusNode;

  bool get inProgress => progress != null && pageCount != null && !read;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numLabel = chapterNumberLabel(number);
    final name = title ?? (number == null ? 'Chapter' : 'Chapter $numLabel');
    final bits = <String>[
      if (date != null) chapterDateLabel(date!, now ?? DateTime.now()),
      if (inProgress) '$progress/$pageCount' else if (pageCount != null) '$pageCount pages',
      if (read) 'Read',
    ];
    return GlassRowShell(
      minHeight: secondaryTitle != null ? 68 : 56,
      semanticsLabel: [if (number != null) 'Chapter $numLabel', if (title != null) title!, ...bits].join(', '),
      semanticsHint: disabledHint,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      loading: loading,
      selectMode: selectMode,
      selected: selected,
      error: error,
      forceStates: forceStates,
      customActions: customActions,
      focusNode: focusNode,
      builder: (context, stacked, info) {
        final host = GlassHost.of(context);
        final off = !enabled;
        final l1 = read ? 3 : 1;
        final numW = SizedBox(
          width: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassText(numLabel, role: gt.typeMono, size: 15, height: 20, color: glassRowTone(context, 2, disabled: off), onGlass: host),
              if (inProgress) Padding(padding: const EdgeInsets.only(top: 2), child: SizedBox(width: 24, height: 2, child: ColoredBox(color: gt.colorIris500))),
            ],
          ),
        );
        final meta = Wrap(spacing: 8, children: [
          for (final b in bits)
            GlassText(b, role: gt.typeCaption1, color: b.contains('/') && !read ? gt.colorIris400 : glassRowTone(context, 3, disabled: off), onGlass: host && !(b.contains('/') && !read)),
        ],);
        final texts = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          GlassText(name, role: gt.typeBody, color: glassRowTone(context, l1, disabled: off), onGlass: host, maxScale: 1.6),
          if (secondaryTitle != null) GlassText(secondaryTitle!, role: gt.typeFootnote, color: glassRowTone(context, 3, disabled: off), onGlass: host, maxScale: 1.6),
          if (bits.isNotEmpty) meta,
        ],);
        if (stacked) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [numW, Expanded(child: texts)]),
              if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
            ],),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
          child: Row(children: [numW, Expanded(child: texts), if (trailing != null) trailing!]),
        );
      },
    );
  }
}
