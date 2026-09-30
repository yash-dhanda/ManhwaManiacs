import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Admin (cinematic 8.30.2 row 14): the admin pages.
class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SettingsLinkRow(id: 'backup', label: 'Backup & restore', onTap: () => unawaited(context.push<void>(Routes.settings(SettingsSection.backup)))),
        SettingsLinkRow(id: 'admin-members', label: 'Members', onTap: () => unawaited(context.push<void>(Routes.settings(SettingsSection.members)))),
        SettingsLinkRow(id: 'admin-status', label: 'System status', onTap: () => unawaited(context.push<void>(Routes.status()))),
      ],);
}
