import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `ADMINISTRATORS ONLY`, the section's name and a way back (cinematic 8.30.1). The controls never
/// render.
class AdminOnlyNotice extends StatelessWidget {
  const AdminOnlyNotice({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText('ADMINISTRATORS ONLY', c.typeKicker, color: c.colorInk60),
        SizedBox(height: c.space2),
        CineRoleText('$title is for administrators of this server.', c.typeUi),
        SizedBox(height: c.space4),
        CineButton(label: 'Back to Settings', variant: CineButtonVariant.secondary, onPressed: () => context.go(Routes.settings())),
      ],),
    );
  }
}

/// One section (or pushed page) as it is drawn: its heading, the no-profile banner where it
/// applies, and its rows.
class SectionPane extends ConsumerWidget {
  const SectionPane({super.key, required this.slug, required this.env, required this.twoPane, this.headingFocus, this.bodyOverride, this.overrideTitle});
  final String slug;
  final SettingsEnv env;
  final bool twoPane;
  final FocusNode? headingFocus;

  /// Replaces the body and title (the licence list, opened by `?licenses=1`).
  final Widget? bodyOverride;
  final String? overrideTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final page = settingsPageOf(slug);
    final def = settingsSectionOf(page?.parent ?? slug);
    final title = overrideTitle ?? page?.title ?? def?.title ?? 'Settings';
    final visible = visibleSettingsSections(env);
    final gated = (page?.adminOnly ?? false) || slug == 'admin';
    final hasProfile = ref.watch(hasActiveProfileProvider);
    final perProfile = page == null && (def?.perProfile ?? false);
    final Widget body;
    if (bodyOverride != null) {
      body = bodyOverride!;
    } else if (gated && !env.admin) {
      body = AdminOnlyNotice(title: title);
    } else if (def == null && page == null) {
      body = const SizedBox.shrink();
    } else {
      final built = (page?.body ?? def!.body)(context);
      body = perProfile && !hasProfile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const NoProfileBanner(),
              Opacity(opacity: 0.5, child: IgnorePointer(child: ExcludeFocus(child: built))),
            ],)
          : built;
    }
    final folio = folioOf(visible, page?.parent ?? slug);
    final heading = twoPane
        ? Padding(
            padding: EdgeInsets.only(bottom: c.space4),
            child: SetHeading(
              title,
              id: 'settings-$slug',
              style: CineText.style(context, c.typeSection).copyWith(color: c.colorInk100),
              cap: c.typeSection.cap,
              level: 3,
              trigger: SetTrigger.mount,
              focusNode: headingFocus,
            ),
          )
        : CineMasthead(kicker: 'No. $folio — SETTINGS', title: title, focusNode: headingFocus, id: 'settings-$slug');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading,
      body,
      if (twoPane) Padding(padding: EdgeInsets.only(top: c.space8), child: Container(height: 1, color: c.colorRule1)),
    ],);
  }
}
