import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The 18+ safeguard in one component (cinematic 7.24), so the profile form and Settings -> Content
/// share it. Turning on always opens the certificate; turning off needs no confirmation.
///
/// **Settings mode** (`MatureGateSwitch.settings`, mounted by mobile/18): a settings row bound to
/// `matureContentProvider`; `Enable 18+` runs `setEnabled(true)` (the `PUT /settings` that already
/// invalidates every gated cache; the device stores follow through `matureGateOpenProvider`).
/// **Form mode** (`MatureGateSwitch.form`): the certificate sets the form value only, saved with
/// the form.
class MatureGateSwitch extends ConsumerWidget {
  /// Settings mode.
  const MatureGateSwitch.settings({super.key})
      : formValue = null,
        onFormChanged = null,
        formProfileName = '';

  /// Form mode: [value] is the form's value, [onChanged] receives it after the certificate.
  const MatureGateSwitch.form({super.key, required bool value, required ValueChanged<bool> onChanged, this.formProfileName = ''})
      : formValue = value,
        onFormChanged = onChanged;

  final bool? formValue;
  final ValueChanged<bool>? onFormChanged;
  final String formProfileName;

  bool get _form => formValue != null;

  static const String label = 'Show mature content (18+)';
  static const String description = 'Adult sources, series, search results and recommendations. Off by default.';
  static const String blockedLine = "No reading profile is active, so there's nowhere to save this yet.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    if (_form) {
      return CineSettingsRow(
        label: 'Mature content (18+)',
        description: description,
        control: CineSwitch(
          label: 'Mature content (18+)',
          value: formValue!,
          errorLine: "Couldn't change this setting.",
          onChanged: (v) async {
            if (!v) {
              onFormChanged!(false);
              return;
            }
            final ok = await openCineCertificateDialog(
              context,
              profileName: formProfileName,
              onConfirm: () async => true,
            );
            if (ok ?? false) onFormChanged!(true);
          },
        ),
      );
    }

    final active = ref.watch(activeProfileProvider);
    if (active == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CineSettingsRow(label: label, description: description, control: CineSwitch(value: false, onChanged: null), disabled: true),
        Padding(
          padding: EdgeInsets.only(top: c.space2),
          child: CineRoleText(blockedLine, c.typeCaption, color: c.colorInk60),
        ),
        CineButton(
          label: 'Choose a profile',
          variant: CineButtonVariant.link,
          onPressed: () => context.push(Routes.profiles(), extra: const <String, String>{'mode': 'switch'}),
        ),
      ],);
    }
    final state = ref.watch(matureContentProvider);
    if (state.hasError && !state.isLoading) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CineSettingsRow(label: label, description: "Couldn't read this setting.", control: CineSwitch(value: false, onChanged: null), disabled: true),
        CineButton(label: 'Retry', variant: CineButtonVariant.link, onPressed: () => ref.invalidate(matureContentProvider)),
      ],);
    }
    // Only a settled value is the profile's: a refresh after a profile switch still carries the previous profile's.
    final fresh = state is AsyncData<bool>;
    final on = fresh && (state.valueOrNull ?? false);
    return CineSettingsRow(
      label: label,
      description: description,
      control: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: CineSwitch(
        label: label,
        value: on,
        errorLine: "Couldn't change this setting.",
        onChanged: !fresh
            ? null
            : (v) async {
                final notifier = ref.read(matureContentProvider.notifier);
                if (!v) {
                  final err = await notifier.setEnabled(false);
                  if (err != null) throw err;
                  ref.read(cineToastsProvider.notifier).info(matureHiddenToast(active.name));
                  return;
                }
                await openCineCertificateDialog(
                  context,
                  profileName: active.name,
                  onConfirm: () async => (await notifier.setEnabled(true)) == null,
                );
              },
        ),
      ),
    );
  }
}
