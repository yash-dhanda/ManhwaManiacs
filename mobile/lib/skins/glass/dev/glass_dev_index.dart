import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// `/dev/glass`: the Glass development index (until `mobile/40` builds Glass Diagnostics).
class GlassDevIndex extends ConsumerWidget {
  const GlassDevIndex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const t = glassTokens;
    final reg = ref.watch(glassRegistryProvider);
    final renderer = ref.watch(glassRendererProvider);
    final over = reg.layers > kGlassLayerBudget || reg.shapes > kGlassShapeBudget;
    final hit = GlassFrame.hitMin(context);
    final margin = GlassFrame.screenMargin(context);

    Widget row(String label, {String? value, Color? valueColor, VoidCallback? onTap}) => Semantics(
          button: onTap != null,
          label: value == null ? label : '$label $value',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: hit + 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassText(label, role: t.typeBody),
                    if (value != null) GlassText(value, role: t.typeMono, size: 12, height: 16, color: valueColor ?? t.colorLabel2),
                  ],
                ),
              ),
            ),
          ),
        );

    return ColoredBox(
      color: const Color(0xFF000000),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(margin, 16, margin, 32),
          children: [
            GlassText('Glass development', role: t.typeLargeTitle),
            const SizedBox(height: 12),
            DevButton(label: 'Glass calibration', onTap: () => context.push('/dev/glass/calibration')),
            const SizedBox(height: 8),
            DevButton(label: 'Primitives gallery', onTap: () => context.push('/dev/glass/primitives')),
            const SizedBox(height: 8),
            row(
              'Glass layers on screen',
              value: '${reg.layers} / $kGlassLayerBudget layers · ${reg.shapes} / $kGlassShapeBudget shapes · ${reg.scrims} scrims',
              valueColor: over ? t.colorWarning : t.colorLabel2,
            ),
            DevToggle(
              label: 'Show motion timings',
              value: ref.watch(glassShowMotionTimingsProvider),
              onChanged: (v) => ref.read(glassShowMotionTimingsProvider.notifier).state = v,
            ),
            row('Renderer', value: 'Impeller'),
            row('Glass quality', value: 'premium (chrome) · standard (page controls in scroll views)'),
            row('Refraction', value: renderer == GlassRenderer.liquid ? 'on' : 'frosted'),
            const DevHeading('Edition (debug)'),
            DevSegmented<SkinId>(
              values: const [SkinId.cinematic, SkinId.glass],
              labelOf: (s) => s.name.toUpperCase(),
              selected: SkinId.glass,
              onSelected: (s) {
                if (s != SkinId.glass) debugSwitchSkin(context, ref, s);
              },
            ),
          ],
        ),
      ),
    );
  }
}
