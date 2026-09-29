// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';

import '../auth/auth_test_support.dart';

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);

FakeAuth _signedIn() => FakeAuth(initial: AuthAuthenticated(testUser));

void main() {
  testWidgets('the picker lists the profiles and never auto-skips', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 500);
    expect(find.bySemanticsLabel('Read as Yash'), findsOneWidget);
    expect(find.bySemanticsLabel('Read as Guest'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget, reason: 'the profile whose onboarding is not done');
    expect(rig.at, '/profiles');
  });
}
