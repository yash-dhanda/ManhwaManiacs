import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_password_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The bootstrap-window status while it loads or fails, shared by Login and Register: the
/// masthead only with a 24 px leader dial after 400 ms, or the unreachable notice.
class AuthStatusGate extends ConsumerWidget {
  const AuthStatusGate({super.key, required this.builder});
  final Widget Function(BuildContext context, BootstrapStatus status) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(bootstrapStatusProvider);
    return status.when(
      data: (s) => builder(context, s),
      loading: () => const Padding(padding: EdgeInsets.only(top: 32), child: Center(child: CineLeaderDial(size: 24))),
      error: (e, _) => AuthUnreachable(message: e is Exception ? _msg(e) : null),
    );
  }

  static String? _msg(Object e) => (e as dynamic).userMessage as String?;
}

/// The `CORRECTION` notice for a server that did not answer (Login and Register).
class AuthUnreachable extends ConsumerWidget {
  const AuthUnreachable({super.key, this.message, this.onRetry, this.showChangeServer = true});
  final String? message;
  final VoidCallback? onRetry;
  final bool showChangeServer;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: EdgeInsets.only(top: context.cine.space8),
        child: CineNotice(
          tone: CineNoticeTone.error,
          kicker: 'Correction',
          headline: "We couldn't reach the server.",
          deck: message,
          primary: CineNoticeAction('Try again', onRetry ?? () => ref.invalidate(bootstrapStatusProvider)),
          quiet: showChangeServer ? CineNoticeAction('Change server address', () => changeServerAddress(ref)) : null,
        ),
      );
}

/// "Change server address": Setup again, prefilled; the router's rule 1 does the rest.
Future<void> changeServerAddress(WidgetRef ref) async {
  await ref.read(preferencesProvider).setSetupCompleted(false);
  ref.invalidate(setupCompletedProvider);
}

/// Register (mobile S04, cinematic 8.4): the same Bare stack as Login plus a back arrow.
class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    return AuthFrame(
      top: Align(
        alignment: Alignment.centerLeft,
        child: CineIconButton(
          label: 'Back',
          role: CineIconRole.back,
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login()),
        ),
      ),
      footer: AuthStatusGate(
        builder: (context, s) => s.isBootstrapOpen || !s.isRegistrationOpen
            ? const SizedBox.shrink()
            : Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                CineRoleText('Already have an account?', c.typeCaption, color: c.colorInk60),
                SizedBox(width: c.space2),
                CineButton(label: 'Sign in', variant: CineButtonVariant.link, onPressed: () => context.go(Routes.login())),
              ],),
      ),
      children: [
        const AuthMasthead(),
        AuthStatusGate(
          builder: (context, s) {
            if (!s.isBootstrapOpen && !s.isRegistrationOpen) return const RegistrationClosedNotice();
            final bootstrap = s.isBootstrapOpen;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: c.space6),
              AuthKicker(bootstrap ? 'First issue' : 'Join'),
              SizedBox(height: c.space2),
              AuthHeadline(bootstrap ? 'Claim this server.' : 'Join this library.'),
              if (bootstrap) ...[
                SizedBox(height: c.space3),
                CineRoleText('Create the first account. It becomes the administrator.', c.typeDeck, color: c.colorInk60),
              ],
              SizedBox(height: c.space6),
              CineRegisterForm(bootstrap: bootstrap, inviteRequired: s.inviteCodeRequired),
            ],);
          },
        ),
      ],
    );
  }
}

class RegistrationClosedNotice extends StatelessWidget {
  const RegistrationClosedNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: context.cine.space8),
        child: CineNotice(
          tone: CineNoticeTone.caution,
          kicker: 'Registration closed',
          headline: "This library isn't taking new readers.",
          deck: 'Ask the owner to create an account for you, then sign in.',
          primary: CineNoticeAction('Back to sign in', () => context.go(Routes.login())),
        ),
      );
}

/// The registration fields and button. [bootstrap] labels the button for the administrator;
/// [inviteRequired] (or a server answer of `invite_code_required`) shows the invite field.
class CineRegisterForm extends ConsumerStatefulWidget {
  const CineRegisterForm({super.key, required this.bootstrap, this.inviteRequired = false});
  final bool bootstrap;
  final bool inviteRequired;

  @override
  ConsumerState<CineRegisterForm> createState() => _CineRegisterFormState();
}

