import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/auth/models/user_session.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/auth/utils/session_device_label.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_password_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart' show rateLimitLine;
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const String kMsgCurrentEmpty = 'Enter your current password.';
const String kMsgNewEmpty = 'Enter a new password.';
const String kMsgNewShort = 'Password must be at least 8 characters.';
const String kMsgNewLong = 'Password is too long.';
const String kMsgMismatch = "The new passwords don't match.";
const String kMsgSame = 'Your new password must be different from your current one.';
const String kMsgWrongCurrent = "That isn't your current password.";
const String kToastChanged = 'Password changed. Every other device has been signed out.';

/// The first failing line of a password change, per field.
({String? current, String? next, String? confirm}) validatePasswordChange({required String current, required String next, required String confirm}) {
  String? c, n, f;
  if (current.isEmpty) c = kMsgCurrentEmpty;
  if (next.isEmpty) {
    n = kMsgNewEmpty;
  } else if (next.length < 8) {
    n = kMsgNewShort;
  } else if (next.length > 4096) {
    n = kMsgNewLong;
  } else if (current.isNotEmpty && next == current) {
    n = kMsgSame;
  }
  if (n == null && next.isNotEmpty && confirm != next) f = kMsgMismatch;
  return (current: c, next: n, confirm: f);
}

String _day(DateTime t) {
  const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  final l = t.toLocal();
  return '${l.day} ${m[l.month - 1]}';
}

/// Password & security (`/settings/security`, cinematic 8.30.4): change password, where you are
/// signed in, sign out everywhere.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SettingsKicker('CHANGE PASSWORD'),
        ChangePasswordForm(),
        SettingsKicker('WHERE YOU ARE SIGNED IN'),
        SessionsList(),
        SettingsKicker('SIGN OUT EVERYWHERE'),
        SignOutEverywhere(),
      ],);
}

class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _cur = TextEditingController(), _new = TextEditingController(), _conf = TextEditingController();
  final _curFocus = FocusNode(debugLabel: 'pw-current');
  final _rate = RateCountdown();
  String? _eCur, _eNew, _eConf;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rate.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _conf.dispose();
    _curFocus.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _rate.active) return;
    final v = validatePasswordChange(current: _cur.text, next: _new.text, confirm: _conf.text);
    setState(() {
      _eCur = v.current;
      _eNew = v.next;
      _eConf = v.confirm;
    });
    if (v.current != null || v.next != null || v.confirm != null) return;
    setState(() => _busy = true);
    final err = await ref.read(authControllerProvider.notifier).changePassword(currentPassword: _cur.text, newPassword: _new.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      _cur.clear();
      _new.clear();
      _conf.clear();
      ref.read(cineToastsProvider.notifier).success(kToastChanged);
      return;
    }
    if (err is ApiError) {
      if (err.code == 'invalid_credentials') {
        setState(() => _eCur = kMsgWrongCurrent);
        _curFocus.requestFocus();
        return;
      }
      if (err.code == 'weak_password') {
        setState(() => _eNew = err.message);
        return;
      }
      if (err.code == 'rate_limited' || err.statusCode == 429) {
        _rate.start(err.retryAfter ?? const Duration(seconds: 30));
        return;
      }
    }
    setState(() => _eNew = err.userMessage);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CinePasswordField(label: 'Current password', controller: _cur, focusNode: _curFocus, errorText: _eCur, textInputAction: TextInputAction.next, enabled: !_busy),
      SizedBox(height: c.space3),
      CinePasswordField(
        label: 'New password',
        controller: _new,
        helperText: 'At least 8 characters',
        errorText: _eNew,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        enabled: !_busy,
      ),
      SizedBox(height: c.space3),
      CinePasswordField(
        label: 'Confirm new password',
        controller: _conf,
        errorText: _eConf,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        enabled: !_busy,
        onSubmitted: (_) => unawaited(_submit()),
      ),
      SizedBox(height: c.space3),
      CineRoleText('Changing it signs out every other device. This one stays signed in.', c.typeCaption, color: c.colorInk60),
      if (_rate.active)
        Padding(
          padding: EdgeInsets.only(top: c.space2),
          child: Semantics(
            liveRegion: true,
            child: Row(children: [
              CineRoleText('SLOW DOWN', c.typeKicker, color: c.colorProof),
              SizedBox(width: c.space2),
              CineRoleText(rateLimitLine(_rate.seconds), c.typeCaption, color: c.colorProof),
            ],),
          ),
        ),
      SizedBox(height: c.space3),
      Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Change password', loading: _busy, onPressed: _rate.active ? null : () => unawaited(_submit()))),
    ],);
  }
}

