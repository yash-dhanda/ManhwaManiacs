import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/delete_profile_alert.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Move Late-night reads to position 2 of 4" (announced assertively after every move).
String moveAnnouncement(String name, int position, int total) => '$name moved to position $position of $total';

/// Manage profiles (glass 8.6): the You branch's `/profiles/manage`. Rows with an "Active" badge, Use, edit and a menu with the move
/// items; dragging reorders and writes only the changed `sort_order`s.
class GlassProfilesManageScreen extends ConsumerStatefulWidget {
  const GlassProfilesManageScreen({super.key});

  @override
  ConsumerState<GlassProfilesManageScreen> createState() => _GlassProfilesManageScreenState();
}

class _GlassProfilesManageScreenState extends ConsumerState<GlassProfilesManageScreen> {
  int? _focusedId;
  List<Profile>? _order;
  final Map<int, FocusNode> _nodes = {};

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _reorder(List<Profile> list, int from, int to) async {
    final next = [...list];
    final moved = next.removeAt(from);
    next.insert(to, moved);
    setState(() => _order = next);
    unawaited(SemanticsService.sendAnnouncement(View.of(context), moveAnnouncement(moved.name, to + 1, next.length), Directionality.of(context), assertiveness: Assertiveness.assertive));
    final err = await ref.read(profilesProvider.notifier).reorder([for (final p in next) p.id]);
    if (!mounted) return;
    setState(() => _order = null);
    if (err != null) showGlassToast(ref, const GlassToastSpec("Couldn't save the order. Try again.", kind: GlassToastKind.error));
  }

  Future<void> _use(Profile p) async {
    final sw = ref.read(glassProfileSwitchProvider);
    final r = await sw.prepare(p);
    if (!mounted) return;
    if (r.restartTo != null) {
      await playMelt(ref);
      if (mounted) await restartIntoSkin(context, ref, r.restartTo!);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) sw.commit(Routes.tonight());
  }

  void _edit(Profile p) => unawaited(context.push<void>(Routes.profileEdit(p.id), extra: const GlassNavExtra()));

  void _add() => unawaited(context.push<void>(Routes.profileNew(), extra: const GlassNavExtra()));

