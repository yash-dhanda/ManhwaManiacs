/// The sleep timer menu (glass 8.16.6, I): blooms from the Sleep tile; Off, 5, 10, 15, 30, 45, 60 min, End of chapter, End of next
/// chapter and Custom (a minutes stepper, 1 to 180); the foot carries "Shake to extend" (default off, `glassShakeToExtend`).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/anchored_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

Future<void> showGlassSleepMenu(BuildContext context, {required Rect anchor}) =>
    showListenPicker(context, anchor: anchor, label: 'Sleep timer', builder: (context, close) => GlassSleepMenu(close: close));

class GlassSleepMenu extends ConsumerStatefulWidget {
  const GlassSleepMenu({super.key, required this.close});
  final VoidCallback close;

  @override
  ConsumerState<GlassSleepMenu> createState() => _GlassSleepMenuState();
}

class _GlassSleepMenuState extends ConsumerState<GlassSleepMenu> {
  bool _custom = false;
  int _minutes = 20;

  void _pick(SleepChoice c) {
    glassFire(ref, HapticEvent.select);
    ref.read(narrationControllerProvider.notifier).setSleep(c);
    widget.close();
  }

  Widget _row(String label, bool selected, VoidCallback onTap) => SizedBox(
        height: 44,
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.99,
          shape: const GlassShape.superellipse(14),
          minHit: false,
          onTap: onTap,
          semanticsLabel: label,
          semanticsSelected: selected,
          builder: (context, info) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(child: GlassText(label, role: gt.typeBody, onGlass: true, maxLines: 1, maxScale: 1.5)),
                if (selected) Icon(PhosphorRegular.check, size: 18, color: gt.colorOnGlass),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = ref.watch(narrationControllerProvider.notifier);
    final current = n.sleepState.value.choice;
    final shake = ref.watch(listenSettingsValueProvider).glassShakeToExtend;
    return SizedBox(
      width: 280,
      child: SkinGlass(
        key: const ValueKey('glass-sleep-menu'),
        tier: GlassTierId.t4,
        shape: const GlassShape.superellipse(24),
        layer: GlassLayerKind.overlays,
        debugLabel: 'GlassSleepMenu',
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row('Off', current.kind == SleepKind.off, () => _pick(SleepChoice.off)),
                for (final m in SleepChoice.presets) _row('$m min', current.kind == SleepKind.minutes && current.minutes == m, () => _pick(SleepChoice.minutes(m))),
                _row('End of chapter', current.kind == SleepKind.endOfChapter, () => _pick(SleepChoice.endOfChapter)),
                _row('End of next chapter', current.kind == SleepKind.endOfNextChapter, () => _pick(SleepChoice.endOfNextChapter)),
                _row('Custom', _custom, () => setState(() => _custom = !_custom)),
                if (_custom)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                    child: Row(
                      children: [
                        Expanded(child: GlassStepper(value: _minutes, min: SleepChoice.minCustom, max: SleepChoice.maxCustom, label: 'Minutes', format: (v) => '$v min', onChanged: (v) => setState(() => _minutes = v))),
                        const SizedBox(width: 8),
                        GlassButton(label: 'Start', size: GlassButtonSize.small, variant: GlassButtonVariant.primary, onPressed: () => _pick(SleepChoice.minutes(_minutes))),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Container(height: 0.5, color: gt.colorSeparator),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassText('Shake to extend', role: gt.typeBody, onGlass: true, maxScale: 1.5),
                            GlassText('Works while ManhwaManiacs is open.', role: gt.typeCaption1, onGlass: true, color: gt.colorLabel2, maxScale: 1.5, maxLines: 2),
                          ],
                        ),
                      ),
                      GlassSwitch(value: shake, label: 'Shake to extend', onChanged: (v) => unawaited(ref.read(listenSettingsProvider.notifier).put({'glassShakeToExtend': v}))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
