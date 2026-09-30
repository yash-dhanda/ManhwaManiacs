import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/storage_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';

/// Downloads & storage: the same panel as `/downloads?tab=storage` (mobile/17), unchanged.
class StorageSection extends StatelessWidget {
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context) => const JumpRow(id: 'storage-panel', child: StoragePanel());
}
