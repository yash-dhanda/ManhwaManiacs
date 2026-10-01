import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/user_session.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/auth/utils/password_change_check.dart';
import 'package:manhwamaniacs/features/auth/utils/session_device_label.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The line of each password issue (glass 8.25.7).
String passwordIssueLine(PasswordIssue i) => switch (i) {
      PasswordIssue.currentEmpty => 'Enter your current password',
      PasswordIssue.newEmpty => 'Enter a new password',
      PasswordIssue.tooShort => 'At least 8 characters',
      PasswordIssue.tooLong => 'Password is too long',
      PasswordIssue.mismatch => "The new passwords don't match",
      PasswordIssue.same => 'Your new password must be different',
    };

/// Signs out on this device after the "Sign out?" alert, then Login (glass 8.0.9, B5).
Future<void> glassConfirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await confirmAlert(context, title: 'Sign out?', body: "You'll need to sign in again on this device.", confirmLabel: 'Sign out', destructive: true);
  if (!ok) return;
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) GoRouter.of(context).go(Routes.login());
}

/// Settings -> Security (glass 8.25.7): change password, where you're signed in, sign out everywhere.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ChangePasswordGroup(),
        SessionsGroup(),
        SignOutEverywhereGroup(),
      ],);
}

class ChangePasswordGroup extends ConsumerStatefulWidget {
  const ChangePasswordGroup({super.key});
  @override
  ConsumerState<ChangePasswordGroup> createState() => _ChangePasswordGroupState();
}

class _ChangePasswordGroupState extends ConsumerState<ChangePasswordGroup> {
  final _cur = TextEditingController(), _new = TextEditingController(), _conf = TextEditingController();
  final _curFocus = FocusNode(debugLabel: 'current password');
  String? _eCur, _eNew, _eConf;
  int _shake = 0;
  bool _busy = false;
  int _wait = 0;
  Timer? _timer;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _conf.dispose();
    _curFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait = _wait - 1);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    if (_busy || _wait > 0) return;
    final v = checkPasswordChange(current: _cur.text, next: _new.text, confirm: _conf.text);
    setState(() {
      _eCur = v.current == null ? null : passwordIssueLine(v.current!);
      _eNew = v.next == null ? null : passwordIssueLine(v.next!);
      _eConf = v.confirm == null ? null : passwordIssueLine(v.confirm!);
    });
    if (_eCur != null || _eNew != null || _eConf != null) return;
    setState(() => _busy = true);
    final err = await ref.read(authControllerProvider.notifier).changePassword(currentPassword: _cur.text, newPassword: _new.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      _cur.clear();
      _new.clear();
      _conf.clear();
      settingsToast(ref, 'Password changed. Your other devices were signed out; this one stays signed in.', kind: GlassToastKind.success);
      return;
    }
    if (err is ApiError && err.code == 'invalid_credentials') {
      setState(() {
        _eCur = "That isn't your current password.";
        _shake++;
      });
      _curFocus.requestFocus();
      return;
    }
    if (err is ApiError && err.code == 'weak_password') {
      setState(() => _eNew = err.message);
      return;
    }
    if (err is ApiError && (err.code == 'rate_limited' || err.statusCode == 429)) {
      _countdown((err.retryAfter ?? const Duration(seconds: 30)).inSeconds);
      return;
    }
    setState(() => _eNew = err.userMessage);
  }

  @override
  Widget build(BuildContext context) => SettingsGroup(
        id: 'change-password',
        header: 'Change password',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                GlassTextField(
                  kind: GlassFieldKind.password,
                  label: 'Current password',
                  controller: _cur,
                  focusNode: _curFocus,
                  error: _eCur,
                  errorTrigger: _shake,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  kind: GlassFieldKind.password,
                  label: 'New password',
                  helper: 'At least 8 characters',
                  controller: _new,
                  error: _eNew,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  kind: GlassFieldKind.password,
                  label: 'Confirm new password',
                  controller: _conf,
                  error: _eConf,
                  enabled: !_busy,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => unawaited(_submit()),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassButton(
                    label: _wait > 0 ? 'Try again in $_wait s' : 'Change password',
                    mono: _wait > 0,
                    variant: GlassButtonVariant.primary,
                    loading: _busy,
                    onPressed: _wait > 0 || _busy ? null : () => unawaited(_submit()),
                  ),
                ),
              ],),
            ),
          ),
        ],
      );
}

Glyph _deviceGlyph(String label) => label == 'ManhwaManiacs app' ? YouGlyphs.deviceMobile : (label == 'Unknown device' ? YouGlyphs.question : YouGlyphs.browser);

class SessionsGroup extends ConsumerWidget {
  const SessionsGroup({super.key});

