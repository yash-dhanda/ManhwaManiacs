import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_highlight_sweep.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The jump of the settings search (cinematic 8.30.1): scroll to a row in 400 ms `easeSettle`
/// (`jumpTo` under reduced motion), wash it with `spot.wash` (200 ms sweep, then held 1200 ms) and
/// move focus into its control.
class SettingsJump {
  final Map<String, GlobalKey> _keys = {};
  final Map<String, FocusNode> _nodes = {};
  final ValueNotifier<String?> flash = ValueNotifier<String?>(null);

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);
  FocusNode nodeFor(String id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'settings-row-$id', skipTraversal: true, canRequestFocus: false));

  Future<void> run(BuildContext context, String id) async {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final reduced = CineMotion.reduced(context);
    final glide = context.cine.durGlide;
    if (reduced) {
      await Scrollable.ensureVisible(ctx, alignment: 0.3);
    } else {
      await Scrollable.ensureVisible(ctx, alignment: 0.3, duration: glide, curve: CineCurves.settle);
    }
    flash.value = id;
    final target = _nodes[id]?.descendants.where((n) => n.canRequestFocus && !n.skipTraversal).firstOrNull;
    target?.requestFocus();
    _timer?.cancel();
    _timer = Timer(CineDur.clip + CineDur.holdFlash, () {
      if (flash.value == id) flash.value = null;
    });
  }

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    flash.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
  }
}

class SettingsJumpScope extends InheritedWidget {
  const SettingsJumpScope({super.key, required this.jump, required super.child});
  final SettingsJump jump;

  static SettingsJump? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<SettingsJumpScope>()?.jump;

  @override
  bool updateShouldNotify(SettingsJumpScope o) => o.jump != jump;
}

/// A settings row the search can jump to.
class JumpRow extends StatelessWidget {
  const JumpRow({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final jump = SettingsJumpScope.maybeOf(context);
    if (jump == null) return child;
    return KeyedSubtree(
      key: jump.keyFor(id),
      child: Focus(
        focusNode: jump.nodeFor(id),
        skipTraversal: true,
        canRequestFocus: false,
        child: ValueListenableBuilder<String?>(
          valueListenable: jump.flash,
          builder: (_, flashing, __) => Stack(children: [
            Positioned.fill(
              child: IgnorePointer(
                child: flashing == id ? const CineHighlightSweep(child: SizedBox.expand()) : const SizedBox.shrink(),
              ),
            ),
            child,
          ],),
        ),
      ),
    );
  }
}

/// A kicker over a group of rows.
class SettingsKicker extends StatelessWidget {
  const SettingsKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
      child: Semantics(header: true, child: CineRoleText(text, c.typeKicker, color: c.colorInk60)),
    );
  }
}

/// A caption line under a row.
class SettingsCaption extends StatelessWidget {
  const SettingsCaption(this.text, {super.key, this.tone});
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(bottom: c.space2),
      child: CineRoleText(text, c.typeCaption, color: tone ?? c.colorInk60),
    );
  }
}

/// A label, an optional description and the control on its own line below (segmented controls,
/// sliders and slug lines need the width).
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, required this.id, required this.label, required this.child, this.description, this.disabled = false});
  final String id, label;
  final String? description;
  final Widget child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return JumpRow(
      id: id,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: c.space3),
        child: Semantics(
          container: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CineRoleText(label, c.typeUi, color: disabled ? c.colorInk30 : c.colorInk100),
            if (description != null) CineRoleText(description!, c.typeCaption, color: c.colorInk60),
            SizedBox(height: c.space2),
            child,
          ],),
        ),
      ),
    );
  }
}

Widget switchRow(String id, String label, bool value, FutureOr<void> Function(bool)? onChanged, {String? description, bool disabled = false}) => JumpRow(
      id: id,
      child: CineSettingsRow(
        label: label,
        description: description,
        disabled: disabled,
        control: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: CineSwitch(label: label, value: value, onChanged: disabled ? null : onChanged),
        ),
      ),
    );

/// `A │ B │ C` as a segmented control.
Widget segmentedRow(String id, String label, List<String> labels, int index, ValueChanged<int> onChanged,
        {String? description, bool disabled = false, Map<int, String> disabledReasons = const {},}) =>
    SettingsBlock(
      id: id,
      label: label,
      description: description,
      disabled: disabled,
      child: IgnorePointer(
        ignoring: disabled,
        child: CineSegmentedControl(labels: labels, index: index, onChanged: onChanged, disabledReasons: disabledReasons),
      ),
    );

/// A single-select slug line (`SYSTEM · ON`).
Widget slugRow(String id, String label, List<CineSlug> items, String selected, ValueChanged<String> onChanged, {String? description, bool disabled = false}) =>
    SettingsBlock(
      id: id,
      label: label,
      description: description,
      disabled: disabled,
      child: IgnorePointer(ignoring: disabled, child: CineSlugLines(items: items, selected: {selected}, onChanged: onChanged)),
    );

