import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/admin/members.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/features/admin/providers/members_provider.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const String kMembersExplainer = 'Registration is open. Deactivating signs a member out everywhere and blocks sign-in; deleting removes everything they own.';
const String kOwnAccountLine = "You can't deactivate or delete your own account.";

String sessionsLabel(int n) => n == 0 ? 'No sessions' : (n == 1 ? '1 session' : '$n sessions');

String _date(DateTime? t) {
  if (t == null) return '–';
  const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  final l = t.toLocal();
  return '${l.day} ${m[l.month - 1]} ${l.year}';
}

/// Members (`/settings/members`, admin, cinematic 8.30.5): a block per member on phones, a table
/// from 600 dp.
class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  int? _busy;

  Future<void> _setActive(Account a, bool active) async {
    setState(() => _busy = a.id);
    final r = await ref.read(adminRepositoryProvider).setActive(id: a.id, active: active);
    if (!mounted) return;
    setState(() => _busy = null);
    if (r.isErr) {
      ref.read(cineToastsProvider.notifier).error(memberActionFailure(r.error.userMessage));
    } else {
      ref.invalidate(membersProvider);
    }
  }

  Future<void> _delete(Account a) async {
    final ok = await showCineConfirm(
      context,
      title: 'Delete @${a.username}?',
      body: "Their profiles, library, progress, bookmarks and everything else they own are removed. This can't be undone.",
      confirmLabel: 'Delete account',
      destructive: true,
      typedUsername: a.username,
      onConfirm: () async {
        final r = await ref.read(adminRepositoryProvider).deleteAccount(a.id);
        if (r.isErr) throw r.error;
      },
    );
    if (ok) ref.invalidate(membersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final members = ref.watch(membersProvider);
    final auth = ref.watch(authControllerProvider);
    final me = auth is AuthAuthenticated ? auth.user.id : null;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final now = DateTime.now();

    Widget actions(Account a, {required bool self}) => Wrap(spacing: c.space2, runSpacing: c.space1, children: [
          CineButton(
            label: a.isActive ? 'Deactivate' : 'Reactivate',
            variant: CineButtonVariant.secondary,
            size: CineButtonSize.sm,
            loading: _busy == a.id,
            disabledReason: self ? kOwnAccountLine : null,
            onPressed: self ? null : () => unawaited(_setActive(a, !a.isActive)),
          ),
          CineButton(label: 'Delete', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, disabledReason: self ? kOwnAccountLine : null, onPressed: self ? null : () => unawaited(_delete(a))),
        ],);

    Widget block(Account a) {
      final self = a.id == me;
      return Container(
        key: Key('member-${a.id}'),
        margin: EdgeInsets.only(top: c.space3),
        padding: EdgeInsets.all(c.space3),
        color: self ? c.colorPaper4 : null,
        decoration: self ? null : BoxDecoration(border: Border(bottom: c.ruleHair)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Flexible(child: CineRoleText('@${a.username}', c.typeUi)),
            if (a.isAdmin) ...[SizedBox(width: c.space2), const CineBadge('ADMIN', variant: CineBadgeVariant.admin)],
            if (self) ...[SizedBox(width: c.space2), const CineBadge('YOU', variant: CineBadgeVariant.text)],
          ],),
          CineCreditsRow(label: 'STATUS', value: a.isActive ? 'ACTIVE' : 'DEACTIVATED'),
          CineCreditsRow(label: 'JOINED', value: _date(a.createdAt)),
          CineCreditsRow(label: 'LAST SEEN', value: a.lastLoginAt == null ? 'NEVER' : agoLabel(a.lastLoginAt!, now)),
          CineCreditsRow(label: 'SESSIONS', value: sessionsLabel(a.sessionCount)),
          SizedBox(height: c.space2),
          actions(a, self: self),
          if (self) Padding(padding: EdgeInsets.only(top: c.space2), child: CineRoleText(kOwnAccountLine, c.typeCaption, color: c.colorInk60)),
        ],),
      );
    }

    Widget table(List<Account> rows) => LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: box.maxWidth < 640 ? 640 : box.maxWidth,
              child: Column(children: [
                for (final a in rows)
                  Container(
                    key: Key('member-${a.id}'),
                    padding: EdgeInsets.symmetric(vertical: c.space2, horizontal: c.space3),
                    color: a.id == me ? c.colorPaper4 : null,
                    decoration: a.id == me ? null : BoxDecoration(border: Border(bottom: c.ruleHair)),
                    child: Row(children: [
                      Expanded(flex: 3, child: CineRoleText('@${a.username}${a.isAdmin ? '  ADMIN' : ''}${a.id == me ? '  YOU' : ''}', c.typeUi)),
                      Expanded(flex: 2, child: CineRoleText(a.isActive ? 'ACTIVE' : 'DEACTIVATED', c.typeFolio, color: a.isActive ? c.colorSet : c.colorProof)),
                      Expanded(flex: 2, child: CineRoleText(_date(a.createdAt), c.typeFolio, color: c.colorInk60)),
                      Expanded(flex: 2, child: CineRoleText(a.lastLoginAt == null ? 'NEVER' : agoLabel(a.lastLoginAt!, now), c.typeFolio, color: c.colorInk60)),
                      Expanded(flex: 2, child: CineRoleText(sessionsLabel(a.sessionCount), c.typeFolio, color: c.colorInk60)),
                      Expanded(flex: 4, child: actions(a, self: a.id == me)),
                    ],),
                  ),
              ],),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CineRoleText(kMembersExplainer, c.typeCaption, color: c.colorInk60),
      SettingsAsync<List<Account>>(
        value: members,
        onRetry: () => ref.invalidate(membersProvider),
        builder: (context, all, offline) {
          final rows = sortMembers(all, currentUserId: me);
          if (rows.length <= 1 && rows.every((r) => r.id == me)) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (rows.isNotEmpty) (wide ? table(rows) : block(rows.first)),
              Padding(padding: EdgeInsets.only(top: c.space3), child: CineRoleText('Only your account so far.', c.typeCaption, color: c.colorInk60)),
            ],);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (wide) table(rows) else for (final a in rows) block(a),
            SizedBox(height: c.space3),
            Row(children: [
              Expanded(child: CineRoleText('${rows.length - 1} other accounts.', c.typeFolio, color: c.colorInk60)),
              CineButton(label: 'Refresh', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(membersProvider)),
            ],),
          ],);
        },
      ),
    ],);
  }
}
