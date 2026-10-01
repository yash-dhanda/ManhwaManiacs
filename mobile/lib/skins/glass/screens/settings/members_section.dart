import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/members.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/features/admin/providers/members_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Joined 27 Jul · last seen 2 h ago · 2 sessions", or "Never signed in" (glass 8.25.8).
String memberLine(Account a, DateTime now) {
  final joined = a.createdAt == null ? null : 'Joined ${glassDay(a.createdAt!)}';
  if (a.lastLoginAt == null) return [if (joined != null) joined, 'Never signed in'].join(' · ');
  return [if (joined != null) joined, 'last seen ${glassAgo(a.lastLoginAt!, now)}', '${a.sessionCount} ${a.sessionCount == 1 ? 'session' : 'sessions'}'].join(' · ');
}

/// The line a refused member action shows (glass 8.0.10).
String memberRefusal(AppError e) {
  if (e is ApiError && (e.code == 'cannot_manage_self' || e.code == 'forbidden')) return glassErrors[e.code]!.copy;
  return e is ApiError ? memberActionFailure(e.message) : e.userMessage;
}

/// Settings -> Members (glass 8.25.8, admin): phone rows with swipe and ⋯ actions, a table on tablet and desktop frames, the
/// in-alert hold to delete.
class MembersSection extends ConsumerWidget {
  const MembersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const GlassAdminGate(child: MembersBody());
}

class MembersBody extends ConsumerWidget {
  const MembersBody({super.key});

  Future<void> _setActive(WidgetRef ref, Account a, bool active) async {
    final r = await ref.read(adminRepositoryProvider).setActive(id: a.id, active: active);
    if (r.isErr) {
      settingsToast(ref, memberRefusal(r.error), kind: GlassToastKind.error);
      return;
    }
    ref.invalidate(membersProvider);
    settingsToast(ref, '${active ? 'Reactivated' : 'Deactivated'} @${a.username}', kind: GlassToastKind.success);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Account a) async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Delete @${a.username}?',
      body: "This removes their profiles, library, progress, bookmarks and everything else they own. It can't be undone.",
      actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
      extra: Builder(
        builder: (c) => HoldToConfirm(
          mode: HoldMode.inAlert,
          label: 'Hold to delete @${a.username}',
          fallbackLabel: 'Delete @${a.username}',
          onConfirm: () => Navigator.of(c).pop(true),
        ),
      ),
    );
    if (!(ok ?? false)) return;
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.deleteConfirm));
    final r = await ref.read(adminRepositoryProvider).deleteAccount(a.id);
    if (r.isErr) {
      settingsToast(ref, memberRefusal(r.error), kind: GlassToastKind.error);
      return;
    }
    ref.invalidate(membersProvider);
    settingsToast(ref, 'Deleted @${a.username}', kind: GlassToastKind.success);
  }

  List<SwipeAction> _actions(BuildContext context, WidgetRef ref, Account a) => [
        SwipeAction(
          id: a.isActive ? 'deactivate' : 'reactivate',
          label: a.isActive ? 'Deactivate' : 'Reactivate',
          glyph: YouGlyphs.userSwitch.regular,
          tone: SwipeTone.warning,
          run: () => _setActive(ref, a, !a.isActive),
        ),
        SwipeAction(id: 'delete', label: 'Delete', glyph: YouGlyphs.signOut.regular, tone: SwipeTone.danger, run: () => _delete(context, ref, a)),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final me = glassUser(ref)?.id;
    final now = DateTime.now();
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    Widget body;
    if (members.hasError && !members.isLoading) {
      body = settingsOffline(ref) ? const OfflineSettingsNotice() : GlassInlineError(onRetry: () => ref.invalidate(membersProvider));
    } else if (!members.hasValue) {
      body = const GlassRowSkeletons(3, label: 'Loading members');
    } else {
      final list = sortMembers(members.value!, currentUserId: me);
      final others = list.where((a) => a.id != me).length;
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (others == 0)
          Padding(padding: const EdgeInsets.all(16), child: GlassText('Only your account so far', role: gt.typeCallout, color: gt.colorLabel2)),
        if (wide) _MembersTable(accounts: list, me: me, now: now, onActive: (a, v) => _setActive(ref, a, v), onDelete: (a) => _delete(context, ref, a)) else SettingsGroup(children: [for (final a in list) _row(context, ref, a, me, now)]),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 4, 16, 16),
          child: Row(children: [
            Expanded(child: GlassText('$others other ${others == 1 ? 'account' : 'accounts'}', role: gt.typeFootnote, color: gt.colorLabel2)),
            GlassButton(label: 'Refresh', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.invalidate(membersProvider)),
          ],),
        ),
      ],);
    }
    return SettingsAnchor(
      id: 'members',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
          child: GlassText(
            "Registration is open on this server. Deactivating keeps an account's data and signs it out everywhere; deleting removes the account and everything it owns.",
            role: gt.typeFootnote,
            color: gt.colorLabel2,
          ),
        ),
        body,
      ],),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Account a, int? me, DateTime now) {
    final guard = memberRowGuard(a, currentUserId: me);
    final badges = [
      if (a.isAdmin) 'Admin',
      if (guard.isSelf) 'You',
      if (!a.isActive) 'Deactivated',
    ];
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            GlassText('@${a.username}', role: gt.typeHeadline),
            for (final b in badges) GlassBadge.role(b),
          ],),
          GlassText(guard.isSelf ? "You can't deactivate or delete your own account" : memberLine(a, now), role: gt.typeFootnote, color: gt.colorLabel2),
        ],),
      ),
    );
    return Semantics(
      container: true,
      label: ['@${a.username}', ...badges].join(', '),
      child: guard.canManage ? GlassSwipeRow(name: '@${a.username}', trailing: _actions(context, ref, a), child: GlassSwipeActionsSemantics(child: row)) : row,
    );
  }
}