class SessionsList extends ConsumerWidget {
  const SessionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final sessions = ref.watch(authSessionsProvider);
    final now = DateTime.now();

    Future<void> revoke(UserSession s) async {
      final label = sessionDeviceLabel(s.userAgent);
      final ok = await showCineConfirm(
        context,
        title: 'Sign out $label?',
        body: 'It will have to sign in again.',
        confirmLabel: 'Sign out',
        destructive: true,
        onConfirm: () async {
          final r = await ref.read(authRepositoryProvider).revokeSession(s.id);
          if (r.isErr) throw r.error;
        },
      );
      if (ok) ref.invalidate(authSessionsProvider);
    }

    return SettingsAsync<List<UserSession>>(
      value: sessions,
      onRetry: () => ref.invalidate(authSessionsProvider),
      builder: (context, list, offline) {
        if (list.isEmpty) return Padding(padding: EdgeInsets.symmetric(vertical: c.space3), child: CineRoleText('No active sessions.', c.typeCaption, color: c.colorInk60));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final s in list)
            Semantics(
              container: true,
              label: '${sessionDeviceLabel(s.userAgent)}${s.isCurrent ? ', this device' : ''}',
              child: Container(
                padding: EdgeInsets.symmetric(vertical: c.space3, horizontal: c.space3),
                decoration: BoxDecoration(border: Border(bottom: c.ruleHair, left: BorderSide(color: s.isCurrent ? c.colorSpot : const Color(0x00000000), width: 2))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: CineRoleText(sessionDeviceLabel(s.userAgent), c.typeUi)),
                        if (s.isCurrent) ...[SizedBox(width: c.space2), const CineBadge('THIS DEVICE', variant: CineBadgeVariant.text)],
                      ],),
                      Semantics(
                        label: folioLabel('LAST USED ${agoLabel(s.lastUsedAt, now)}'),
                        child: CineRoleText('LAST USED ${agoLabel(s.lastUsedAt, now)}${s.ipAddress == null ? '' : ' · ${s.ipAddress}'}', c.typeFolio, color: c.colorInk60),
                      ),
                      CineRoleText('SIGNED IN ${_day(s.createdAt)} · EXPIRES ${_day(s.expiresAt)}', c.typeFolio, color: c.colorInk60),
                    ],),
                  ),
                  if (s.isCurrent)
                    CineButton(label: 'Sign out', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: () => unawaited(ref.read(authControllerProvider.notifier).logout()))
                  else
                    CineButton(label: 'Revoke', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: offline ? null : () => unawaited(revoke(s))),
                ],),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: CineButton(label: 'Refresh', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(authSessionsProvider)),
          ),
        ],);
      },
    );
  }
}

class SignOutEverywhere extends ConsumerWidget {
  const SignOutEverywhere({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    return Container(
      padding: EdgeInsets.all(c.space4),
      decoration: BoxDecoration(color: c.colorProofWash, border: Border(left: BorderSide(color: c.colorProof, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText('Revokes every session, this device included. Saved chapters stay on this device.', c.typeCaption, color: c.colorInk100),
        SizedBox(height: c.space3),
        CineButton(
          label: 'Sign out everywhere',
          variant: CineButtonVariant.destructive,
          onPressed: () => unawaited(showCineConfirm(
            context,
            title: 'Sign out everywhere?',
            body: 'Every device, including this one, will have to sign in again.',
            confirmLabel: 'Sign out everywhere',
            destructive: true,
            acknowledge: 'I understand this signs me out here too',
            onConfirm: () async {
              final err = await ref.read(authControllerProvider.notifier).logoutEverywhere();
              if (err != null) throw err;
            },
          ),),
        ),
      ],),
    );
  }
}