  Future<void> _delete(Profile p) => showDeleteProfileAlert(context, ref, profile: p);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profilesProvider);
    final active = ref.watch(activeProfileProvider);
    final offline = ref.watch(glassOfflineProvider);
    final list = _order ?? async.valueOrNull;
    final atLimit = (list?.length ?? 0) >= kMaxProfiles;
    final addDisabled = atLimit || offline;

    final Widget body;
    if (list == null && async.isLoading) {
      body = GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 64, radius: 16, index: i))]));
    } else if (list == null) {
      body = GlassObjectLens(situation: LensSituation.loadError, title: "Couldn't load profiles", tone: GlassLensTone.error, placement: GlassLensPlacement.inline, primary: LensAction('Try again', () => unawaited(ref.read(profilesProvider.notifier).refresh())));
    } else if (list.isEmpty) {
      body = DecoratedBox(
        decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20), border: Border.all(color: GlassColors.g600)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [GlassText('No profiles yet', role: gt.typeHeadline), const SizedBox(height: 12), GlassButton(label: 'Add profile', onPressed: addDisabled ? null : _add)]),
        ),
      );
    } else {
      body = _list(list, active, offline);
    }

    return RegisteredShortcuts(
      group: 'Profiles',
      entries: [
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyN), description: 'Add a profile', singleKey: true, keys: const ['N'], onInvoke: () {
          if (!addDisabled) _add();
        },),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyE), description: 'Edit the focused profile', singleKey: true, keys: const ['E'], onInvoke: () {
          final p = _byId(list);
          if (p != null && !offline) _edit(p);
        },),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.delete), description: 'Delete the focused profile', keys: const ['Delete'], onInvoke: () {
          final p = _byId(list);
          if (p != null && !offline) unawaited(_delete(p));
        },),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.backspace), description: 'Delete the focused profile', keys: const ['Backspace'], onInvoke: () {
          final p = _byId(list);
          if (p != null && !offline) unawaited(_delete(p));
        },),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true), description: 'Move the focused profile up', keys: const ['Alt', '↑'], onInvoke: () => _moveFocused(list, -1)),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true), description: 'Move the focused profile down', keys: const ['Alt', '↓'], onInvoke: () => _moveFocused(list, 1)),
      ],
      child: GlassScaffold(
        title: 'Profiles',
        leading: GlassLeading.back,
        trailing: [
          GlassBarAction(id: 'add', label: 'Add profile', glyph: GlassGlyph.plus, onPress: addDisabled ? () {} : _add),
        ],
        slivers: [
          if (offline) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: GlassStatusCapsule(kind: GlassStatusKind.offline)))),
          SliverToBoxAdapter(child: body),
          if (atLimit) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 12), child: GlassText('Up to 5 profiles', role: gt.typeFootnote, color: gt.colorLabel2))),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Profile? _byId(List<Profile>? list) => list?.where((p) => p.id == _focusedId).firstOrNull;

  void _moveFocused(List<Profile>? list, int delta) {
    if (list == null || ref.read(glassOfflineProvider)) return;
    final p = _byId(list);
    if (p == null) return;
    final i = list.indexOf(p);
    final j = i + delta;
    if (j < 0 || j >= list.length) return;
    unawaited(_reorder(list, i, j));
  }

  Widget _list(List<Profile> list, ActiveProfile? active, bool offline) => ClipRSuperellipse(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: gt.colorSurface1,
          child: GlassReorderList<Profile>(
            items: list,
            nameOf: (p) => p.name,
            onReorder: offline ? (a, b) {} : (a, b) => unawaited(_reorder(list, a, b)),
            menuEntries: (p, i) => [
              GlassMenuEntry(label: 'Edit', enabled: !offline, onSelected: () => _edit(p)),
              if (active?.id != p.id) GlassMenuEntry(label: 'Use', onSelected: () => unawaited(_use(p))),
              GlassMenuEntry(label: 'Delete', destructive: true, enabled: !offline, onSelected: () => unawaited(_delete(p))),
            ],
            itemBuilder: (context, p, i, info) {
              final isActive = active?.id == p.id;
              return Focus(
                focusNode: _nodes.putIfAbsent(p.id, () => FocusNode(debugLabel: 'manage-${p.id}')),
                onFocusChange: (f) {
                  if (f) setState(() => _focusedId = p.id);
                },
                onKeyEvent: (n, e) {
                  if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.enter && !isActive) {
                    unawaited(_use(p));
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: GlassRowShell(
                  minHeight: 68,
                  semanticsLabel: '${p.name}, ${p.mood.label} mood${isActive ? ', active' : ''}',
                  onTap: offline ? null : () => _edit(p),
                  builder: (context, stacked, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GlassProfileOrb(preset: glassPresetFor(p.avatarKey), mood: moodColour(p.mood), name: p.name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GlassText(p.name, role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis),
                              GlassText('${p.mood.label} mood', role: gt.typeFootnote, color: gt.colorLabel2),
                            ],
                          ),
                        ),
                        if (isActive) Padding(padding: const EdgeInsets.only(right: 4), child: _ActiveBadge()) else GlassButton(label: 'Use', variant: GlassButtonVariant.plain, onPressed: () => unawaited(_use(p))),
                        GlassIconButton(icon: GlassButtonIcon.glyph(GlassGlyph30.pencilSimple), label: 'Edit ${p.name}', onPressed: offline ? null : () => _edit(p), tooltip: offline ? 'Needs a connection' : null),
                        info.handle(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(10)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: GlassText('Active', role: gt.typeCaption1, color: gt.colorLabel1)),
      );
}