/// The tablet and desktop table: min 640 px inside its own horizontal scroll view; the own row tinted `iris600` at 6 %.
class _MembersTable extends StatelessWidget {
  const _MembersTable({required this.accounts, required this.me, required this.now, required this.onActive, required this.onDelete});
  final List<Account> accounts;
  final int? me;
  final DateTime now;
  final void Function(Account a, bool active) onActive;
  final void Function(Account a) onDelete;

  static const _cols = <double>[180, 120, 100, 120, 80, 260];

  Widget _cell(int i, Widget child) => SizedBox(width: _cols[i], child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: child));

  @override
  Widget build(BuildContext context) {
    Widget head(int i, String t) => _cell(i, Semantics(header: true, child: GlassText(t.toUpperCase(), role: gt.typeFootnote, wght: 600, color: gt.colorLabel2)));
    return Semantics(
      label: 'Members',
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 640),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [head(0, 'Member'), head(1, 'Status'), head(2, 'Joined'), head(3, 'Last seen'), head(4, 'Sessions'), head(5, 'Actions')]),
              for (final a in accounts) _tableRow(a),
            ],),
          ),
        ),
      ),
    );
  }

  Widget _tableRow(Account a) {
    final guard = memberRowGuard(a, currentUserId: me);
    final status = [if (a.isAdmin) 'Admin', if (guard.isSelf) 'You', a.isActive ? 'Active' : 'Deactivated'].join(' · ');
    return Container(
      color: guard.isSelf ? GlassColors.iris600.withValues(alpha: 0.06) : null,
      child: Row(children: [
        _cell(0, GlassText('@${a.username}', role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis)),
        _cell(1, GlassText(status, role: gt.typeFootnote, color: gt.colorLabel2)),
        _cell(2, GlassText(a.createdAt == null ? '—' : glassDay(a.createdAt!), role: gt.typeFootnote)),
        _cell(3, GlassText(a.lastLoginAt == null ? 'Never' : glassAgo(a.lastLoginAt!, now), role: gt.typeFootnote)),
        _cell(4, GlassText('${a.sessionCount}', role: gt.typeMono)),
        _cell(
          5,
          guard.canManage
              ? Wrap(spacing: 8, children: [
                  GlassButton(label: a.isActive ? 'Deactivate' : 'Reactivate', onPressed: () => onActive(a, !a.isActive)),
                  GlassButton(label: 'Delete', onPressed: () => onDelete(a)),
                ],)
              : GlassText("You can't deactivate or delete your own account", role: gt.typeFootnote, color: gt.colorLabel2),
        ),
      ],),
    );
  }
}
