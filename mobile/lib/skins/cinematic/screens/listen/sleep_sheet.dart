import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The sleep timer sheet (cinematic 8.16.6): `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of
/// chapter · End of next chapter · Custom` (a minutes stepper, 1-180).
Future<void> showSleepSheet(BuildContext context, {CineStockColors? stock}) => showListenSheet<void>(
      context,
      kicker: 'SLEEP',
      title: 'Sleep timer',
      stock: stock,
      builder: (_) => const SleepSheetBody(),
    );

class SleepSheetBody extends ConsumerStatefulWidget {
  const SleepSheetBody({super.key});

  @override
  ConsumerState<SleepSheetBody> createState() => _SleepSheetBodyState();
}

class _SleepSheetBodyState extends ConsumerState<SleepSheetBody> {
  bool _custom = false;
  int _minutes = 20;

  void _pick(SleepChoice choice) {
    ref.read(narrationControllerProvider.notifier).setSleep(choice);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final controller = ref.read(narrationControllerProvider.notifier);
    return ValueListenableBuilder<SleepState>(
      valueListenable: controller.sleepState,
      builder: (context, sleep, _) {
        final current = sleep.choice;
        final options = <(SleepChoice, String)>[
          (SleepChoice.off, 'Off'),
          for (final m in SleepChoice.presets) (SleepChoice.minutes(m), '$m min'),
          (SleepChoice.endOfChapter, 'End of chapter'),
          (SleepChoice.endOfNextChapter, 'End of next chapter'),
        ];
        return Padding(
          padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sleep.countdown != null)
                Padding(
                  padding: EdgeInsets.only(bottom: c.space2),
                  child: CineRoleText('${sleep.countdown} LEFT', c.typeFolio, color: c.colorInk60),
                ),
              for (final (choice, label) in options)
                CineRadio<SleepChoice>(
                  value: choice,
                  groupValue: _custom ? null : current,
                  label: label,
                  onChanged: _pick,
                ),
              CineRadio<bool>(
                value: true,
                groupValue: _custom,
                label: 'Custom',
                onChanged: (_) => setState(() => _custom = true),
              ),
              if (_custom) ...[
                SizedBox(height: c.space2),
                Row(
                  children: [
                    CineStepper(
                      label: 'Minutes',
                      value: _minutes,
                      min: SleepChoice.minCustom,
                      max: SleepChoice.maxCustom,
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                    SizedBox(width: c.space2),
                    CineRoleText('MIN', c.typeFolio, color: c.colorInk60),
                    const Spacer(),
                    CineButton(
                      label: 'Set',
                      size: CineButtonSize.sm,
                      onPressed: () {
                        cineFeedback(context, HapticEvent.tapPrimary);
                        _pick(SleepChoice.minutes(_minutes));
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
