import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/session_loss.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a profile gone elsewhere is dropped, not left active behind the picker', (tester) async {
    SharedPreferences.setMockInitialValues({'mm.active_profile': '{"id":7,"name":"X","avatar_key":null,"mood":"default"}'});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/profiles', builder: (_, __) => const SizedBox()),
    ],);
    addTearDown(router.dispose);
    late WidgetRef r;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        skinRouterProvider.overrideWithValue(router),
      ],
      child: Consumer(builder: (_, ref, __) {
        r = ref;
        return const SizedBox();
      },),
    ),);
    expect(r.read(activeProfileProvider)?.id, 7);

    handleProfileGone(r);
    await tester.pump();

    expect(r.read(activeProfileProvider), isNull);
    expect(prefs.getString('mm.active_profile'), isNull);
  });
}
