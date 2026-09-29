import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';

ProviderContainer _c({bool phone = true}) {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(overlayQueueProvider.notifier).setPhone(phone);
  return c;
}

Set<OverlayKind> _vis(ProviderContainer c) => c.read(overlayQueueProvider).visible;

void main() {
  group('phone top band', () {
    test('alert > toast > new-chapters > app-update, one at a time', () {
      final c = _c();
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.appUpdate);
      expect(_vis(c), {OverlayKind.appUpdate});
      q.requestSlot(OverlayKind.newChapters);
      expect(_vis(c), {OverlayKind.newChapters});
      q.requestSlot(OverlayKind.toast);
      expect(_vis(c), {OverlayKind.toast});
      q.requestSlot(OverlayKind.alert);
      expect(_vis(c), {OverlayKind.alert});
    });

    test('the new-chapters capsule re-appears when a higher one leaves', () {
      final c = _c();
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.newChapters);
      q.requestSlot(OverlayKind.toast);
      expect(_vis(c), {OverlayKind.toast});
      q.release(OverlayKind.toast);
      expect(_vis(c), {OverlayKind.newChapters});
    });
  });

  group('behind an open menu', () {
    test('toasts, the new-chapters capsule and the app-update capsule all wait', () {
      for (final phone in [true, false]) {
        final c = _c(phone: phone);
        final q = c.read(overlayQueueProvider.notifier);
        q.requestSlot(OverlayKind.toast);
        q.requestSlot(OverlayKind.newChapters);
        q.requestSlot(OverlayKind.appUpdate);
        final close = q.registerBlocker();
        expect(_vis(c), isEmpty, reason: 'phone=$phone');
        close();
        expect(_vis(c), isNotEmpty);
      }
    });

    test('an item already showing leaves when a menu opens and returns when it closes', () {
      final c = _c();
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.toast);
      expect(c.read(overlaySlotVisibleProvider(OverlayKind.toast)), isTrue);
      final close = q.registerBlocker();
      expect(c.read(overlaySlotVisibleProvider(OverlayKind.toast)), isFalse);
      close();
      close(); // idempotent
      expect(c.read(overlaySlotVisibleProvider(OverlayKind.toast)), isTrue);
    });

    test('two menus need both to close', () {
      final c = _c();
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.toast);
      final a = q.registerBlocker();
      final b = q.registerBlocker();
      a();
      expect(_vis(c), isEmpty);
      b();
      expect(_vis(c), {OverlayKind.toast});
    });
  });

  group('tablet and desktop frames', () {
    test('toasts and the new-chapters capsule share one queue', () {
      final c = _c(phone: false);
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.toast);
      expect(_vis(c), {OverlayKind.toast});
      q.requestSlot(OverlayKind.newChapters);
      expect(_vis(c), {OverlayKind.newChapters}); // a toast waits while the capsule shows
      q.release(OverlayKind.newChapters);
      expect(_vis(c), {OverlayKind.toast});
    });

    test('the app-update capsule waits behind the bulk toolbar or the unsaved-changes bar', () {
      final c = _c(phone: false);
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.appUpdate);
      expect(_vis(c), {OverlayKind.appUpdate});
      c.read(glassBottomBarProvider.notifier).state = true;
      expect(_vis(c), isEmpty);
      q.requestSlot(OverlayKind.toast);
      expect(_vis(c), {OverlayKind.toast});
      c.read(glassBottomBarProvider.notifier).state = false;
      expect(_vis(c), {OverlayKind.toast, OverlayKind.appUpdate});
    });

    test('an alert does not block toasts', () {
      final c = _c(phone: false);
      final q = c.read(overlayQueueProvider.notifier);
      q.requestSlot(OverlayKind.toast);
      q.requestSlot(OverlayKind.alert);
      expect(_vis(c), {OverlayKind.alert, OverlayKind.toast});
    });
  });
}
