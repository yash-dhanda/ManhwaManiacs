import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/setup_copy.dart' show setupFailureLine;
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';

/// Settings -> Server (glass 8.25.11, phones only): the API base URL, validated as Setup (glass 8.1), switched through the shared
/// `server_switch.dart` after a confirm (the switch signs out, so the confirm exists: open issue).
class ServerSection extends ConsumerStatefulWidget {
  const ServerSection({super.key});
  @override
  ConsumerState<ServerSection> createState() => _ServerSectionState();
}

class _ServerSectionState extends ConsumerState<ServerSection> {
  final _c = TextEditingController();
  String? _loaded, _error;
  int _shake = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The saved address fills the field once it resolves (never during a build).
    ref.listenManual<AsyncValue<String>>(settingsApiUrlProvider, (_, next) {
      final v = next.valueOrNull;
      if (v == null || v == _loaded) return;
      _loaded = v;
      _c.text = v;
      if (mounted) setState(() {});
    }, fireImmediately: true,);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _fail(String line) => setState(() {
        _busy = false;
        _error = line;
        _shake++;
      });

  Future<bool> _confirm() => confirmAlert(
        context,
        title: 'Switch servers?',
        body: "You'll be signed out. Saved chapters stay on this phone but open only when you're signed in to the server they came from.",
        confirmLabel: 'Switch servers',
        destructive: true,
      );

  Future<void> _save() async {
    final sw = ref.read(serverSwitchProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final check = await sw.check(_c.text);
    if (!mounted) return;
    if (check is! ServerCheckOk) return _fail(setupFailureLine(check)!);
    if (sw.isSame(check.normalisedUrl)) return setState(() => _busy = false);
    if (!await _confirm()) return setState(() => _busy = false);
    final err = await sw.confirm(check.normalisedUrl);
    if (!mounted) return;
    if (err != null) return _fail(err.userMessage);
    settingsToast(ref, 'Server URL saved and applied', kind: GlassToastKind.success);
    GoRouter.of(context).go(Routes.login());
  }

  Future<void> _reset() async {
    final sw = ref.read(serverSwitchProvider);
    if (!sw.isSame(Env.defaultApiUrl)) {
      if (!await _confirm()) return;
      await sw.confirm(Env.defaultApiUrl);
    }
    await sw.reset();
    if (!mounted) return;
    settingsToast(ref, 'Reset to the default address', kind: GlassToastKind.success);
    GoRouter.of(context).go(Routes.login());
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(settingsApiUrlProvider);
    if (url.hasError) return GlassInlineError(message: "Couldn't read the saved address", onRetry: () => ref.invalidate(settingsApiUrlProvider));
    final current = url.valueOrNull;
    if (current == null) return const Padding(padding: EdgeInsets.all(16), child: GlassSkeletonGroup(label: 'Loading the address', child: GlassSkeleton(height: 52)));
    final same = normaliseAddress(_c.text) == normaliseAddress(current);
    return SettingsGroup(
      id: 'server-url',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassTextField(
              kind: GlassFieldKind.url,
              controller: _c,
              label: 'API base URL',
              hint: Env.defaultApiUrl,
              error: _error,
              errorTrigger: _shake,
              validating: _busy,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) {
                if (!same && !_busy) unawaited(_save());
              },
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              GlassButton(label: 'Save', variant: GlassButtonVariant.primary, loading: _busy, onPressed: same || _busy ? null : () => unawaited(_save())),
              GlassButton(label: 'Reset to default', variant: GlassButtonVariant.plain, onPressed: _busy ? null : () => unawaited(_reset())),
            ],),
          ],),
        ),
      ],
    );
  }
}
