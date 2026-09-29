import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Manage profiles (cinematic 8.6): the account's profiles as reorderable rows with `Use`, edit,
/// delete (armed) and a Move menu; `New profile` is disabled at five.
class ProfilesManageScreen extends ConsumerStatefulWidget {
  const ProfilesManageScreen({super.key});

  @override
  ConsumerState<ProfilesManageScreen> createState() => _ProfilesManageScreenState();
}

class _ProfilesManageScreenState extends ConsumerState<ProfilesManageScreen> {
  List<Profile>? _order;

  Future<void> _move(List<Profile> current, int from, int to) async {
    final next = [...current];
    final moved = next.removeAt(from);
    next.insert(to, moved);
    setState(() => _order = next);
    final notifier = ref.read(profilesProvider.notifier);
    for (var i = 0; i < next.length; i++) {
      if (next[i].sortOrder != i || current[i].id != next[i].id) {
        final err = await notifier.edit(next[i].id, sortOrder: i);
        if (err != null && mounted) {
          ref.read(cineToastsProvider.notifier).error(profileSaveError(err));
          setState(() => _order = null);
          return;
        }
      }
    }
  }

  Future<void> _use(Profile p) async {
    await ref.read(activeProfileProvider.notifier).select(p);
    ref.read(profileSessionReadyProvider.notifier).enter();
    if (mounted) ref.read(cineToastsProvider.notifier).info(readingAsToast(p.name));
  }

  Future<void> _delete(Profile p) async {
    final ok = await showCineConfirm(
      context,
      title: deleteTitle(p.name),
      body: kDeleteBody,
      confirmLabel: 'Delete profile',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final wasActive = ref.read(activeProfileProvider)?.id == p.id;
    final err = await ref.read(profilesProvider.notifier).delete(p.id);
    if (!mounted) return;
    if (err != null) {
      ref.read(cineToastsProvider.notifier).error(profileSaveError(err));
      return;
    }
    setState(() => _order = null);
    ref.read(cineToastsProvider.notifier).info(deletedToast(p.name));
    if (wasActive) context.go(Routes.profiles());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final profiles = ref.watch(profilesProvider);
    final active = ref.watch(activeProfileProvider);
    final list = profiles.valueOrNull;
    final rows = _order != null && list != null && _order!.length == list.length ? _order! : list;
    final atLimit = (rows?.length ?? 0) >= kMaxProfiles;

    Widget body;
    if (profiles.isLoading && rows == null) {
      body = Column(children: [for (var i = 0; i < 5; i++) const CineRow(title: '', loading: true)]);
    } else if (profiles.hasError && rows == null) {
      body = CineNotice(
        tone: CineNoticeTone.error,
        kicker: 'Correction',
        headline: "We couldn't load the profiles.",
        deck: "The server isn't answering.",
        primary: CineNoticeAction('Retry', () => ref.invalidate(profilesProvider)),
      );
    } else if (rows!.isEmpty) {
      body = CineNotice(
        tone: CineNoticeTone.empty,
        kicker: 'Nothing here yet',
        headline: 'No profiles yet.',
        deck: kEmptyHouseDeck,
        primary: CineNoticeAction('New profile', () => context.push(Routes.profileNew())),
      );
    } else {
      body = CineReorderableList<Profile>(
        items: rows,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        idOf: (p) => p.id,
        titleOf: (p) => p.name,
        onMove: (from, to) => unawaited(_move(rows, from, to)),
        itemBuilder: (context, p, index, handle, moveEntries, semantics) {
          final current = active?.id == p.id;
          final wide = MediaQuery.sizeOf(context).width >= 600;
          final actions = Wrap(spacing: c.space2, runSpacing: c.space1, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (!current) CineButton(label: 'Use', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => _use(p)),
            CineIconButton(label: 'Edit ${p.name}', role: CineIconRole.edit, onPressed: () => context.push(Routes.profileEdit(p.id))),
            CineIconButton(label: 'Delete ${p.name}', role: CineIconRole.delete, onPressed: () => _delete(p)),
          ],);
          final who = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Flexible(child: CineRoleText(p.name, c.typeTitle)),
              if (current) Padding(padding: EdgeInsets.only(left: c.space2), child: const CineBadge('CURRENT', variant: CineBadgeVariant.you)),
            ],),
            CineRoleText(manageCaption(mood: p.mood.wire, adult: p.matureContentEnabled), c.typeCaption, color: c.colorInk45),
          ],);
          return CineRowShell(
            minHeight: 72,
            current: current,
            handle: handle,
            menu: moveEntries,
            semanticActions: semantics,
            semanticLabel: '${p.name}, ${manageCaption(mood: p.mood.wire, adult: p.matureContentEnabled)}',
            child: wide
                ? Row(children: [CineAvatar(avatarKey: p.avatarKey), SizedBox(width: c.space4), Expanded(child: who), actions])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [CineAvatar(avatarKey: p.avatarKey), SizedBox(width: c.space4), Expanded(child: who)]),
                    SizedBox(height: c.space2),
                    actions,
                  ],),
          );
        },
      );
    }

    return CineScaffold(
      runningTitle: 'PROFILES',
      back: const CineBack(),
      firstRunNote: false,
      body: _WithTop(builder: (top) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(c.space4, top + c.space6, c.space4, c.space12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CineMasthead(kicker: 'YOUR ACCOUNT', title: 'Profiles', deck: 'Up to five reading profiles on this account.', id: 'profiles-manage'),
          body,
          if (rows != null && rows.isNotEmpty) ...[
            SizedBox(height: c.space6),
            CineButton(
              label: 'New profile',
              disabledReason: atLimit ? kLimitLine : null,
              onPressed: atLimit ? null : () => context.push(Routes.profileNew()),
            ),
          ],
        ],),
      ),),
    );
  }
}

/// Hands its builder the height the running head takes, which the scaffold reports to what sits inside it.
class _WithTop extends StatelessWidget {
  const _WithTop({required this.builder});
  final Widget Function(double top) builder;

  @override
  Widget build(BuildContext context) => builder(CineScaffoldScope.topExtentOf(context));
}
