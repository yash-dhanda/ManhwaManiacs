import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/new_chapters_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';

import 'overlay_support.dart';
import 'support.dart';

ProviderContainer _c(WidgetTester t) => primContainer(t);

Future<OverlayHost> _host(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  final h = OverlayHost(tester);
  await h.pump(size: size, page: const GlassCapsuleHost(child: GlassToastHost(child: SizedBox.expand())));
  return h;
}

void main() {
  group('inline notice', () {
    testWidgets('every variant renders its text, its leading bar in the semantic colour and an optional action', (tester) async {
      var acted = 0;
      await tester.pumpWidget(primHost(SizedBox(
        width: 360,
        child: Column(children: [
          for (final v in GlassNoticeVariant.values) GlassInlineNotice(message: 'Notice ${v.name}', variant: v, actionLabel: 'Fix', onAction: () => acted++),
        ],),
      ),),);
      await tester.pump(const Duration(milliseconds: 100));
      for (final v in GlassNoticeVariant.values) {
        expect(find.text('Notice ${v.name}'), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('glass-notice-bar')), findsNWidgets(4));
      await tester.tap(find.text('Fix').first);
      await tester.pump();
      expect(acted, 1);
    });
  });

  group('status capsule', () {
    testWidgets('the four kinds and the live rate-limit countdown; inGroup adds no glass layer', (tester) async {
      await tester.pumpWidget(primHost(const GlassStatusCapsule(kind: GlassStatusKind.rateLimit)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sources are busy. Retrying in 12 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Sources are busy. Retrying in 9 s'), findsOneWidget);
      for (final e in {GlassStatusKind.offline: 'Offline', GlassStatusKind.savedCopy: 'Saved copy · 2 h', GlassStatusKind.syncing: 'Syncing'}.entries) {
        await tester.pumpWidget(const SizedBox.shrink()); // primHost's overlay entry keeps its first child
        await tester.pumpWidget(primHost(GlassStatusCapsule(kind: e.key)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text(e.value), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(primHost(const GlassStatusCapsule(kind: GlassStatusKind.offline, inGroup: true)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('glass-tab-capsule')), findsNothing);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('it dematerialises out when hidden', (tester) async {
      late StateSetter set;
      var visible = true;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassStatusCapsule(kind: GlassStatusKind.offline, visible: visible);
      },),),);
      await tester.pump(const Duration(milliseconds: 400));
      set(() => visible = false);
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      await pumpFor(tester, 600);
      expect(find.text('Offline'), findsNothing);
    });
  });

  group('new-chapters and app-update capsules', () {
    GlassNewChaptersSpec news(int id) => GlassNewChaptersSpec(
          id: id,
          chapters: 5,
          series: 3,
          covers: [for (var i = 0; i < 5; i++) ColoredBox(color: Color(0xFF223344 + i * 0x101010))],
        );

    testWidgets('a stack of up to 3 covers, the text, View, and the close button; it stays until acted on', (tester) async {
      await _host(tester);
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(1);
      await pumpFor(tester, 800);
      expect(find.text('5 new chapters in 3 series'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.descendant(of: find.byType(GlassNewChaptersCapsule), matching: find.byType(ColoredBox)), findsAtLeastNWidgets(3));
      await pumpFor(tester, 12000);
      expect(find.text('5 new chapters in 3 series'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('glass-capsule-close')));
      await pumpFor(tester, 900);
      expect(find.text('5 new chapters in 3 series'), findsNothing);
      // A newer notification shows again.
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(2);
      await pumpFor(tester, 900);
      expect(find.text('5 new chapters in 3 series'), findsOneWidget);
    });

    testWidgets('a swipe up dismisses it', (tester) async {
      await _host(tester);
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(1);
      await pumpFor(tester, 800);
      await tester.fling(find.text('5 new chapters in 3 series'), const Offset(0, -80), 900);
      await pumpFor(tester, 900);
      expect(find.text('5 new chapters in 3 series'), findsNothing);
    });

    testWidgets('phones: a toast wins the top band and the capsule re-appears when it leaves', (tester) async {
      await _host(tester);
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(1);
      await pumpFor(tester, 800);
      _c(tester).read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));
      await pumpFor(tester, 800);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('5 new chapters in 3 series').hitTestable(), findsNothing);
      await pumpFor(tester, 5000);
      expect(find.text('5 new chapters in 3 series'), findsOneWidget);
    });

    testWidgets('tablet: top-centre of the content column, 72 from the top, max 480 wide, and the toast waits', (tester) async {
      await _host(tester, size: const Size(834, 1194));
      _c(tester).read(glassSidebarEdgeProvider.notifier).state = 76;
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(1);
      await pumpFor(tester, 800);
      final r = tester.getRect(find.byType(GlassNewChaptersCapsule));
      expect(r.top, closeTo(72, 3));
      expect(r.width, lessThanOrEqualTo(480));
      expect(r.center.dx, closeTo(76 + (834 - 76) / 2, 4));
      _c(tester).read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));
      await pumpFor(tester, 800);
      expect(find.text('Saved').hitTestable(), findsNothing); // a toast waits while the capsule shows
    });

    testWidgets('the app-update capsule shows on Android only, after new chapters on phones', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await _host(tester);
      _c(tester).read(glassAppUpdateProvider.notifier).state = GlassAppUpdateSpec(onUpdate: () {});
      await pumpFor(tester, 800);
      expect(find.text('A new version is ready'), findsNothing); // iOS: SideStore updates the app
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      _c(tester).read(glassAppUpdateProvider.notifier).state = null;
      await pumpFor(tester, 100);
      var updated = 0;
      _c(tester).read(glassAppUpdateProvider.notifier).state = GlassAppUpdateSpec(onUpdate: () => updated++);
      await pumpFor(tester, 800);
      expect(find.text('A new version is ready'), findsOneWidget);
      _c(tester).read(glassNewChaptersProvider.notifier).state = news(1);
      await pumpFor(tester, 800);
      expect(find.text('A new version is ready').hitTestable(), findsNothing);
      _c(tester).read(glassNewChaptersProvider.notifier).state = null;
      await pumpFor(tester, 900);
      await tester.tap(find.text('Update'));
      await tester.pump();
      expect(updated, 1);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tablet: bottom-centre of the content column, waiting while a bottom bar shows', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await _host(tester, size: const Size(834, 1194));
      _c(tester).read(glassBottomBarProvider.notifier).state = true;
      _c(tester).read(glassAppUpdateProvider.notifier).state = GlassAppUpdateSpec(onUpdate: () {});
      await pumpFor(tester, 800);
      expect(find.text('A new version is ready').hitTestable(), findsNothing);
      _c(tester).read(glassBottomBarProvider.notifier).state = false;
      await pumpFor(tester, 800);
      final r = tester.getRect(find.byType(GlassAppUpdateCapsule));
      expect(r.center.dx, closeTo(834 / 2, 4));
      expect(r.bottom, greaterThan(1194 - 100));
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
