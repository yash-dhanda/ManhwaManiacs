import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/known_accounts_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/slab_condense.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_targets.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Login (glass 8.3, mobile S02 and S03): a typed "Welcome back", the server row, the known accounts, the form, and the Slab
/// condense into the lens on success.
class GlassLoginScreen extends ConsumerStatefulWidget {
  const GlassLoginScreen({super.key, this.user});

  /// `?user=` from the signed-out alert: fills Username and focuses Password.
  final String? user;

  @override
  ConsumerState<GlassLoginScreen> createState() => _GlassLoginScreenState();
}

class _GlassLoginScreenState extends ConsumerState<GlassLoginScreen> with TickerProviderStateMixin {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _userNode = FocusNode(debugLabel: 'login-username');
  final _passNode = FocusNode(debugLabel: 'login-password');
  final _rate = RateCountdown();
  final GlobalKey _lensBox = GlobalKey();
  late final AnimationController _out = AnimationController(vsync: this);
  late final VoidCallback _unregister;
  late final StateController<bool> _hold;
  bool _remember = true;
  bool _pending = false;
  bool _unreachable = false;
  bool _switchedToSignIn = false;
  String? _line;
  int _errorTrigger = 0;

  @override
  void initState() {
    super.initState();
    _hold = ref.read(glassRedirectHoldProvider.notifier);
    _unregister = registerSplashTarget(GlassSplashTarget.login, _lensBox);
    _rate.addListener(_rebuild);
    _user.addListener(_rebuild);
    final prefill = widget.user;
    if (prefill != null && prefill.isNotEmpty) {
      _user.text = prefill;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passNode.requestFocus();
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _unregister();
    _rate.dispose();
    _user.dispose();
    _pass.dispose();
    _userNode.dispose();
    _passNode.dispose();
    _out.dispose();
    final hold = _hold;
    Future<void>.microtask(() {
      if (hold.mounted) hold.state = false;
    });
    super.dispose();
  }

  bool get _canSubmit => _user.text.trim().isNotEmpty && _pass.text.isNotEmpty && !_pending && !_rate.active;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _pending = true;
      _line = null;
    });
    _hold.state = true;
    final username = _user.text.trim();
    final err = await ref.read(authControllerProvider.notifier).login(username: username, password: _pass.text, remember: _remember);
    if (!mounted) return;
    if (err == null) {
      await _success(username);
      return;
    }
    _hold.state = false;
    final line = loginLine(err);
    setState(() {
      _pending = false;
      _errorTrigger++;
      switch (line.kind) {
        case AuthLineKind.unreachable:
          _unreachable = true;
        case AuthLineKind.rateLimited:
          _rate.start(line.retryAfter ?? const Duration(seconds: 30));
          _line = rateLimitLine(_rate.seconds);
        case AuthLineKind.claimedSwitchToSignIn:
          _switchedToSignIn = true;
          _line = line.text;
        case AuthLineKind.message || AuthLineKind.registrationClosed || AuthLineKind.bootstrapExpired:
          _line = line.text;
      }
    });
    if (line.field == AuthField.username) _userNode.requestFocus();
  }

  Future<void> _success(String username) async {
    await ref.read(knownAccountsProvider.notifier).remember(username);
    TextInput.finishAutofillContext();
    if (!mounted) return;
    final reduced = glassReduced(ref);
    final lensRect = globalRectOfKey(_lensBox);
    // The column's contents fade (120 ms) and the slab shrinks into a droplet, then the droplet falls into the lens.
    if (reduced) {
      _out.value = 0;
      unawaited(_out.animateTo(1, duration: const Duration(milliseconds: 200)));
    } else {
      unawaited(GlassMotion.play(MotionName.slabCondense, controller: _out, target: 1));
    }
    await Future<void>.delayed(Duration(milliseconds: reduced ? 200 : 160));
    if (!mounted) return;
    if (lensRect != null) {
      await playDropletLand(
        context,
        lensCentre: lensRect.center,
        reduced: reduced,
        onLand: () => glassFire(ref, HapticEvent.logoLand),
      );
    }
    if (!mounted) return;
    await completeAuth(context, ref, lensRect: lensRect);
  }

  Future<void> _changeServer() async {
    await ref.read(preferencesProvider).setSetupCompleted(false);
    ref.invalidate(setupCompletedProvider);
  }

  Future<void> _copyServer(String base) async {
    await Clipboard.setData(ClipboardData(text: base));
    if (mounted) showGlassToast(ref, GlassToastSpec('Copied $base'));
  }

  String _statusMessage(Object? e) => e is AppError ? e.userMessage : kUnreachableDetail;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final status = ref.watch(bootstrapStatusProvider);
    final open = status.valueOrNull;
    final bootstrap = open != null && open.isBootstrapOpen && !_switchedToSignIn;
    final showCreate = open != null && open.isRegistrationOpen && !open.isBootstrapOpen;
    final statusFailed = status.hasError && !status.isLoading;
    final resolving = status.isLoading && !status.hasValue && !_unreachable;
    final unreachable = _unreachable || statusFailed;

    final lensState = resolving || _pending
        ? GlassAuthLensState.spinning
        : unreachable
            ? GlassAuthLensState.unreachable
            : GlassAuthLensState.mark;

    final Widget body;
    if (resolving) {
      body = const SizedBox(height: 96);
    } else if (unreachable) {
      body = _Unreachable(
        detail: _unreachable ? kNetworkLine : _statusMessage(status.error),
        onRetry: () {
          setState(() => _unreachable = false);
          ref.invalidate(bootstrapStatusProvider);
        },
        onChange: _changeServer,
      );
    } else if (bootstrap) {
      body = _Bootstrap(onCreate: () => context.push(Routes.register()));
    } else {
      body = _form(showCreate: showCreate);
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: KeyedSubtree(key: _lensBox, child: GlassAuthLens(state: lensState)),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _out,
          builder: (context, child) => Opacity(opacity: (1 - _out.value * (1 / 0.2)).clamp(0.0, 1.0), child: child),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: unreachable
                    ? Semantics(header: true, child: GlassText(kUnreachableHeading, role: gt.typeLargeTitle, textAlign: TextAlign.center))
                    : resolving
                        ? const SizedBox(height: 41)
                        : TypedHeadline(bootstrap ? kBootstrapHeading : kLoginHeading, role: gt.typeLargeTitle, placement: bootstrap ? 'login.bootstrap' : 'login.heading', headingLevel: 1, textAlign: TextAlign.center),
              ),
              if (!unreachable && !resolving) ...[
                const SizedBox(height: 8),
                GlassText(bootstrap ? kBootstrapSubtitle : kLoginSubtitle, role: gt.typeBody, color: gt.colorLabel2, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              body,
            ],
          ),
        ),
      ],
    );
    return GlassAuthFrame(slab: true, condense: tablet ? _out : null, child: column);
  }

  Widget _form({required bool showCreate}) {
    final base = ref.watch(apiBaseUrlProvider);
    final host = Uri.tryParse(base)?.authority ?? base;
    final known = ref.watch(knownAccountsProvider);
    final off = _pending;
    final rate = _rate.active;
    return AutofillGroup(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ServerRow(host: host, onCopy: () => _copyServer(base), onChange: _changeServer),
            const SizedBox(height: 16),
            if (known.isNotEmpty && _user.text.isEmpty) ...[
              GlassChipRow(
                children: [
                  for (final name in known)
                    GlassChip(
                      label: name,
                      kind: GlassChipKind.input,
                      onPressed: () {
                        _user.text = name;
                        _passNode.requestFocus();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: GlassTextField(
                controller: _user,
                focusNode: _userNode,
                label: 'Username',
                username: true,
                enabled: !off,
                autofocus: widget.user == null || widget.user!.isEmpty,
                errorTrigger: _errorTrigger,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                onSubmitted: (_) => _pass.text.isEmpty ? _passNode.requestFocus() : unawaited(_submit()),
              ),
            ),
            const SizedBox(height: 16),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: GlassTextField(
                controller: _pass,
                focusNode: _passNode,
                kind: GlassFieldKind.password,
                label: 'Password',
                enabled: !off,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => _rebuild(),
                onSubmitted: (_) => unawaited(_submit()),
              ),
            ),
            const SizedBox(height: 16),
            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: Row(
                children: [
                  Expanded(child: GlassText('Keep me signed in', role: gt.typeBody)),
                  GlassSwitch(label: 'Keep me signed in', value: _remember, onChanged: off ? (_) {} : (v) => setState(() => _remember = v)),
                ],
              ),
            ),
            if (_line != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: GlassFieldMessage(text: rate ? rateLimitLine(_rate.seconds) : _line, error: true)),
            ],
            const SizedBox(height: 20),
            FocusTraversalOrder(
              order: const NumericFocusOrder(5),
              child: GlassButton(
                label: rate ? rateLimitButton(_rate.seconds) : 'Sign in',
                mono: rate,
                variant: GlassButtonVariant.primary,
                size: GlassButtonSize.large,
                fullWidth: true,
                loading: _pending,
                onPressed: _canSubmit ? () => unawaited(_submit()) : null,
              ),
            ),
            if (showCreate) ...[
              const SizedBox(height: 16),
              FocusTraversalOrder(
                order: const NumericFocusOrder(6),
                child: _FooterLink(lead: 'Need an account?', link: 'Create one', onTap: () => context.push(Routes.register())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.host, required this.onCopy, required this.onChange});
  final String host;
  final VoidCallback onCopy;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final server = GlassPressable(
            material: GlassMaterial.content,
            sink: 0.98,
            onTap: onCopy,
            semanticsLabel: 'Copy server address',
            tooltip: 'Copy server address',
            builder: (context, info) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: hit),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: GlassText('Server: $host', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  GlyphIcon(GlassGlyph30.copy, size: 16, color: gt.colorLabel2),
                ],
              ),
            ),
          );
    final change = GlassButton(label: 'Change server', variant: GlassButtonVariant.plain, onPressed: onChange);
    // From 1.6 the two no longer fit side by side (3.3 rule 4: rows stack).
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.6) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [server, change]);
    }
    return Row(children: [Expanded(child: server), change]);
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.lead, required this.link, required this.onTap});
  final String lead;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GlassText('$lead ', role: gt.typeBody, color: gt.colorLabel2),
          GlassButton(label: link, variant: GlassButtonVariant.plain, onPressed: onTap),
        ],
      );
}

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.detail, required this.onRetry, required this.onChange});
  final String detail;
  final VoidCallback onRetry;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(liveRegion: true, child: GlassText(detail, role: gt.typeBody, color: gt.colorDanger, textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          GlassButton(label: 'Try again', size: GlassButtonSize.large, fullWidth: true, onPressed: onRetry),
          const SizedBox(height: 8),
          Center(child: GlassButton(label: 'Change server', variant: GlassButtonVariant.plain, onPressed: onChange)),
        ],
      );
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => GlassButton(
        label: 'Create the first account',
        variant: GlassButtonVariant.primary,
        size: GlassButtonSize.large,
        fullWidth: true,
        onPressed: onCreate,
      );
}
