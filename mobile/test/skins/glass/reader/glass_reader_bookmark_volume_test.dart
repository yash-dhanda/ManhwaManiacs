// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/native_bridge.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

import 'glass_reader_rig.dart';

/// Logs every bookmark the reader creates (no store needed).
class _LoggingOutbox extends BookmarkOutboxController {
  _LoggingOutbox(ReaderRepository repo) : super(store: null, repository: repo, activeScopeId: () => 'u1p1');
  final List<({ChapterIdentity id, int page})> log = [];

  @override
  Future<Bookmark?> create({
    required ChapterIdentity id,
    required BookmarkMedia media,
    required int anchorIndex,
    required double anchorFraction,
    required int anchorTotal,
    String? seriesTitle,
    double? chapterNumber,
    String? snippet,
    String? note,
  }) async {
    log.add((id: id, page: anchorIndex));
    final now = DateTime.now().toUtc();
    return Bookmark(
        clientId: 'b${log.length}',
        sourceId: id.sourceId,
        seriesKey: id.seriesKey,
        chapterKey: id.chapterKey,
        createdAt: now,
        updatedAt: now,
        anchorIndex: anchorIndex);
  }
}

class _Bridge implements NativeBridge {
  // ignore: close_sinks
  final events = StreamController<VolumeKeyDirection>.broadcast();
  final List<bool> calls = [];

  @override
  Future<void> setVolumeKeyNavEnabled(bool enabled) async => calls.add(enabled);
  @override
  Stream<VolumeKeyDirection> get volumeKeyEvents => events.stream;
  @override
  Future<DeviceMemoryInfo?> getDeviceMemoryInfo() async => null;
  @override
  Future<void> setHighRefreshRateEnabled(bool enabled) async {}
}

List<String> _toasts(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(glassToastProvider).map((e) => e.spec.message).toList();

void main() {
  testWidgets('b saves a bookmark through the outbox and toasts "Saved this spot"', (t) async {
    late _LoggingOutbox outbox;
    await pumpGlassReader(t, extra: [
      bookmarkOutboxControllerProvider.overrideWith((ref) => outbox = _LoggingOutbox(ref.watch(readerRepositoryProvider))),
    ]);
    await settleReader(t, ms: 1000);
    await t.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
    await settleReader(t, ms: 600);
    expect(outbox.log, hasLength(1));
    expect(outbox.log.single.id.chapterKey, 'c2');
    expect(_toasts(t), contains('Saved this spot'));
    await disposeGlassReader(t);
  });

  testWidgets('volume keys: enabled only while mounted on Android with K08 on; down turns forward', (t) async {
    final bridge = _Bridge();
    await pumpGlassReader(t,
        platform: TargetPlatform.android,
        prefsValues: {'settings_volume_key_navigation': true},
        extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(t, ms: 1000);
    expect(bridge.calls, contains(true));
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    final before = s.engine.value.page;
    bridge.events.add(VolumeKeyDirection.down);
    await settleReader(t, ms: 800);
    expect(s.engine.value.page, before + 1);
    // Backgrounded: interception is released.
    for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      t.binding.handleAppLifecycleStateChanged(st);
    }
    await t.pump();
    expect(bridge.calls.last, isFalse);
    for (final st in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      t.binding.handleAppLifecycleStateChanged(st);
    }
    await t.pump();
    expect(bridge.calls.last, isTrue);
    await disposeGlassReader(t);
    expect(bridge.calls.last, isFalse, reason: 'released on dispose');
  });

  testWidgets('volume keys stay off with K08 off, and on iOS', (t) async {
    final bridge = _Bridge();
    await pumpGlassReader(t, platform: TargetPlatform.android, extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(t, ms: 800);
    expect(bridge.calls, isNot(contains(true)));
    await disposeGlassReader(t);

    final ios = _Bridge();
    await pumpGlassReader(t, prefsValues: {'settings_volume_key_navigation': true}, extra: [nativeBridgeProvider.overrideWithValue(ios)]);
    await settleReader(t, ms: 800);
    expect(ios.calls, isNot(contains(true)));
    await disposeGlassReader(t);
  });
}
