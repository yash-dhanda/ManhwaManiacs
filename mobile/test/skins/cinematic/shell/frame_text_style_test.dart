import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

/// The banner and the toasts sit above the Navigator, outside every Material: without a
/// DefaultTextStyle of the frame's own they drew Flutter's debug fallback (a yellow double
/// underline). No text the frame hosts may carry an underline at all (owner, 3.5.2).
class _Unread extends UnreadCountNotifier {
  @override
  int build() => 6;
}

void main() {
  testWidgets('the stop-press banner and toasts use the skin face, never an underline', (t) async {
    SharedPreferences.setMockInitialValues(testPrefsDefaults());
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      skinIdProvider.overrideWithValue(SkinId.cinematic),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      profileSessionReadyOverride(),
      setupCompletedProvider.overrideWithValue(true),
      tonightIdleOverride(),
      ...shelfIdleOverrides(),
      ...noDownloadsStoreOverrides(),
      unreadNotificationCountProvider.overrideWith(_Unread.new),
      newChaptersBannerProvider.overrideWith((ref) async => (chapters: 6, series: 6, maxId: 9)),
    ],);
    addTearDown(c.dispose);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: CinematicSkin.baseTheme,
        routerConfig: c.read(skinRouterProvider),
        builder: (context, child) => CineAppFrame(splash: false, child: child!),
      ),
    ),);
    await t.pumpAndSettle();
    void expectNoUnderlines() {
      // Every paragraph on screen: the page, the thumb index, the banner and the toast.
      final hosted = find.byType(RichText).evaluate().toList();
      expect(hosted.length, greaterThan(10));
      for (final e in hosted) {
        final p = e.renderObject! as RenderParagraph;
        final s = p.text.style!;
        final what = p.text.toPlainText();
        expect(s.fontFamily, isNotNull, reason: what);
        expect(s.decorationColor, isNot(const Color(0xFFFFFF00)), reason: what);
        p.text.visitChildren((span) {
          final d = span.style?.decoration;
          expect(d == null || d == TextDecoration.none, isTrue, reason: '"$what" is underlined');
          return true;
        });
      }
    }

    // Twice, as the 401 race posted it: the same notice must not stack.
    final toasts = c.read(cineToastsProvider.notifier)
      ..info(kSignedOutToast)
      ..info(kSignedOutToast);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(c.read(cineToastsProvider), hasLength(1));
    expect(find.byType(CineStopPressBanner), findsOneWidget);
    expect(find.text(kSignedOutToast), findsOneWidget);
    expectNoUnderlines();

    // An action toast's label (`Undo`) reads by weight, not a rule.
    toasts.undo('Removed.', onUndo: () {});
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Undo'), findsOneWidget);
    expectNoUnderlines();
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 15));
  });
}
