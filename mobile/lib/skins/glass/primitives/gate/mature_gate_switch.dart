import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show glassPurgeProbeProvider;

/// Where the gate writes: `settings` binds to the active profile's value through the shared setter (`PUT /settings` with the
/// profile header, then the gate invalidation list), `form` writes a form value only.
enum MatureGateMode { settings, form }

/// "Show mature content (18+)" (glass 7.25): one safeguard for Settings -> Content (`mobile/39`) and the profile form
/// (`mobile/30`). Turning on never flips on tap: the alert opens first. Turning off is immediate. Nothing here draws a lock, a
/// blur or a hidden count.
class GlassMatureGate extends ConsumerStatefulWidget {
  const GlassMatureGate({super.key, this.mode = MatureGateMode.settings, this.value = false, this.onChanged, this.onChooseProfile});
  final MatureGateMode mode;

  /// Form mode: the form's current value.
  final bool value;

  /// Form mode: receives the new value.
  final ValueChanged<bool>? onChanged;

  /// The "Choose a profile" link's target when no profile is active; defaults to `/profiles`.
  final VoidCallback? onChooseProfile;

  @override
  ConsumerState<GlassMatureGate> createState() => _GlassMatureGateState();
}

class _GlassMatureGateState extends ConsumerState<GlassMatureGate> {
  final GlobalKey _switchKey = GlobalKey();
  bool _pending = false;
  int _errors = 0;

  bool get _settings => widget.mode == MatureGateMode.settings;

  Rect? _rect() {
    final ro = _switchKey.currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : null;
  }

  Future<void> _request(bool next, bool current) async {
    if (_pending || next == current) return;
    if (!next) {
      await _apply(false);
      return;
    }
    final ok = await showMatureGateAlert(context, sourceRect: _rect());
    if (!ok || !mounted) return;
    glassFire(ref, HapticEvent.gateConfirm);
    glassSound(ref, SoundEvent.gateConfirm);
    await _apply(true);
  }

  Future<void> _apply(bool v) async {
    if (!_settings) {
      widget.onChanged?.call(v);
      return;
    }
    setState(() => _pending = true);
    final err = await ref.read(matureContentProvider.notifier).setEnabled(v);
    if (!mounted) return;
    setState(() {
      _pending = false;
      if (err != null) _errors++;
    });
    if (err != null) {
      showGlassToast(ref, const GlassToastSpec("Couldn't change this setting", kind: GlassToastKind.error));
    } else if (!v) {
      // Closing the active profile's gate runs the Glass 18+ purge, as the profile form and a profile switch do (glass 8.0.8).
      ref.read(glassPurgeProbeProvider)();
    }
  }

  void _choose() {
    final f = widget.onChooseProfile;
    if (f != null) return f();
    try {
      GoRouter.of(context).go('/profiles');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Show mature content (18+)';
    const subtitle = 'Adult sources, search results and recommendations appear for this profile.';
    final blocked = _settings && ref.watch(activeProfileProvider) == null;
    if (blocked) {
      return GlassListRow(
        title: title,
        subtitle: 'Choose a profile first',
        enabled: false,
        trailing: GlassButton(label: 'Choose a profile', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: _choose),
      );
    }
    final async = _settings ? ref.watch(matureContentProvider) : null;
    if (async != null && async.hasError && !async.isLoading && !_pending) {
      return GlassListRow(
        title: title,
        subtitle: "Couldn't read this setting",
        enabled: false,
        trailing: GlassButton(label: 'Retry', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: () => ref.invalidate(matureContentProvider)),
      );
    }
    // Only a settled value is shown as the profile's: a refresh after a profile switch still carries the previous profile's.
    final fresh = async is AsyncData<bool>;
    final value = _settings ? (fresh && (async?.valueOrNull ?? false)) : widget.value;
    final loading = _pending || (_settings && !fresh);
    return GlassListRow(
      title: title,
      subtitle: subtitle,
      onTap: loading ? null : () => unawaited(_request(!value, value)),
      trailing: Semantics(
        value: _pending ? 'Saving' : null,
        child: GlassSwitch(
          key: _switchKey,
          value: value,
          label: title,
          loading: loading,
          errorTrigger: _errors,
          deferOn: true,
          spring: gt.springCelebrate,
          onChanged: (next) => unawaited(_request(next, value)),
        ),
      ),
    );
  }
}
