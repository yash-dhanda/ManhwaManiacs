import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/known_accounts_provider.dart';
import 'package:manhwamaniacs/features/auth/utils/register_validation.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconRole;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/slab_condense.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Register (glass 8.4, mobile S04): Closed, Bootstrap and Open, with live validation and every server code on its field.
class GlassRegisterScreen extends ConsumerStatefulWidget {
  const GlassRegisterScreen({super.key});

  @override
  ConsumerState<GlassRegisterScreen> createState() => _GlassRegisterScreenState();
}

class _GlassRegisterScreenState extends ConsumerState<GlassRegisterScreen> with TickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _invite = TextEditingController();
  final _display = TextEditingController();
  final _email = TextEditingController();
  final _passNode = FocusNode(debugLabel: 'register-password');
  final _emailNode = FocusNode(debugLabel: 'register-email');
  final _rate = RateCountdown();
  final GlobalKey _lensBox = GlobalKey();
  late final AnimationController _out = AnimationController(vsync: this);
  late final StateController<bool> _hold;
  bool _remember = true;
  bool _pending = false;
  bool _unreachable = false;
  bool _closedByServer = false;
  bool _claimed = false;
  bool _passBlurred = false;
  bool _emailBlurred = false;
  bool _inviteRevealed = false;
  String? _line;
  final Map<AuthField, String> _fieldErrors = {};
  final Map<AuthField, int> _triggers = {for (final f in AuthField.values) f: 0};

  @override
  void initState() {
    super.initState();
    _hold = ref.read(glassRedirectHoldProvider.notifier);
    for (final c in [_username, _password, _confirm, _invite, _display, _email]) {
      c.addListener(_rebuild);
    }
    _rate.addListener(_rebuild);
    _passNode.addListener(() {
      if (!_passNode.hasFocus && _password.text.isNotEmpty) setState(() => _passBlurred = true);
    });
    _emailNode.addListener(() {
      if (!_emailNode.hasFocus && _email.text.isNotEmpty) setState(() => _emailBlurred = true);
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_username, _password, _confirm, _invite, _display, _email]) {
      c.dispose();
    }
    _passNode.dispose();
    _emailNode.dispose();
    _rate.dispose();
    _out.dispose();
    final hold = _hold;
    Future<void>.microtask(() {
      if (hold.mounted) hold.state = false;
    });
    super.dispose();
  }

  RegisterDraft get _draft => RegisterDraft(username: _username.text, password: _password.text, confirm: _confirm.text, invite: _invite.text, email: _email.text);

  bool _inviteRequired(bool bootstrap, bool serverSays) => !bootstrap && (serverSays || _inviteRevealed);

  bool _canSubmit(bool bootstrap, bool serverSays) => !_pending && !_rate.active && canSubmitRegister(_draft, inviteRequired: _inviteRequired(bootstrap, serverSays));

  Future<void> _submit(bool bootstrap, bool serverSays) async {
    if (!_canSubmit(bootstrap, serverSays)) return;
    setState(() {
      _pending = true;
      _line = null;
      _fieldErrors.clear();
    });
    _hold.state = true;
    final username = _username.text.trim();
    final err = await ref.read(authControllerProvider.notifier).register(
          username: username,
          password: _password.text,
          remember: _remember,
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          displayName: _display.text.trim().isEmpty ? null : _display.text.trim(),
          inviteCode: _invite.text.trim().isEmpty ? null : _invite.text.trim(),
        );
    if (!mounted) return;
    if (err == null) {
      try {
        await _success(username);
      } catch (_) {
        // Signed in but the hand-off threw: release the redirect hold so the guard takes the user home, never a dead form.
        if (mounted) {
          _hold.state = false;
          setState(() => _pending = false);
        }
        rethrow;
      }
      return;
    }
    _hold.state = false;
    final line = registerLine(err);
    setState(() {
      _pending = false;
      switch (line.kind) {
        case AuthLineKind.unreachable:
          _unreachable = true;
        case AuthLineKind.rateLimited:
          _rate.start(line.retryAfter ?? const Duration(seconds: 30));
          _line = rateLimitLine(_rate.seconds);
        case AuthLineKind.registrationClosed:
          _closedByServer = true;
        case AuthLineKind.claimedSwitchToSignIn:
          _claimed = true;
          _line = line.text;
        case AuthLineKind.bootstrapExpired:
          _line = line.text;
        case AuthLineKind.message:
          if (line.field == AuthField.general) {
            _line = line.text;
          } else {
            _fieldErrors[line.field] = line.text;
            _triggers[line.field] = (_triggers[line.field] ?? 0) + 1;
            if (line.field == AuthField.invite) _inviteRevealed = true;
          }
      }
    });
  }

  Future<void> _success(String username) async {
    await ref.read(knownAccountsProvider.notifier).remember(username);
    TextInput.finishAutofillContext();
    if (!mounted) return;
    final reduced = glassReduced(ref);
    final lensRect = globalRectOfKey(_lensBox);
    if (reduced) {
      unawaited(_out.animateTo(1, duration: const Duration(milliseconds: 200)));
    } else {
      unawaited(GlassMotion.play(MotionName.slabCondense, controller: _out, target: 1));
    }
    await Future<void>.delayed(Duration(milliseconds: reduced ? 200 : 160));
    if (!mounted) return;
    if (lensRect != null) {
      await playDropletLand(context, lensCentre: lensRect.center, reduced: reduced, onLand: () => glassFire(ref, HapticEvent.logoLand));
    }
    if (!mounted) return;
    await completeAuth(context, ref, lensRect: lensRect, registered: true);
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.login());

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final status = ref.watch(bootstrapStatusProvider);
    final s = status.valueOrNull;
    final statusFailed = status.hasError && !status.isLoading;
    final resolving = status.isLoading && !status.hasValue && !_unreachable;
    final unreachable = _unreachable || statusFailed;
    final bootstrap = s != null && s.isBootstrapOpen && !_claimed;
    final closed = _closedByServer || (s != null && !s.isRegistrationOpen && !s.isBootstrapOpen);
    final inviteSays = s?.inviteCodeRequired ?? false;

    final (title, subtitle) = unreachable
        ? (kUnreachableHeading, kUnreachableDetail)
        : closed
            ? ('Registration is closed', "This server isn't accepting new accounts. Ask its owner for access.")
            : bootstrap
                ? ('Claim this server', 'This first account becomes the administrator.')
                : ('Join ManhwaManiacs', 'Create an account on this server.');

    final Widget body;
    if (resolving) {
      body = const SizedBox(height: 96);
    } else if (unreachable) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassButton(
            label: 'Try again',
            size: GlassButtonSize.large,
            fullWidth: true,
            onPressed: () {
              setState(() => _unreachable = false);
              ref.invalidate(bootstrapStatusProvider);
            },
          ),
        ],
      );
    } else if (closed) {
      body = GlassButton(label: 'Back to sign in', size: GlassButtonSize.large, fullWidth: true, onPressed: _back);
    } else {
      body = _form(bootstrap: bootstrap, inviteSays: inviteSays);
    }

    final phone = !tablet;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phone)
          Align(
            alignment: Alignment.centerLeft,
            child: GlassIconButton(icon: roleIcon(GlassIconRole.back), label: 'Back to sign in', kind: GlassIconButtonKind.nav, twin: GlassTwin.content, onPressed: _back),
          ),
        Center(
          child: KeyedSubtree(
            key: _lensBox,
            child: GlassAuthLens(state: resolving || _pending ? GlassAuthLensState.spinning : (unreachable ? GlassAuthLensState.unreachable : GlassAuthLensState.mark)),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _out,
          builder: (context, child) => Opacity(opacity: (1 - _out.value * 5).clamp(0.0, 1.0), child: child),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: GlassText(title, role: gt.typeLargeTitle, textAlign: TextAlign.center)),
              const SizedBox(height: 8),
              GlassText(subtitle, role: gt.typeBody, color: unreachable ? gt.colorDanger : gt.colorLabel2, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              body,
            ],
          ),
        ),
      ],
    );
    return GlassAuthFrame(slab: true, condense: tablet ? _out : null, child: column);
  }

  Widget _form({required bool bootstrap, required bool inviteSays}) {
    final off = _pending;
    final rate = _rate.active;
    final userText = _username.text;
    final usernameErr = _fieldErrors[AuthField.username] ?? (userText.isNotEmpty && !usernameValid(userText) ? kUsernameHelper : null);
    final passErr = _fieldErrors[AuthField.password] ?? (_passBlurred && _password.text.isNotEmpty && !passwordLongEnough(_password.text) ? kPasswordHelper : null);
    final mismatch = _password.text.isNotEmpty && _confirm.text.isNotEmpty && !confirmationMatches(_password.text, _confirm.text);
    final emailErr = _emailBlurred && _email.text.isNotEmpty && !emailValidOrBlank(_email.text) ? kEmailError : null;
    final showInvite = _inviteRequired(bootstrap, inviteSays);
    return AutofillGroup(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassTextField(
              controller: _username,
              label: 'Username',
              username: true,
              autofocus: true,
              enabled: !off,
              helper: kUsernameHelper,
              error: usernameErr,
              errorTrigger: _triggers[AuthField.username]!,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _password,
              focusNode: _passNode,
              kind: GlassFieldKind.password,
              label: 'Password',
              enabled: !off,
              helper: kPasswordHelper,
              error: passErr,
              errorTrigger: _triggers[AuthField.password]!,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _confirm,
              kind: GlassFieldKind.password,
              label: 'Confirm password',
              enabled: !off,
              error: mismatch ? kPasswordMismatch : null,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            if (showInvite) ...[
              const SizedBox(height: 16),
              GlassTextField(
                controller: _invite,
                label: 'Invite code',
                hint: 'Ask whoever invited you',
                enabled: !off,
                error: _fieldErrors[AuthField.invite],
                errorTrigger: _triggers[AuthField.invite]!,
                textInputAction: TextInputAction.next,
              ),
            ],
            const SizedBox(height: 16),
            GlassTextField(
              controller: _display,
              label: 'Display name',
              hint: 'How your name appears',
              enabled: !off,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _email,
              focusNode: _emailNode,
              label: 'Email',
              enabled: !off,
              error: emailErr,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.go,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => unawaited(_submit(bootstrap, inviteSays)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: GlassText('Keep me signed in', role: gt.typeBody)),
                GlassSwitch(label: 'Keep me signed in', value: _remember, onChanged: off ? (_) {} : (v) => setState(() => _remember = v)),
              ],
            ),
            if (_line != null || rate) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: GlassFieldMessage(text: rate ? rateLimitLine(_rate.seconds) : _line, error: true)),
            ],
            const SizedBox(height: 20),
            if (_claimed)
              GlassButton(label: 'Sign in', variant: GlassButtonVariant.primary, size: GlassButtonSize.large, fullWidth: true, onPressed: () => context.go(Routes.login()))
            else
              GlassButton(
                label: rate ? rateLimitButton(_rate.seconds) : (bootstrap ? 'Create the administrator account' : 'Create account'),
                mono: rate,
                icon: bootstrap && !rate ? GlassButtonIcon.glyph(GlassGlyph30.shieldCheck) : null,
                variant: GlassButtonVariant.primary,
                size: GlassButtonSize.large,
                fullWidth: true,
                loading: _pending,
                onPressed: _canSubmit(bootstrap, inviteSays) ? () => unawaited(_submit(bootstrap, inviteSays)) : null,
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GlassText('Already have an account? ', role: gt.typeBody, color: gt.colorLabel2),
                GlassButton(label: 'Sign in', variant: GlassButtonVariant.plain, onPressed: _back),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