  Future<void> _revoke(BuildContext context, WidgetRef ref, UserSession s) async {
    final ok = await confirmAlert(context, title: 'Sign out this device?', body: 'It will have to sign in again.', confirmLabel: 'Sign out', destructive: true);
    if (!ok) return;
    final r = await ref.read(authRepositoryProvider).revokeSession(s.id);
    if (r.isErr) {
      settingsToast(ref, "Couldn't sign that device out. Try again.", kind: GlassToastKind.error);
      return;
    }
    ref.invalidate(authSessionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(authSessionsProvider);
    final now = DateTime.now();
    final offline = settingsOffline(ref);
    final header = Row(children: [
      Expanded(child: GlassText("WHERE YOU'RE SIGNED IN", role: gt.typeFootnote, wght: 600, color: gt.colorLabel2)),
      GlassIconButton(
        icon: GlassButtonIcon(YouGlyphs.arrowsClockwise.regular),
        label: 'Refresh sessions',
        loading: sessions.isLoading,
        onPressed: () => ref.invalidate(authSessionsProvider),
      ),
    ],);
    Widget body;
    if (sessions.hasError && !sessions.isLoading) {
      body = offline ? const OfflineSettingsNotice() : GlassInlineError(onRetry: () => ref.invalidate(authSessionsProvider));
    } else if (!sessions.hasValue) {
      body = const GlassRowSkeletons(4, label: 'Loading sessions');
    } else if (sessions.value!.isEmpty) {
      body = Padding(padding: GlassFrame.gutter(context, top: 16, bottom: 16, inner: 16), child: GlassText('No active sessions', role: gt.typeCallout, color: gt.colorLabel2));
    } else {
      body = SettingsGroup(children: [
        for (final s in sessions.value!) _sessionRow(context, ref, s, now, offline),
      ],);
    }
    return SettingsAnchor(
      id: 'sessions',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: GlassFrame.gutter(context, top: 8, inner: 16), child: header),
        body,
      ],),
    );
  }

  Widget _sessionRow(BuildContext context, WidgetRef ref, UserSession s, DateTime now, bool offline) {
    final label = sessionDeviceLabel(s.userAgent);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          GlyphIcon(_deviceGlyph(label), size: 24, color: gt.colorLabel2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                GlassText(label, role: gt.typeHeadline),
                if (s.isCurrent) const GlassBadge.role('This device'),
              ],),
              GlassText('Last used ${glassAgo(s.lastUsedAt, now)}${s.ipAddress == null ? '' : ' · ${s.ipAddress}'}', role: gt.typeFootnote, color: gt.colorLabel2),
              GlassText('Signed in ${glassDay(s.createdAt)} · expires ${glassDay(s.expiresAt)}', role: gt.typeFootnote, color: gt.colorLabel2),
            ],),
          ),
        ],),
      ),
    );
    final action = s.isCurrent
        ? SwipeAction(id: 'sign-out', label: 'Sign out', glyph: YouGlyphs.signOut.regular, tone: SwipeTone.danger, run: () => glassConfirmSignOut(context, ref))
        : SwipeAction(id: 'revoke', label: 'Sign out this device', glyph: YouGlyphs.signOut.regular, tone: SwipeTone.danger, run: () => _revoke(context, ref, s));
    return Semantics(
      container: true,
      label: '$label${s.isCurrent ? ', This device' : ''}',
      child: offline ? row : GlassSwipeRow(name: label, trailing: [action], child: GlassSwipeActionsSemantics(child: row)),
    );
  }
}

class SignOutEverywhereGroup extends ConsumerWidget {
  const SignOutEverywhereGroup({super.key});

  Future<void> _everywhere(BuildContext context, WidgetRef ref) async {
    final err = await ref.read(authControllerProvider.notifier).logoutEverywhere();
    if (err != null) {
      settingsToast(ref, err.userMessage, kind: GlassToastKind.error);
      return;
    }
    if (context.mounted) GoRouter.of(context).go(Routes.login());
  }

  Future<void> _alert(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Sign out everywhere?',
      body: 'Every device, including this one, will have to sign in again.',
      actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
      extra: const AcknowledgedConfirm(acknowledgement: 'I understand this signs me out here too', confirmLabel: 'Sign out everywhere'),
    );
    if ((ok ?? false) && context.mounted) await _everywhere(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsGroup(
        id: 'sign-out-everywhere',
        header: 'Sign out everywhere',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const GlassInlineNotice(message: 'Every device, including this one, will have to sign in again. Downloaded chapters stay.', variant: GlassNoticeVariant.danger),
              const SizedBox(height: 12),
              HoldToConfirm(
                label: 'Sign out everywhere',
                fallbackLabel: 'Sign out everywhere',
                onConfirm: () => unawaited(_everywhere(context, ref)),
                onRequestConfirm: () => unawaited(_alert(context, ref)),
              ),
            ],),
          ),
        ],
      );
}

/// Inside an alert: a switch the reader must turn on before the destructive button enables (glass 8.25.7).
class AcknowledgedConfirm extends StatefulWidget {
  const AcknowledgedConfirm({super.key, required this.acknowledgement, required this.confirmLabel});
  final String acknowledgement, confirmLabel;
  @override
  State<AcknowledgedConfirm> createState() => _AcknowledgedConfirmState();
}

class _AcknowledgedConfirmState extends State<AcknowledgedConfirm> {
  bool _on = false;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: GlassText(widget.acknowledgement, role: gt.typeCallout, color: gt.colorOnGlass)),
          GlassSwitch(value: _on, label: widget.acknowledgement, onChanged: (v) => setState(() => _on = v)),
        ],),
        const SizedBox(height: 12),
        GlassButton(label: widget.confirmLabel, variant: GlassButtonVariant.destructive, fullWidth: true, onPressed: _on ? () => Navigator.of(context).pop(true) : null),
      ],);
}
