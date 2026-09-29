import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_password_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Login (mobile S03, cinematic 8.3). Phone: the masthead, one cover line, the form; tablet: three
/// cover lines 400 ms apart. On success the form fades (160 ms `lift`) while the masthead rule
/// extends across the width (480 ms `settle`); the router then Dips to the picker.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _userNode = FocusNode(debugLabel: 'login-username');
  final _passNode = FocusNode(debugLabel: 'login-password');
  final _rate = RateCountdown();
  late final AnimationController _out;
  late final AnimationController _ext;
  bool _remember = true;
  bool _pending = false;
  bool _unreachable = false;
  bool _switchedToSignIn = false;
  String? _line;

  @override
  void initState() {
    super.initState();
    _out = AnimationController(vsync: this, duration: CineDur.beat);
    _ext = AnimationController(vsync: this, duration: CineDur.spread);
    _rate.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _userNode.requestFocus();
      if (ref.read(sessionEndReasonProvider) == SessionEndReason.signedOut) {
        ref.read(sessionEndReasonProvider.notifier).state = null;
        ref.read(cineToastsProvider.notifier).info(kSignedOutToast);
      }
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _userNode.dispose();
    _passNode.dispose();
    _rate.dispose();
    _out.dispose();
    _ext.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pending || _rate.active) return;
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _line = kEmptyCredentials);
      return;
    }
    setState(() {
      _pending = true;
      _line = null;
    });
    final err = await ref.read(authControllerProvider.notifier).login(
          username: _user.text.trim(),
          password: _pass.text,
          remember: _remember,
        );
    if (!mounted) return;
    if (err == null) {
      TextInput.finishAutofillContext();
      if (CineMotion.reduced(context)) {
        _out.duration = CineDur.reduced;
        unawaited(_out.forward());
      } else {
        unawaited(_out.forward());
        unawaited(_ext.forward());
      }
      return; // the router Dips to the picker
    }
    final line = loginLine(err);
    setState(() {
      _pending = false;
      switch (line.kind) {
        case AuthLineKind.unreachable:
          _unreachable = true;
        case AuthLineKind.rateLimited:
          _rate.start(line.retryAfter ?? const Duration(seconds: 30));
        case AuthLineKind.claimedSwitchToSignIn:
          _switchedToSignIn = true;
          _line = line.text;
        case AuthLineKind.message || AuthLineKind.registrationClosed || AuthLineKind.inviteRequired || AuthLineKind.invalidUsername:
          _line = line.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tablet = CineGrid.of(context).width >= 600;
    final status = ref.watch(bootstrapStatusProvider);
    final open = status.valueOrNull;
    final bootstrap = open != null && open.isBootstrapOpen && !_switchedToSignIn;
    final showCreate = open != null && open.isRegistrationOpen && !open.isBootstrapOpen;
    final lines = tablet ? kCoverLines : kCoverLines.take(1).toList();

    final Widget body;
    if (_unreachable || status.hasError && !status.isLoading) {
      body = AuthUnreachable(
        message: _unreachable ? null : _statusMessage(status.error),
        onRetry: () {
          setState(() => _unreachable = false);
          ref.invalidate(bootstrapStatusProvider);
        },
      );
    } else if (status.isLoading && !status.hasValue) {
      body = const AuthStatusGate(builder: _never);
    } else if (bootstrap) {
      body = _Bootstrap(inviteRequired: open.inviteCodeRequired);
    } else {
      body = _form(context);
    }

    return AuthFrame(
      footer: showCreate
          ? Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              CineRoleText('Need an account?', c.typeCaption, color: c.colorInk60),
              CineButton(label: 'Create one', variant: CineButtonVariant.link, onPressed: () => context.push(Routes.register())),
            ],)
          : null,
      children: [
        AnimatedBuilder(
          animation: _ext,
          builder: (context, _) => AuthMasthead(dateLine: true, extend: CineCurves.settle.transform(_ext.value)),
        ),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: c.space2),
          AuthCoverLine(lines[i], index: i),
        ],
        SizedBox(height: c.space6),
        AnimatedBuilder(
          animation: _out,
          builder: (context, child) => Opacity(opacity: 1 - CineCurves.lift.transform(_out.value), child: child),
          child: body,
        ),
      ],
    );
  }

  static Widget _never(BuildContext context, Object _) => const SizedBox.shrink();

  String? _statusMessage(Object? e) {
    try {
      return (e as dynamic).userMessage as String?;
    } catch (_) {
      return null;
    }
  }

  Widget _form(BuildContext context) {
    final c = context.cine;
    final base = ref.watch(apiBaseUrlProvider);
    final host = Uri.tryParse(base)?.authority ?? base;
    final off = _pending;
    final signIn = !_rate.active && !off;
    return AutofillGroup(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AuthKicker('Sign in'),
          SizedBox(height: c.space2),
          const AuthHeadline('Welcome back.'),
          SizedBox(height: c.space2),
          _ServerLine(host: host, base: base),
          SizedBox(height: c.space5),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: CineTextField(
              label: 'Username',
              controller: _user,
              focusNode: _userNode,
              enabled: !off,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _pass.text.isEmpty ? _passNode.requestFocus() : _submit(),
            ),
          ),
          SizedBox(height: c.space5),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: CinePasswordField(
              label: 'Password',
              controller: _pass,
              focusNode: _passNode,
              enabled: !off,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submit(),
            ),
          ),
          SizedBox(height: c.space5),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: CineSwitch(label: 'Keep me signed in', value: _remember, onChanged: off ? null : (v) => setState(() => _remember = v)),
          ),
          SizedBox(height: c.space6),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: CineButton(
              label: 'Sign in',
              loadingLabel: 'Signing in…',
              loading: _pending,
              onPressed: signIn ? _submit : null,
            ),
          ),
          if (_rate.active) ...[
            SizedBox(height: c.space3),
            Semantics(
              liveRegion: true,
              child: CineRoleText('SLOW DOWN · ${rateLimitLine(_rate.seconds)}', c.typeCaption, color: c.colorProof),
            ),
          ],
          AuthErrorLine(_line),
        ],),
      ),
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap({required this.inviteRequired});
  final bool inviteRequired;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const AuthKicker('First issue'),
      SizedBox(height: c.space2),
      const AuthHeadline('Claim this server.'),
      SizedBox(height: c.space3),
      CineRoleText('Create the first account. It becomes the administrator.', c.typeDeck, color: c.colorInk60),
      SizedBox(height: c.space6),
      CineRegisterForm(bootstrap: true, inviteRequired: inviteRequired),
    ],);
  }
}

/// "Server: {host}", tap to copy the whole base URL.
class _ServerLine extends ConsumerWidget {
  const _ServerLine({required this.host, required this.base});
  final String host, base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: 'Server: $host. Copy address',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: base));
          ref.read(cineToastsProvider.notifier).info('Copied $base');
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(alignment: Alignment.centerLeft, child: CineRoleText('Server: $host', c.typeCaption, color: c.colorInk45)),
        ),
      ),
    );
  }
}

