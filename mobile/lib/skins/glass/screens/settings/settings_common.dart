import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A row with a switch on its trailing edge.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({super.key, required this.id, required this.title, required this.value, required this.onChanged, this.caption, this.enabled = true});
  final String id, title;
  final String? caption;
  final bool value, enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SettingsRow(
        id: id,
        title: title,
        caption: caption,
        enabled: enabled,
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        trailing: GlassSwitch(value: value, label: title, onChanged: enabled ? onChanged : null),
      );
}

/// A caption1 line under a control ("All series").
class SettingsCaption extends StatelessWidget {
  const SettingsCaption(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => GlassText(text, role: context.glass.typeCaption1, color: context.glass.colorLabel2);
}

/// A slider block with its value in `mono` on the right.
class SettingsSliderBlock extends StatelessWidget {
  const SettingsSliderBlock({super.key, required this.id, required this.title, required this.value, required this.onChanged, this.caption, this.min = 0, this.max = 1, this.divisions, this.format, this.enabled = true});
  final String id, title;
  final String? caption;
  final double value, min, max;
  final int? divisions;
  final String Function(double)? format;
  final ValueChanged<double>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SettingsBlock(
        id: id,
        title: title,
        caption: caption,
        child: GlassSlider(value: value, min: min, max: max, divisions: divisions, label: title, format: format, onChanged: enabled ? onChanged : (_) {}),
      );
}

/// A segmented block (2 to 5 segments).
class SettingsSegmentedBlock<T> extends StatelessWidget {
  const SettingsSegmentedBlock({super.key, required this.id, required this.title, required this.segments, required this.selected, required this.onSelected, this.caption, this.enabled = true});
  final String id, title;
  final String? caption;
  final List<GlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SettingsBlock(
        id: id,
        title: title,
        caption: caption,
        child: GlassSegmented<T>(segments: segments, selected: selected, onSelected: onSelected, enabled: enabled),
      );
}

/// "Choose a profile first" with its link (glass 8.25, B5). Shown in place of a profile-scoped section's body.
class NeedsProfileNotice extends StatelessWidget {
  const NeedsProfileNotice({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassInlineNotice(message: 'Choose a profile first', actionLabel: 'Choose a profile', onAction: () => GoRouter.of(context).go(Routes.profiles())),
      );
}

/// Builds [builder] only with an active profile; otherwise the notice and nothing else.
class ProfileGate extends ConsumerWidget {
  const ProfileGate({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(activeProfileProvider) == null ? const NeedsProfileNotice() : builder(context);
}

/// Six row skeletons while a server-backed section loads.
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key, this.rows = 6});
  final int rows;
  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        label: 'Loading settings',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (var i = 0; i < rows; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 52, index: i)),
          ],),
        ),
      );
}

/// The offline notice for server-backed sections.
class OfflineSettingsNotice extends StatelessWidget {
  const OfflineSettingsNotice({super.key, this.message = 'These settings need a connection'});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: GlassInlineNotice(message: message));
}

bool settingsOffline(WidgetRef ref) => ref.watch(glassOfflineProvider);

void settingsToast(WidgetRef ref, String message, {GlassToastKind kind = GlassToastKind.info}) => showGlassToast(ref, GlassToastSpec(message, kind: kind));

/// Keeps the anchors provider alive for the section bodies (they register rows on it).
void touchAnchors(WidgetRef ref) => ref.watch(settingsAnchorsProvider);
