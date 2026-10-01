import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const String kSwitchServersBody =
    "You'll be signed out. Saved chapters stay on this phone but open only when you're signed in to the server they came from.";

/// Server (cinematic 8.30.2 row 13): the API address, validated as Setup does, and switched with
/// a heavy confirmation that signs out and clears the profile caches (downloads stay).
class ServerSection extends ConsumerStatefulWidget {
  const ServerSection({super.key});

  @override
  ConsumerState<ServerSection> createState() => _ServerSectionState();
}

class _ServerSectionState extends ConsumerState<ServerSection> {
  final _url = TextEditingController();
  bool _seeded = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final input = _url.text.trim();
    if (input.isEmpty) {
      setState(() => _error = setupErrorLine(const ServerCheck.unreachable('')));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final sw = ref.read(serverSwitchProvider);
    final check = await sw.check(input);
    if (!mounted) return;
    setState(() => _busy = false);
    if (check is! ServerCheckOk) {
      setState(() => _error = setupErrorLine(check));
      return;
    }
    final toasts = ref.read(cineToastsProvider.notifier);
    if (sw.isSame(check.normalisedUrl)) {
      toasts.info('Already connected to this server.');
      return;
    }
    final ok = await showCineConfirm(
      context,
      title: 'Switch servers?',
      body: kSwitchServersBody,
      confirmLabel: 'Switch servers',
      destructive: true,
      onConfirm: () async {
        final err = await sw.confirm(check.normalisedUrl);
        if (err != null) throw err;
      },
    );
    if (ok) toasts.info('Signed out: new server.');
  }

  Future<void> _reset() async {
    final sw = ref.read(serverSwitchProvider);
    final toasts = ref.read(cineToastsProvider.notifier);
    setState(() => _error = null);
    if (sw.isSame(Env.defaultApiUrl)) {
      await sw.reset();
      if (!mounted) return;
      setState(() => _url.text = Env.defaultApiUrl);
      toasts.info('Already on the default server.');
      return;
    }
    final ok = await showCineConfirm(
      context,
      title: 'Switch servers?',
      body: kSwitchServersBody,
      confirmLabel: 'Switch servers',
      destructive: true,
      onConfirm: () async {
        final err = await sw.reset();
        if (err != null) throw err;
      },
    );
    if (!mounted || !ok) return;
    setState(() => _url.text = Env.defaultApiUrl);
    toasts.info('Signed out: default server.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final saved = ref.watch(settingsApiUrlProvider);
    if (!_seeded && saved.hasValue) {
      _seeded = true;
      _url.text = saved.value!;
    }
    return JumpRow(
      id: 'api-url',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineTextField(
          label: 'API base URL',
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.go,
          numeric: true,
          errorText: _error,
          enabled: !_busy,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => unawaited(_save()),
        ),
        SizedBox(height: c.space3),
        Wrap(spacing: c.space2, children: [
          CineButton(label: 'Save', size: CineButtonSize.sm, loading: _busy, onPressed: _busy ? null : () => unawaited(_save())),
          CineButton(
            label: 'Reset to default',
            variant: CineButtonVariant.quiet,
            size: CineButtonSize.sm,
            onPressed: _busy
                ? null
                : () => unawaited(_reset()),
          ),
        ],),
      ],),
    );
  }
}
