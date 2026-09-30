import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `SHARE SHELF` (cinematic 9.3.5): members who take shelves as avatar toggles, `CAN ADD | VIEW ONLY`
/// and `Save`; an empty selection unshares. Resolves true once saved.
Future<bool> showShareShelfSheet(BuildContext context, {required int collectionId, required String name, SharedShelfInfo? current}) async =>
    await showCineSheet<bool>(
      context,
      kicker: 'SHARE SHELF',
      title: name,
      builder: (ctx) => ShareShelfBody(collectionId: collectionId, current: current),
    ) ??
    false;

class ShareShelfBody extends ConsumerStatefulWidget {
  const ShareShelfBody({super.key, required this.collectionId, this.current});
  final int collectionId;
  final SharedShelfInfo? current;

  @override
  ConsumerState<ShareShelfBody> createState() => _ShareShelfBodyState();
}

class _ShareShelfBodyState extends ConsumerState<ShareShelfBody> {
  late final Set<int> _picked = {...?widget.current?.memberProfileIds};
  late int _mode = widget.current?.mode == 'view_only' ? 1 : 0;
  final Set<int> _gone = {};
  bool _saving = false, _failed = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final r = await ref.read(circleRepositoryProvider).shareCollection(widget.collectionId, profileIds: _picked.toList(), mode: _mode == 0 ? 'can_add' : 'view_only');
    if (!mounted) return;
    if (r.isOk) {
      ref
        ..invalidate(sharedCollectionsProvider)
        ..invalidate(sharedShelfDetailProvider(widget.collectionId))
        ..invalidate(collectionsProvider);
      Navigator.of(context).pop(true);
      return;
    }
    final e = r.error;
    setState(() {
      _saving = false;
      _failed = true;
      if (e is ApiError && e.code == 'member_unavailable') {
        final raw = e.details is Map ? (e.details! as Map)['profile_ids'] : null;
        final bad = <int>{for (final x in (raw as List? ?? const [])) (x as num).toInt()};
        _picked.removeAll(bad);
        _gone.addAll(bad);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final members = [for (final m in ref.watch(circleMembersProvider).valueOrNull ?? const <CircleMember>[]) if (m.shares.shelves && !_gone.contains(m.profileId)) m];
    final dup = <String>{}, seen = <String>{};
    for (final m in members) {
      if (!seen.add(m.name)) dup.add(m.name);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (members.isEmpty) ...[
          CineRoleText('Nobody can be added to shelves right now.', c.typeBody, color: c.colorInk60),
          SizedBox(height: c.space4),
          Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Done', variant: CineButtonVariant.secondary, onPressed: () => Navigator.of(context).pop(false))),
        ] else ...[
          Wrap(spacing: c.space4, runSpacing: c.space3, children: [
            for (final m in members)
              Semantics(
                button: true,
                toggled: _picked.contains(m.profileId),
                label: dup.contains(m.name) && m.username != null ? '${m.name} (@${m.username})' : m.name,
                excludeSemantics: true,
                onTap: () => setState(() => _picked.contains(m.profileId) ? _picked.remove(m.profileId) : _picked.add(m.profileId)),
                child: CinePressable(
                  key: ValueKey('share-${m.profileId}'),
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
          CineSegmentedControl(labels: const ['CAN ADD', 'VIEW ONLY'], index: _mode, onChanged: (i) => setState(() => _mode = i)),
          if (_failed) ...[
            SizedBox(height: c.space3),
            CineRoleText('CORRECTION', c.typeKicker, color: c.colorProof),
            CineRoleText("Couldn't update who can see this shelf.", c.typeUi),
            Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Try again', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: _saving ? null : () => unawaited(_save()))),
          ],
          SizedBox(height: c.space4),
          Align(alignment: Alignment.centerLeft, child: CineButton(key: const Key('share-save'), label: 'Save', loading: _saving, onPressed: _saving ? null : () => unawaited(_save()))),
        ],
      ],),
    );
  }
}