class _CineRegisterFormState extends ConsumerState<CineRegisterForm> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _invite = TextEditingController();
  final _display = TextEditingController();
  final _email = TextEditingController();
  final _rate = RateCountdown();
  bool _remember = true;
  bool _pending = false;
  bool _inviteShown = false;
  bool _usernameRejected = false;
  bool _unreachable = false;
  bool _closed = false;
  String? _line;

  @override
  void initState() {
    super.initState();
    _inviteShown = widget.inviteRequired;
    for (final t in [_user, _pass, _confirm, _email]) {
      t.addListener(_rebuild);
    }
    _rate.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final t in [_user, _pass, _confirm, _invite, _display, _email]) {
      t.dispose();
    }
    _rate.dispose();
    super.dispose();
  }

  String? get _usernameError {
    if (_usernameRejected) return kUsernameHelper;
    return _user.text.isNotEmpty && !usernameValid(_user.text) ? kUsernameHelper : null;
  }

  bool get _valid =>
      usernameValid(_user.text) &&
      _pass.text.length >= 8 &&
      _pass.text == _confirm.text &&
      emailValid(_email.text.trim()) &&
      (!_inviteShown || _invite.text.trim().isNotEmpty);

  Future<void> _submit() async {
    if (_pending || _rate.active) return;
    setState(() {
      _line = null;
    });
    if (!_valid) return;
    setState(() => _pending = true);
    final err = await ref.read(authControllerProvider.notifier).register(
          username: _user.text.trim(),
          password: _pass.text,
          remember: _remember,
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          displayName: _display.text.trim().isEmpty ? null : _display.text.trim(),
          inviteCode: _inviteShown && _invite.text.trim().isNotEmpty ? _invite.text.trim() : null,
        );
    if (!mounted) return;
    if (err == null) {
      TextInput.finishAutofillContext();
      return; // the router Dips to the picker
    }
    final line = registerLine(err);
    setState(() {
      _pending = false;
      switch (line.kind) {
        case AuthLineKind.unreachable:
          _unreachable = true;
        case AuthLineKind.registrationClosed:
          _closed = true;
        case AuthLineKind.inviteRequired:
          _inviteShown = true;
          _line = line.text;
        case AuthLineKind.invalidUsername:
          _usernameRejected = true;
        case AuthLineKind.rateLimited:
          _rate.start(line.retryAfter ?? const Duration(seconds: 30));
        case AuthLineKind.claimedSwitchToSignIn:
          _line = line.text;
          context.go(Routes.login());
        case AuthLineKind.message:
          _line = line.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (_closed) return const RegistrationClosedNotice();
    if (_unreachable) {
      return AuthUnreachable(showChangeServer: false, onRetry: () => setState(() => _unreachable = false));
    }
    final off = _pending;
    final mismatch = passwordsMismatch(_pass.text, _confirm.text);
    final emailBad = _email.text.trim().isNotEmpty && !emailValid(_email.text.trim());
    final serverLine = _line;
    final Widget form = AutofillGroup(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CineTextField(
            label: 'Username',
            controller: _user,
            enabled: !off,
            helperText: kUsernameHelper,
            errorText: _usernameError,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newUsername],
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_usernameRejected) setState(() => _usernameRejected = false);
            },
          ),
          SizedBox(height: c.space5),
          CinePasswordField(
            label: 'Password',
            controller: _pass,
            enabled: !off,
            helperText: kPasswordHelper,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: c.space5),
          CinePasswordField(
            label: 'Confirm password',
            controller: _confirm,
            enabled: !off,
            errorText: mismatch ? kPasswordMismatch : null,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          if (_inviteShown) ...[
            SizedBox(height: c.space5),
            CineTextField(
              label: 'Invite code',
              controller: _invite,
              enabled: !off,
              helperText: 'Ask whoever invited you',
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
            ),
          ],
          SizedBox(height: c.space5),
          CineTextField(
            label: 'Display name',
            controller: _display,
            enabled: !off,
            helperText: 'How your name appears',
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: c.space5),
          CineTextField(
            label: 'Email',
            controller: _email,
            enabled: !off,
            errorText: emailBad ? kEmailError : null,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
          ),
        ],),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      form,
      SizedBox(height: c.space5),
      CineSettingsRow(
              label: 'Keep me signed in',
              control: CineSwitch(label: 'Keep me signed in', value: _remember, onChanged: off ? null : (v) => setState(() => _remember = v)),
            ),
      SizedBox(height: c.space6),
      CineButton(
        label: widget.bootstrap ? 'Create the administrator account' : 'Create account',
        loadingLabel: 'Creating account…',
        loading: _pending,
        onPressed: off || _rate.active ? null : _submit,
      ),
      if (_rate.active) ...[
        SizedBox(height: c.space3),
        Semantics(liveRegion: true, child: CineRoleText('SLOW DOWN · ${rateLimitLine(_rate.seconds)}', c.typeCaption, color: c.colorProof)),
      ],
      if (serverLine != null) AuthErrorLine(serverLine),
    ],);
  }
}