Widget sliderRow(String id, String label, double value, ValueChanged<double> onChanged,
        {required double min, required double max, int? divisions, String Function(double)? flag, String? description, String? minCaption, String? maxCaption, bool disabled = false,}) =>
    SettingsBlock(
      id: id,
      label: label,
      description: description,
      disabled: disabled,
      child: IgnorePointer(
        ignoring: disabled,
        child: CineSlider(
          label: label,
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          flagText: flag,
          valueText: flag,
          minCaption: minCaption,
          maxCaption: maxCaption,
          onChanged: onChanged,
        ),
      ),
    );

Widget stepperRow(String id, String label, int value, ValueChanged<int> onChanged,
        {required int min, required int max, int step = 1, String? description, String? unit, bool disabled = false,}) =>
    JumpRow(
      id: id,
      child: CineSettingsRow(
        label: label,
        description: description,
        disabled: disabled,
        control: IgnorePointer(
          ignoring: disabled,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CineStepper(value: value, min: min, max: max, step: step, label: label, onChanged: onChanged),
            if (unit != null) Builder(builder: (context) => Padding(padding: EdgeInsets.only(left: context.cine.space2), child: CineRoleText(unit, context.cine.typeFolio, color: context.cine.colorInk60))),
          ],),
        ),
      ),
    );

/// The `NOTE` strip and `Choose a profile` shown while a per-profile section has no profile.
class NoProfileBanner extends StatelessWidget {
  const NoProfileBanner({super.key});

  static const String line = "No reading profile is active, so there's nowhere to save this yet.";

  @override
  Widget build(BuildContext context) => CineBannerStrip(
        line: line,
        actions: [
          CineBannerAction('Choose a profile', () => unawaited(context.push<void>(Routes.profiles(), extra: const <String, String>{'mode': 'switch'}))),
        ],
      );
}

/// Whether a per-profile section can save: a profile is active.
final hasActiveProfileProvider = Provider<bool>((ref) => ref.watch(activeProfileProvider) != null, name: 'hasActiveProfile');

/// True while the account has no way to reach the server.
final settingsOfflineProvider = Provider<bool>(
  (ref) => ref.watch(sessionOfflineProvider) || !(ref.watch(deviceOnlineProvider).valueOrNull ?? true),
  name: 'settingsOffline',
);

/// The three states of a server-backed block (cinematic 8.30.1): greeked rows while loading, a
/// `CORRECTION` strip with `Retry` on error, and the last known values with the controls off and
/// "Needs a connection." offline.
class SettingsAsync<T> extends ConsumerWidget {
  const SettingsAsync({super.key, required this.value, required this.builder, required this.onRetry, this.rows = 3});

  final AsyncValue<T> value;

  /// [offline] is true when the controls must be disabled.
  final Widget Function(BuildContext context, T data, bool offline) builder;
  final VoidCallback onRetry;
  final int rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final offline = ref.watch(settingsOfflineProvider);
    final data = value.valueOrNull;
    if (data != null) {
      final body = builder(context, data, offline);
      if (!offline) return body;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: EdgeInsets.only(top: c.space2), child: CineRoleText('Needs a connection.', c.typeCaption, color: c.colorInk60)),
        IgnorePointer(child: ExcludeFocus(child: body)),
      ],);
    }
    if (value.hasError) {
      return Padding(
        padding: EdgeInsets.only(top: c.space3),
        child: CineBannerStrip(
          tone: CineBannerTone.correction,
          line: offline ? 'Needs a connection.' : "This didn't load.",
          actions: [CineBannerAction('Retry', onRetry)],
        ),
      );
    }
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: Column(children: [
          for (var i = 0; i < rows; i++)
            CineFlicker(
              index: i,
              child: Container(
                height: 56,
                margin: EdgeInsets.only(top: c.space2),
                decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: 0.4 + 0.1 * (i % 3), child: Container(height: 12, color: c.colorPaper3)),
              ),
            ),
        ],),
      ),
    );
  }
}

/// A `quiet` link row with a caret (`Reading history →`).
class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({super.key, required this.id, required this.label, required this.onTap, this.value, this.description});
  final String id, label;
  final String? value, description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => JumpRow(
        id: id,
        child: CineSettingsRow(label: label, description: description, value: value, chevron: true, onTap: onTap),
      );
}

/// A `quiet` action under a row.
Widget quietAction(String label, VoidCallback? onPressed, {CineButtonVariant variant = CineButtonVariant.quiet, String? disabledReason}) =>
    Align(alignment: Alignment.centerLeft, child: CineButton(label: label, variant: variant, size: CineButtonSize.sm, onPressed: onPressed, disabledReason: disabledReason));

String folioValue(String s) => folioLabel(s);
