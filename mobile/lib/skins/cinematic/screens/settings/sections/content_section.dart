import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/shared/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Content (cinematic 8.30.2 row 8): the 18+ switch with its certificate, and pinned sources.
class ContentSection extends StatelessWidget {
  const ContentSection({super.key});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const JumpRow(id: 'mature', child: MatureGateSwitch.settings()),
        SettingsLinkRow(id: 'pinned-sources', label: 'Manage pinned sources', onTap: () => unawaited(Future<void>.sync(() => context.go(Routes.sources())))),
      ],);
}
