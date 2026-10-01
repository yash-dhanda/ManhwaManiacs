import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType, SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/settings/utils/licenses.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Loads the groups once per sheet; tests override it.
final licenceGroupsProvider = FutureProvider.autoDispose<List<LicenceGroup>>((ref) => loadLicenceGroups(), name: 'licenceGroups');

/// The Open-source licences sheet (`?sheet=licenses`, glass 8.25.14): a `large` sheet on phones, the 560 px window on the desktop
/// frame. A search field, rows grouped Fonts, App packages, Artwork and sounds, and the licence text pushed inside the sheet.
class GlassLicencesSheet extends StatefulWidget {
  const GlassLicencesSheet({super.key});
  @override
  State<GlassLicencesSheet> createState() => _GlassLicencesSheetState();
}

class _GlassLicencesSheetState extends State<GlassLicencesSheet> {
  final GlobalKey<NavigatorState> _nav = GlobalKey(debugLabel: 'licences');

  @override
  Widget build(BuildContext context) => NavigatorPopHandler(
        onPopWithResult: (_) => _nav.currentState?.maybePop(),
        child: Navigator(
          key: _nav,
          // The sheet body has no Material ancestor; the search field and the selectable text need one.
          onGenerateRoute: (_) => PageRouteBuilder<void>(pageBuilder: (_, __, ___) => const Material(type: MaterialType.transparency, child: LicenceList()), transitionDuration: Duration.zero),
        ),
      );
}

class LicenceList extends ConsumerStatefulWidget {
  const LicenceList({super.key});
  @override
  ConsumerState<LicenceList> createState() => _LicenceListState();
}

class _LicenceListState extends ConsumerState<LicenceList> {
  final _q = TextEditingController();
  final _search = FocusNode(debugLabel: 'licence search');
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(LicenceItem item) async {
    final row = FocusManager.instance.primaryFocus;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => Material(type: MaterialType.transparency, child: LicenceText(item: item)),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 180),
    ),);
    // Back on the list: focus returns to the row that opened the text.
    if (row != null && row.context != null) row.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(licenceGroupsProvider);
    final onGlass = GlassFrame.of(context) == GlassFrameKind.desktop;
    Widget body;
    if (groups.hasError) {
      body = GlassInlineError(message: "Couldn't load the licences", onRetry: () => ref.invalidate(licenceGroupsProvider));
    } else if (!groups.hasValue) {
      body = const GlassRowSkeletons(8, label: 'Loading licences');
    } else {
      final shown = filterLicences(groups.value!, _query);
      body = shown.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: GlassText('No package matches “${_query.trim()}”', role: gt.typeCallout, color: gt.colorLabel2))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final g in shown)
                GlassGroupedList(header: g.title, children: [
                  for (final i in g.items) _LicenceRow(item: i, onGlass: onGlass, onOpen: () => unawaited(_open(i))),
                ],),
            ],);
    }
    return RegisteredShortcuts(
      group: 'Licences',
      entries: [
        ShortcutEntry(group: 'Licences', activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'Search packages', onInvoke: _search.requestFocus, singleKey: true, keys: const ['/']),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GlassSearchField(
              variant: GlassSearchVariant.filter,
              controller: _q,
              focusNode: _search,
              placeholder: 'Search packages',
              onQuery: (q) => setState(() => _query = q),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

class _LicenceRow extends StatelessWidget {
  const _LicenceRow({required this.item, required this.onGlass, required this.onOpen});
  final LicenceItem item;
  final bool onGlass;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      button: true,
      label: '${item.name}${item.version == null ? '' : ', version ${item.version}'}, ${item.tag}',
      excludeSemantics: true,
      onTap: onOpen,
      child: FocusableActionDetector(
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onOpen())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit < 52 ? 52 : hit),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    GlassText(item.name, role: gt.typeMono, color: gt.colorLabel1, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (item.version != null) GlassText(item.version!, role: gt.typeCaption1, color: onGlass ? gt.colorOnGlass : gt.colorLabel3),
                  ],),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(10)),
                  child: GlassText(item.tag, role: gt.typeCaption1, wght: 600, maxScale: 1.5),
                ),
              ],),
            ),
          ),
        ),
      ),
    );
  }
}

/// The licence text inside the sheet: the package name as the title, "Copy" in the header, the text in `mono` 13/20.
class LicenceText extends ConsumerWidget {
  const LicenceText({super.key, required this.item});
  final LicenceItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGlass = GlassFrame.of(context) == GlassFrameKind.desktop;
    void back() => Navigator.of(context).maybePop();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): back},
      child: Focus(
        autofocus: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(children: [
              GlassIconButton(icon: GlassButtonIcon(GlassGlyph28.caretLeft.regular), label: 'Back', onPressed: back),
              Expanded(child: Semantics(header: true, child: GlassText(item.name, role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis))),
              GlassButton(
                label: 'Copy',
                variant: GlassButtonVariant.plain,
                size: GlassButtonSize.small,
                onPressed: () {
                  unawaited(Clipboard.setData(ClipboardData(text: item.text)));
                  showGlassToast(ref, const GlassToastSpec('Copied'));
                },
              ),
            ],),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: SelectableText(item.text, style: GlassTypeStyle.style(context, gt.typeMono, size: 13, height: 20).copyWith(color: onGlass ? gt.colorOnGlass : gt.colorLabel2)),
            ),
          ),
        ],),
      ),
    );
  }
}
