import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Setup (mobile S01, cinematic 8.1): the server address. On success the field's underline
/// thickens into the Oxford rule and slides up to the masthead rule (480 ms `turn`) while the rest
/// fades (240 ms `lift`), then the router Dips to Login. Reduced motion: a 150 ms fade.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.releaseBuild = kReleaseMode});

  /// Shows the HTTPS caption; the real check gets the same flag from `serverCheckProvider`.
  final bool releaseBuild;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

enum _Phase { idle, validating, connected, moving }

class _SetupScreenState extends ConsumerState<SetupScreen> with TickerProviderStateMixin {
  late final TextEditingController _url;
  final GlobalKey _stack = GlobalKey();
  final GlobalKey _fieldKey = GlobalKey();
  final GlobalKey _ruleKey = GlobalKey();
  late final AnimationController _move;
  late final AnimationController _fade;
  _Phase _phase = _Phase.idle;
  String? _error;
  Rect? _from, _to;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this, duration: CineDur.spread);
    _fade = AnimationController(vsync: this, duration: CineDur.line);
    final current = ref.read(apiBaseUrlProvider);
    _url = TextEditingController(text: current == Env.defaultApiUrl ? '' : current);
  }

  @override
  void dispose() {
    _url.dispose();
    _move.dispose();
    _fade.dispose();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey k, {required bool bottom}) {
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize) return null;
    final o = box.localToGlobal(Offset.zero, ancestor: stack);
    return Rect.fromLTWH(o.dx, bottom ? o.dy + box.size.height : o.dy, box.size.width, 0);
  }

  Future<void> _submit() async {
    if (_phase != _Phase.idle) return;
    final input = _url.text.trim();
    cineFeedback(context, HapticEvent.tapPrimary);
    if (input.isEmpty) {
      setState(() => _error = setupErrorLine(const ServerCheck.unreachable('')));
      return;
    }
    setState(() {
      _phase = _Phase.validating;
      _error = null;
    });
    final check = await ref.read(serverCheckProvider)(input);
    if (!mounted) return;
    if (check is! ServerCheckOk) {
      setState(() {
        _phase = _Phase.idle;
        _error = setupErrorLine(check);
      });
      return;
    }
    final saveError = await ref.read(settingsActionsProvider).saveApiUrl(check.normalisedUrl);
    if (!mounted) return;
    if (saveError != null) {
      setState(() {
        _phase = _Phase.idle;
        _error = saveError.userMessage;
      });
      return;
    }
    setState(() => _phase = _Phase.connected);
    await Future<void>.delayed(CineDur.holdConnected);
    if (!mounted) return;
    await _leave();
  }

  Future<void> _leave() async {
    final reduced = CineMotion.reduced(context);
    if (reduced) {
      _fade.duration = CineDur.reduced;
      await _fade.forward();
    } else {
      _from = _rectOf(_fieldKey, bottom: true);
      _to = _rectOf(_ruleKey, bottom: false);
      setState(() => _phase = _Phase.moving);
      unawaited(_fade.forward());
      await _move.forward();
    }
    if (!mounted) return;
    // The router's rule 1 now lets Login through, by the Dip.
    await ref.read(preferencesProvider).setSetupCompleted(true);
    ref.invalidate(setupCompletedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final android = Theme.of(context).platform == TargetPlatform.android;
    final busy = _phase != _Phase.idle;
    final below = AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        final t = _phase == _Phase.moving || _fade.isAnimating || _fade.isCompleted
            ? 1 - (CineMotion.reduced(context) ? _fade.value : CineCurves.lift.transform(_fade.value))
            : 1.0;
        return Opacity(opacity: t.clamp(0.0, 1.0), child: child);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: c.space6),
        const AuthKicker('First, the address'),
        SizedBox(height: c.space2),
        const AuthHeadline('Where is your library?'),
        SizedBox(height: c.space3),
        CineRoleText(
          'Type the address of your ManhwaManiacs server. It is checked before anything is saved.',
          c.typeDeck,
          color: c.colorInk60,
        ),
        SizedBox(height: c.space8),
        KeyedSubtree(
          key: _fieldKey,
          child: CineTextField(
            label: 'Server address',
            controller: _url,
            hint: Env.defaultApiUrl,
            numeric: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.url],
            textInputAction: android ? TextInputAction.go : TextInputAction.done,
            enabled: !busy,
            loading: _phase == _Phase.validating,
            success: _phase == _Phase.connected || _phase == _Phase.moving,
            successHold: CineDur.holdConnected,
            errorText: _error,
            onSubmitted: (_) => _submit(),
          ),
        ),
        SizedBox(height: c.space6),
        CineButton(
          label: 'Connect',
          loadingLabel: 'Connecting…',
          loading: _phase == _Phase.validating,
          onPressed: busy ? null : _submit,
        ),
        if (widget.releaseBuild) ...[
          SizedBox(height: c.space3),
          CineRoleText(kSetupRelease, c.typeCaption, color: c.colorInk45),
        ],
      ],),
    );

    return Stack(key: _stack, children: [
      Positioned.fill(
        child: AuthFrame(children: [AuthMasthead(ruleKey: _ruleKey), below]),
      ),
      if (_phase == _Phase.moving && _from != null && _to != null)
        AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final t = CineCurves.turn.transform(_move.value);
            final top = _from!.top + (_to!.top - _from!.top) * t;
            final left = _from!.left + (_to!.left - _from!.left) * t;
            final width = _from!.width + (_to!.width - _from!.width) * t;
            return Positioned(left: left, top: top - 3, width: width, child: IgnorePointer(child: AuthRule(width: width)));
          },
        ),
    ],);
  }
}
