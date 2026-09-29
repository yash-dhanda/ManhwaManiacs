import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/repositories/mature_settings_repository.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/shared/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_wordmark.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The section id added by mobile/07.
const List<String> kAuthGallerySections = ['auth'];

/// The mobile/07 gallery section: the masthead lockups, the 18+ switch in every state it can be
/// shown in without a tap, and the rating card. Fixture providers only. The whole-screen states
/// (Setup, Login, Register, the picker, the form, Manage) are driven with scripted taps by the
/// `mobile-07` screenshot group.
class AuthGallerySection extends StatelessWidget {
  const AuthGallerySection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget tag(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: CineRoleText(t, c.typeCaption, color: c.colorInk45),
        );
    return Padding(
      key: const Key('gallery-auth'),
      padding: EdgeInsets.only(top: c.space10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineRoleText('GALLERY · AUTH', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        const CineRuleDraw(kind: CineRuleKind.heavy),
        tag('One-line lockup, 28 px with the Oxford rule; 20 px without'),
        const Align(alignment: Alignment.centerLeft, child: CineWordmark.line()),
        SizedBox(height: c.space4),
        const Align(alignment: Alignment.centerLeft, child: CineWordmark.line(size: 20, withRule: false)),
        tag('18+ switch, settings mode: off'),
        const _Fixture(value: false, active: true, child: MatureGateSwitch.settings()),
        tag('on'),
        const _Fixture(value: true, active: true, child: MatureGateSwitch.settings()),
        tag('loading the setting'),
        const _Fixture(value: null, active: true, child: MatureGateSwitch.settings()),
        tag('blocked: no active profile'),
        const _Fixture(value: false, active: false, child: MatureGateSwitch.settings()),
        tag('form mode'),
        MatureGateSwitch.form(value: false, onChanged: (_) {}, formProfileName: 'Yash'),
        tag('Rating card (frozen at full opacity)'),
        const Align(alignment: Alignment.centerLeft, child: CineRatingCard(genres: ['Violence', 'Smut'], frozen: 1, announce: false)),
        SizedBox(height: c.space3),
        const Align(alignment: Alignment.centerLeft, child: CineRatingCard(genres: ['Romance'], frozen: 1, announce: false)),
      ],),
    );
  }
}

class _Repo implements MatureSettingsRepository {
  _Repo(this.value);
  final bool? value;
  @override
  Future<Result<bool>> getMatureEnabled() => value == null ? Completer<Result<bool>>().future : Future.value(Ok(value!));
  @override
  Future<Result<bool>> setMatureEnabled(bool enabled) async => Ok(enabled);
}

class _Active extends ActiveProfileNotifier {
  _Active(this.on);
  final bool on;
  @override
  ActiveProfile? build() => on ? const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral) : null;
}

class _Fixture extends StatelessWidget {
  const _Fixture({required this.value, required this.active, required this.child});
  final bool? value;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          matureSettingsRepositoryProvider.overrideWithValue(_Repo(value)),
          activeProfileProvider.overrideWith(() => _Active(active)),
        ],
        child: child,
      );
}
