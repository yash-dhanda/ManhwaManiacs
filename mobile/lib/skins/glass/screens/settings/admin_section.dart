import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// `/settings/admin` (glass 8.0.3): the Administration list, System status, Members and Backup; admins only.
class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    final r = GoRouter.of(context);
    return GlassAdminGate(
      child: SettingsGroup(
        children: [
          GlassListRow(title: 'System status', icon: YouGlyphs.pulse.regular, iconColor: GlassColors.surface3, caret: true, onTap: () => r.go(Routes.status())),
          GlassListRow(title: 'Members', icon: YouGlyphs.usersThree.regular, iconColor: GlassColors.surface3, caret: true, onTap: () => r.go(Routes.settings(SettingsSection.members))),
          GlassListRow(title: 'Backup', icon: YouGlyphs.cloudArrowUp.regular, iconColor: GlassColors.surface3, caret: true, onTap: () => r.go(Routes.settings(SettingsSection.backup))),
        ],
      ),
    );
  }
}
