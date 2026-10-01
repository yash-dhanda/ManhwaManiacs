import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/glass_skin_switch.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/skin_card.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skins.dart' show skinIdProvider;

/// Settings -> Appearance and skin (glass 8.25.1). The four accessibility switches live in `mm.boot.a11y` (read before first paint;
/// Cinematic reads `legible` and `motion` from the same record) and mirror into Glass's live in-app prefs so they apply at once.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key, bool? showIconRow, this.onChooseSkin}) : _showIconRow = showIconRow;
  final bool? _showIconRow;

  /// Test hook; defaults to [GlassSkinSwitch.start].
  final FutureOr<void> Function(SkinId target, Rect origin)? onChooseSkin;

  bool get showIconRow => _showIconRow ?? Flags.glassAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a11y = ref.watch(a11yPrefsProvider);
    final n = ref.read(a11yPrefsProvider.notifier);
    final live = ref.read(glassInAppPrefsProvider.notifier);
    final skin = ref.watch(skinIdProvider);
    ref.watch(glassPrefsRecordProvider);
    final rec = ref.read(glassPrefsRecordProvider.notifier);
    final lightOn = rec.lightFollowsDevice;
    final switcher = ref.watch(appIconSwitcherProvider);
    FutureOr<void> choose(SkinId t, Rect r) => onChooseSkin != null ? onChooseSkin!(t, r) : GlassSkinSwitch.start(context, ref, t, origin: r);
    return Column(children: [
      SettingsGroup(header: 'Skin', footer: 'Switching skin restarts the app.', children: [
        SettingsAnchor(
          id: 'skin',
          child: Semantics(
            label: 'Skin',
            child: Column(children: [
              GlassSkinCard(skin: SkinId.glass, current: skin == SkinId.glass, onChoose: (r) => choose(SkinId.glass, r)),
              GlassSkinCard(skin: SkinId.cinematic, current: skin == SkinId.cinematic, onChoose: (r) => choose(SkinId.cinematic, r)),
            ],),
          ),
        ),
      ],),
      SettingsGroup(header: 'Accessibility', children: [
        SettingsSwitchRow(id: 'solid-glass', title: 'Solid glass', caption: 'Replaces transparency with solid surfaces.', value: a11y.solid, onChanged: (v) {
          live.setSolidGlass(v);
          unawaited(n.setSolid(v));
        },),
        SettingsSwitchRow(id: 'increase-contrast', title: 'Increase contrast', value: a11y.contrast, onChanged: (v) {
          live.setIncreaseContrast(v);
          unawaited(n.setContrast(v));
        },),
        SettingsSwitchRow(id: 'legible-text', title: 'Legible text', caption: 'Uses Atkinson Hyperlegible Next everywhere.', value: a11y.legible, onChanged: (v) {
          live.setHyperlegible(v);
          unawaited(n.setLegible(v));
        },),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Read the next chapter', style: TextStyle(fontFamily: 'GoogleSansFlexMM', fontSize: 17, color: gt.colorLabel1, decoration: TextDecoration.none)),
              Text('Read the next chapter', style: TextStyle(fontFamily: 'AtkinsonHyperlegibleNext', fontSize: 17, color: gt.colorLabel1, decoration: TextDecoration.none)),
            ],),
          ),
        ),
        SettingsSwitchRow(id: 'reduce-motion', title: 'Reduce motion in this app', value: a11y.motion == 'reduced', onChanged: (v) {
          live.setReduceMotion(v);
          unawaited(n.setMotion(v ? 'reduced' : 'system'));
        },),
        SettingsSwitchRow(id: 'light-follows-device', title: 'Light follows the device', caption: 'Off pins the light at 135°.', value: lightOn, onChanged: (v) {
          live.setLightFollowsDevice(v);
          unawaited(rec.setLightFollowsDevice(v));
        },),
        if (showIconRow) _IconRow(follow: switcher.follow, onChanged: (v) => unawaited(switcher.setFollow(v))),
      ],),
    ],);
  }
}

class _IconRow extends StatefulWidget {
  const _IconRow({required this.follow, required this.onChanged});
  final bool follow;
  final ValueChanged<bool> onChanged;
  @override
  State<_IconRow> createState() => _IconRowState();
}

class _IconRowState extends State<_IconRow> {
  late bool _on = widget.follow;
  @override
  Widget build(BuildContext context) => SettingsSwitchRow(
        id: 'app-icon-follows-skin',
        title: 'App icon follows the skin',
        caption: 'Home-screen shortcuts to the old icon stop working.',
        value: _on,
        onChanged: (v) {
          setState(() => _on = v);
          widget.onChanged(v);
        },
      );
}
