import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_lifecycle_gate.dart';
import 'package:manhwamaniacs/features/downloads/providers/retention_maintenance_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/retention_maintenance.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_overrides.dart';

var _resumes = 0;
var _flushes = 0;

class _Queue extends DownloadQueueController {
  @override
  DownloadQueueState build() => const DownloadQueueState();
  @override
  void resumePendingOnLaunch() => _resumes++;
  @override
  void setForeground(bool foreground) {}
}

class _Bookmarks extends Fake implements BookmarkOutboxController {
  @override
  Future<bool> flush() async => true;
  @override
  Future<bool> sync() async => true;
}

class _Retention extends Fake implements RetentionMaintenance {}

class _Outbox extends Fake implements SkinOutbox {
  @override
  Future<void> flush() async => _flushes++;
}

void main() {
  testWidgets(
      'a restart runs the gate launch pass again (downloads resume, skin outbox flushes)',
      (tester) async {
    _resumes = 0;
    _flushes = 0;
    SharedPreferences.setMockInitialValues(testPrefsDefaults({}));
    final prefs = await SharedPreferences.getInstance();
    late BuildContext ctx;
    await tester.pumpWidget(AppRestart(builder: () {
      return ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          activeProfileOverride(),
          bookmarkOutboxControllerProvider.overrideWithValue(_Bookmarks()),
          retentionMaintenanceProvider.overrideWithValue(_Retention()),
          downloadQueueControllerProvider.overrideWith(_Queue.new),
          skinOutboxProvider.overrideWithValue(_Outbox()),
        ],
        child: Builder(builder: (c) {
          ctx = c;
          return const DownloadsLifecycleGate(child: SizedBox());
        },),
      );
    },),);
    await tester.pump();
    await tester.pump();
    expect(_resumes, 1);
    expect(_flushes, 1);

    AppRestart.of(ctx).restart();
    await tester.pump();
    await tester.pump();
    expect(_resumes, 2);
    expect(_flushes, 2);
  });
}
