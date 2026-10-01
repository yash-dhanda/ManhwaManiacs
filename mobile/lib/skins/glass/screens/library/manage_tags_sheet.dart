import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/tags_provider.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `?sheet=manage-tags` (glass 8.17): rows with the colour dot, the name and "12 series"; a tap renames in place (24 characters), a
/// swipe left or the trailing button deletes after an alert.
final GlassSheetSpec glassManageTagsSheetSpec = GlassSheetSpec(
  title: 'Manage tags',
  builder: (_) => const GlassManageTagsBody(),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
);

class GlassManageTagsBody extends ConsumerWidget {
  const GlassManageTagsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    final offline = ref.watch(glassOfflineProvider);
    final on = sheetOnGlass(context);
    return tags.when(
      loading: () => ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 52, radius: 16, index: i))]),
      error: (e, _) => Center(
        child: GlassObjectLens(
          situation: LensSituation.unavailable,
          title: offline || e is NetworkError ? 'Tags need a connection' : "Couldn't load your tags",
          tone: GlassLensTone.error,
          primary: LensAction('Try again', () => ref.invalidate(tagsProvider)),
        ),
      ),
      data: (list) => list.isEmpty
          ? const Center(child: GlassObjectLens(situation: LensSituation.library, title: 'No tags yet', description: "Add tags from a series' ⋯ menu."))
          : GlassSwipeGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (offline) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassText('Tags need a connection', role: gt.typeFootnote, color: gt.colorWarning, onGlass: on)),
                  for (final t in list) _TagRow(key: ValueKey(t.id), tag: t, readOnly: offline),
                ],
              ),
            ),
    );
  }
}

class _TagRow extends ConsumerStatefulWidget {
  const _TagRow({super.key, required this.tag, required this.readOnly});
  final Tag tag;
  final bool readOnly;

  @override
  ConsumerState<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends ConsumerState<_TagRow> {
  bool _editing = false;
  String? _error;
  late final TextEditingController _c = TextEditingController(text: widget.tag.name);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _rename(String value) async {
    final name = value.trim();
    if (name.isEmpty || name == widget.tag.name) {
      setState(() {
        _editing = false;
        _error = null;
      });
      return;
    }
    final err = await ref.read(tagsControllerProvider).rename(widget.tag.id, name);
    if (!mounted) return;
    setState(() {
      _error = err == null ? null : "Couldn't rename that tag";
      _editing = err != null;
    });
  }

  Future<void> _delete() async {
    final ok = await confirmAlert(context, title: 'Delete this tag?', body: 'It is removed from every series.', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    final err = await ref.read(tagsControllerProvider).delete(widget.tag.id);
    if (err != null && mounted) showGlassToast(ref, const GlassToastSpec("Couldn't delete that tag", kind: GlassToastKind.error));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tag;
    final on = sheetOnGlass(context);
    final count = t.seriesCount;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: t.color ?? gt.colorIris400)),
        const SizedBox(width: 12),
        Expanded(
          child: _editing
              ? GlassTextField(controller: _c, autofocus: true, hint: 'Tag name', error: _error, onSheet: true, onSubmitted: _rename, onChanged: (v) {
                  if (v.length > 24) _c.text = v.substring(0, 24);
                },)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.readOnly ? null : () => setState(() => _editing = true),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GlassText(t.name, role: gt.typeBody, onGlass: on),
                    if (count != null) GlassText('$count series', role: gt.typeCaption1, color: gt.colorLabel3),
                  ],),
                ),
        ),
        if (!widget.readOnly) GlassIconButton(icon: roleButtonIcon(GlassIconRole.delete), label: 'Delete ${t.name}', onPressed: () => unawaited(_delete())),
      ],),
    );
    if (widget.readOnly) return Padding(padding: const EdgeInsets.only(bottom: 8), child: row);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSwipeRow(
        name: t.name,
        showMore: false,
        trailing: [SwipeAction(id: 'delete', label: 'Delete', glyph: roleIcon(GlassIconRole.delete), tone: SwipeTone.danger, run: _delete)],
        child: row,
      ),
    );
  }
}
