import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `/dev/glass`: the Glass development index. The calibration, layer-count, motion-timings, renderer and skin-preview rows live in
/// Settings -> Diagnostics since `mobile/40`; this page keeps the galleries and links there.
class GlassDevIndex extends StatelessWidget {
  const GlassDevIndex({super.key});

  @override
  Widget build(BuildContext context) {
    const t = glassTokens;
    final margin = GlassFrame.screenMargin(context);
    return ColoredBox(
      color: const Color(0xFF000000),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(margin, 16, margin, 32),
          children: [
            GlassText('Glass development', role: t.typeLargeTitle),
            const SizedBox(height: 12),
            DevButton(label: 'Diagnostics', onTap: () => context.go(Routes.settings(SettingsSection.diagnostics))),
            const SizedBox(height: 8),
            DevButton(label: 'Primitives gallery', onTap: () => context.push('/dev/glass/primitives')),
            DevButton(label: 'Shell', onTap: () => context.push('/dev/glass/shell')),
            DevButton(label: 'Auth, profiles and onboarding', onTap: () => context.push('/dev/glass/auth')),
            DevButton(label: 'Reader engine probe', onTap: () => context.push('/dev/glass/reader-engine?fixture=long-strip')),
          ],
        ),
      ),
    );
  }
}
