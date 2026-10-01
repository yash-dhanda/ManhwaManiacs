import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart' show gapWords;
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart'
    show localDaysBetween;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Registers the `?sheet=offer` sheet (glass 8.0.3): `medium` on phones, the 420 px popover on wide frames.
void registerOfferSheet() => registerGlobalSheet(
      'offer',
      const GlassSheetSpec(
          title: 'Recap',
          builder: _offer,
          detents: [GlassDetent.medium],
          opening: GlassDetent.medium,
          wideForm: GlassWideForm.popover,),
    );

Widget _offer(BuildContext context) => const RecapOfferBody();

/// "It's been 3 weeks": the offer that blooms out of Continue (glass 9.1.3).
class RecapOfferBody extends ConsumerStatefulWidget {
  const RecapOfferBody({super.key});

  @override
  ConsumerState<RecapOfferBody> createState() => _RecapOfferBodyState();
}

class _RecapOfferBodyState extends ConsumerState<RecapOfferBody> {
  bool _skip = false;

  Future<void> _skipSave(HomeContinueTarget? t) async {
    if (t == null || !_skip) return;
    await ref.read(recapSettingProvider.notifier).skip(t.seriesId);
  }

  Future<void> _show() async {
    final t = ref.read(offerTargetProvider);
    final router = ref.read(skinRouterProvider);
    final skip = _skipSave(t);
    Navigator.of(context).pop();
    await skip;
    if (t != null) unawaited(router.push<void>(Routes.recap(t.sourceId, t.seriesKey, {'to': t.chapterKey}), extra: const GlassNavExtra()));
  }

  Future<void> _justContinue() async {
    final t = ref.read(offerTargetProvider);
    final go = ref.read(offerContinueProvider);
    final skip = _skipSave(t);
    Navigator.of(context).pop();
    await skip;
    go?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(offerTargetProvider);
    final days = t?.lastReadAt == null
        ? 0
        : localDaysBetween(t!.lastReadAt!, ref.read(clockProvider)());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassText("It's been ${gapWords(days)}",
              role: gt.typeTitle3, onGlass: true,),
          const SizedBox(height: 6),
          GlassText('Want a quick recap of what happened?',
              role: gt.typeCallout, onGlass: true,),
          const SizedBox(height: 20),
          GlassButton(
              label: 'Show recap',
              variant: GlassButtonVariant.primary,
              size: GlassButtonSize.large,
              fullWidth: true,
              onPressed: _show,),
          const SizedBox(height: 8),
          GlassButton(
              label: 'Just continue',
              variant: GlassButtonVariant.plain,
              size: GlassButtonSize.large,
              fullWidth: true,
              onPressed: _justContinue,),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: GlassText("Don't ask for this series",
                      role: gt.typeCallout, onGlass: true,),),
              GlassSwitch(
                  value: _skip,
                  label: "Don't ask for this series",
                  onChanged: (v) => setState(() => _skip = v),),
            ],
          ),
        ],
      ),
    );
  }
}
