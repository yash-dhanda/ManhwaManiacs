import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';

/// Settings -> Content (glass 8.25.4): the 18+ switch and its gate (`GlassMatureGate`, mobile/28). Turning it off clears the
/// 18+ data through the gate's own setter (the invalidation list runs `purgeMatureLocal`).
class ContentSection extends ConsumerWidget {
  const ContentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = settingsOffline(ref);
    return Column(children: [
      if (offline) const OfflineSettingsNotice(),
      const SettingsGroup(children: [SettingsAnchorBox(id: 'mature-content', child: GlassMatureGate())]),
    ],);
  }
}
