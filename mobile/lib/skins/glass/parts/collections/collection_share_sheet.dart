import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart' show currentQuery;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/read_together_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Registers `?sheet=collection-share` (glass 9.3.3): `medium`, the 560 px window on the desktop frame.
void registerCollectionShareSheet() => registerGlobalSheet(
      'collection-share',
      const GlassSheetSpec(title: 'Share shelf', builder: _share, detents: [GlassDetent.medium, GlassDetent.large], opening: GlassDetent.medium),
    );

Widget _share(BuildContext context) => const CollectionShareBody();

/// The collection id of the current location (`/collections/{id}`), or `&collection=`.
int? shareTargetId(WidgetRef ref) {
  final q = currentQuery(ref);
  final fromQuery = int.tryParse(q['collection'] ?? '');
  if (fromQuery != null) return fromQuery;
  try {
    final path = ref.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.pathSegments;
    final i = path.indexOf('collections');
    return i >= 0 && i + 1 < path.length ? int.tryParse(path[i + 1]) : null;
  } catch (_) {
    return null;
  }
}

/// The bloom rim drawn in over `tintShift` (900 ms) on the shelf that was just shared.
final justSharedShelfProvider = StateProvider<int?>((ref) => null, name: 'glassJustSharedShelf');

/// Share a shelf (glass 9.3.3): Circle members whose `shares.shelves` is on as 56 px orb toggles (selected with the 3 px `iris300`
/// ring), Can add · View only (default View only) and the tinted "Share". States: loading members, nobody accepts shelves, this
/// profile doesn't share, sharing, failed (inline, toggles kept), offline, success (closes; the card's rim draws in).
class CollectionShareBody extends ConsumerStatefulWidget {
  const CollectionShareBody({super.key, this.collectionId});
  final int? collectionId;

  @override
  ConsumerState<CollectionShareBody> createState() => _CollectionShareBodyState();
}

class _CollectionShareBodyState extends ConsumerState<CollectionShareBody> {
  late final int? _id = widget.collectionId ?? shareTargetId(ref);
  Set<int>? _selected;
  String _mode = 'view_only';
  bool _sharing = false;
  String? _error;

  Future<void> _share() async {
    final id = _id;
    if (id == null) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    final r = await ref.read(circleRepositoryProvider).shareCollection(id, profileIds: [...?_selected], mode: _mode);
    if (!mounted) return;
    if (r.isErr) {
      glassFire(ref, HapticEvent.error);
      setState(() {
        _sharing = false;
        _error = "Couldn't share this shelf";
      });
      return;
    }
    glassFire(ref, HapticEvent.success);
    ref
      ..invalidate(sharedCollectionsProvider)
      ..invalidate(sharedShelfDetailProvider(id));
    ref.read(justSharedShelfProvider.notifier).state = id;
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final m = GlassFrame.screenMargin(context);
    final offline = ref.watch(glassOfflineProvider);
    final pid = ref.watch(activeProfileProvider)?.id;
    final sharing = pid == null ? null : ref.watch(sharingProvider(pid)).valueOrNull;
    final members = ref.watch(circleMembersProvider);
    final id = _id;
    if (id != null && _selected == null) {
      final d = ref.watch(sharedShelfDetailProvider(id)).valueOrNull;
      if (d != null) {
        _selected = {...?d.shelf.shared?.memberProfileIds};
        _mode = d.shelf.shared?.mode ?? 'view_only';
      }
    }
    final accept = [for (final x in members.valueOrNull ?? const <CircleMember>[]) if (x.shares.shelves) x];
    final notSharing = sharing != null && !sharing.activity;
    final nobody = members.hasValue && accept.isEmpty;
    final canShare = !offline && !notSharing && !nobody && !_sharing && id != null;
    return ListView(
      padding: EdgeInsets.fromLTRB(m, 4, m, 24),
      children: [
        if (notSharing) const Padding(padding: EdgeInsets.only(bottom: 16), child: ReadTogetherCard(compact: true)),
        if (offline) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassText('Sharing needs a connection', role: gt.typeFootnote, color: gt.colorLabel2)),
        if (!members.hasValue)
          GlassSkeletonGroup(label: 'Loading your Circle', child: Row(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(right: 16), child: GlassSkeleton(width: 56, height: 56, circle: true, index: i))]))
        else if (nobody)
          GlassText('Nobody on this server accepts shared shelves yet.', role: gt.typeBody, color: gt.colorLabel2)
        else
          Wrap(spacing: 16, runSpacing: 16, children: [for (final x in accept) _toggle(x, enabled: !offline && !_sharing)]),
        const SizedBox(height: 20),
        GlassSegmented<String>(
          selected: _mode,
          enabled: !offline,
          onSelected: (v) => setState(() => _mode = v),
          segments: const [GlassSegment(value: 'can_add', label: 'Can add'), GlassSegment(value: 'view_only', label: 'View only')],
        ),
        const SizedBox(height: 20),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassText(_error!, role: gt.typeFootnote, color: gt.colorDanger)),
        GlassButton(label: 'Share', variant: GlassButtonVariant.primary, fullWidth: true, loading: _sharing, onPressed: canShare ? () => unawaited(_share()) : null),
      ],
    );
  }

  Widget _toggle(CircleMember x, {required bool enabled}) {
    final on = _selected?.contains(x.profileId) ?? false;
    return SizedBox(
      width: 72,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GlassPressable(
          shape: const GlassShape.circle(),
          material: GlassMaterial.content,
          enabled: enabled,
          toggled: on,
          semanticsLabel: x.name,
          onTap: () {
            glassFire(ref, on ? HapticEvent.toggleOff : HapticEvent.toggleOn);
            setState(() => on ? _selected!.remove(x.profileId) : (_selected ??= {}).add(x.profileId));
          },
          builder: (_, __) => GlassProfileOrb(preset: glassPresetFor(x.avatarKey), size: 56, friend: true, selected: on, enabled: enabled, name: x.name),
        ),
        const SizedBox(height: 4),
        ExcludeSemantics(child: GlassText(x.name, role: gt.typeCaption1, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ],),
    );
  }
}
