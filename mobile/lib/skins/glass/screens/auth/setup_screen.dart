import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/address_drain.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/setup_copy.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_targets.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Setup (glass 8.1, mobile S01): the server address. The lens is the splash target; Connect checks the address, saves it, then the
/// Address drain carries the text into the lens and the lens opens onto Login.
class GlassSetupScreen extends ConsumerStatefulWidget {
  const GlassSetupScreen({super.key, this.releaseBuild = kReleaseMode});

  /// Shows the "https is required." helper (the real check gets the same flag from `serverCheckProvider`).
  final bool releaseBuild;

  @override
  ConsumerState<GlassSetupScreen> createState() => _GlassSetupScreenState();
}

enum _Phase { idle, validating, draining }

class _GlassSetupScreenState extends ConsumerState<GlassSetupScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _url;
  final GlobalKey _lensBox = GlobalKey();
  final GlobalKey _fieldKey = GlobalKey();
  final GlobalKey<GlassAuthLensHandle> _lens = GlobalKey<GlassAuthLensHandle>();
  late final AnimationController _swell = AnimationController(vsync: this);
  late final VoidCallback _unregister;
  late final StateController<bool> _hold;
  _Phase _phase = _Phase.idle;
  String? _error;
  int _errorTrigger = 0;
  bool _offline = false;
  bool _reachable = false;
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    final current = ref.read(apiBaseUrlProvider);
    _url = TextEditingController(text: current == Env.defaultApiUrl ? '' : current);
    _hold = ref.read(glassRedirectHoldProvider.notifier);
    _unregister = registerSplashTarget(GlassSplashTarget.setup, _lensBox);
    ref.listenManual<AsyncValue<bool>>(networkOnlineChangesProvider, (prev, next) {
      final online = next.valueOrNull;
      if (online == null || !mounted) return;
      if (!online) {
        setState(() => _offline = true);
        return;
      }
      final was = _offline;
      setState(() => _offline = false);
      if (was && _phase == _Phase.idle && _url.text.trim().isNotEmpty && _cooledDown()) unawaited(_connect());
    });
  }

  bool _cooledDown() => _lastCheck == null || DateTime.now().difference(_lastCheck!) >= const Duration(seconds: 3);

  @override
  void dispose() {
    _unregister();
    _swell.dispose();
    _url.dispose();
    final hold = _hold;
    Future<void>.microtask(() {
      if (hold.mounted) hold.state = false;
    });
    super.dispose();
  }

  void _fail(String line) {
    setState(() {
      _phase = _Phase.idle;
      _error = line;
      _errorTrigger++;
      _reachable = false;
    });
  }

  Future<void> _connect() async {
    if (_phase != _Phase.idle || _offline) return;
    _lastCheck = DateTime.now();
    glassFire(ref, HapticEvent.tapPrimary);
    final input = _url.text.trim();
    if (input.isEmpty) {
      _fail(setupFailureLine(const ServerCheck.unreachable(''))!);
      return;
    }
    setState(() {
      _phase = _Phase.validating;
      _error = null;
    });
    final check = await ref.read(serverCheckProvider)(input);
    if (!mounted) return;
    if (check is! ServerCheckOk) {
      if (check is ServerCheckOffline) _offline = true;
      _fail(setupFailureLine(check)!);
      return;
    }
    _hold.state = true;
    final saveError = await ref.read(settingsActionsProvider).saveApiUrl(check.normalisedUrl);
    if (!mounted) return;
    if (saveError != null) {
      _hold.state = false;
      _fail(saveError.userMessage);
      return;
    }
    await ref.read(preferencesProvider).setSetupCompleted(true);
    if (!mounted) return;
    ref.invalidate(setupCompletedProvider);
    setState(() {
      _reachable = true;
      _phase = _Phase.draining;
    });
    await _leave();
  }

  Future<void> _leave() async {
    final reduced = glassReduced(ref);
    final lensRect = globalRectOfKey(_lensBox);
    final fieldRect = globalRectOfKey(_fieldKey);
    final router = GoRouter.of(context);
    final hold = _hold;
    final style = roleStyle(context, gt.typeBody).copyWith(color: gt.colorLabel1);
    final text = _url.text.trim();
    void cover() {
      router.go(Routes.login());
      hold.state = false;
    }

    if (lensRect == null || fieldRect == null) {
      cover();
      return;
    }
    final textRect = Rect.fromLTRB(fieldRect.left + 46, fieldRect.center.dy - 12, fieldRect.right - 40, fieldRect.center.dy + 12);
    await playAddressDrain(
      context,
      text: text,
      textRect: textRect,
      lensRect: lensRect,
      style: style,
      reduced: reduced,
      onImpact: () {
        if (!mounted) return;
        _lens.currentState?.flashRim();
        unawaited(GlassMotion.play(MotionName.drain, controller: _swell, target: 1));
      },
      onCovered: cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _phase != _Phase.idle;
    final hasDefault = Env.defaultApiUrl.isNotEmpty;
    return GlassAuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: KeyedSubtree(
              key: _lensBox,
              child: AnimatedBuilder(
                animation: _swell,
                builder: (context, child) => Transform.scale(scale: 1 + 0.2 * _swell.value, child: child),
                child: GlassAuthLens(key: _lens, size: 72, state: _phase == _Phase.validating ? GlassAuthLensState.spinning : GlassAuthLensState.mark),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LetterReveal(kSetupTitle, role: gt.typeLargeTitle, screenId: 'setup', revealKey: 'title', headingLevel: 1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Semantics(
            child: GlassText(kSetupSubtitle, role: gt.typeBody, color: gt.colorLabel2, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          KeyedSubtree(
            key: _fieldKey,
            child: GlassTextField(
              controller: _url,
              kind: GlassFieldKind.url,
              label: kSetupLabel,
              hint: kSetupPlaceholder,
              helper: widget.releaseBuild ? kSetupHttpsHelper : null,
              error: _error,
              errorTrigger: _errorTrigger,
              enabled: !busy,
              validating: _phase == _Phase.validating,
              reachable: _reachable,
              autofillHints: const [AutofillHints.url],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => unawaited(_connect()),
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Connect',
            variant: GlassButtonVariant.primary,
            size: GlassButtonSize.large,
            fullWidth: true,
            loading: _phase == _Phase.validating,
            onPressed: busy || _offline ? null : () => unawaited(_connect()),
            disabledReason: _offline ? kSetupOffline : null,
          ),
          if (hasDefault) ...[
            const SizedBox(height: 8),
            Center(
              child: GlassButton(
                label: 'Use the default address',
                variant: GlassButtonVariant.plain,
                onPressed: busy
                    ? null
                    : () {
                        _url.text = Env.defaultApiUrl;
                        unawaited(_connect());
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
