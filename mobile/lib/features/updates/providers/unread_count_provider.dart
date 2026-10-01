import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Unread new-chapter notifications for the active profile: read every 60 s while the app is in
/// the foreground and at once on resume. 0 with no session or profile. The Cinematic thumb
/// index badge and the stop-press banner read it; legacy does not.
final unreadNotificationCountProvider = NotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
  name: 'unreadNotificationCount',
);

/// How often the count is re-read. An override point for tests.
final unreadPollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 60));

class UnreadCountNotifier extends Notifier<int> with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _alive = false;

  @override
  int build() {
    final signedIn = ref.watch(authControllerProvider) is AuthAuthenticated;
    // The id, not just presence: a switch from one profile to another starts again from that profile's count.
    final hasProfile = ref.watch(activeProfileProvider.select((p) => p?.id)) != null;
    final every = ref.watch(unreadPollIntervalProvider);
    _alive = true;
    _foreground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    ref.onDispose(() {
      _alive = false;
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    if (!signedIn || !hasProfile) return 0;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(every, (_) => _fetch());
    unawaited(_fetch());
    return 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (state == AppLifecycleState.resumed) unawaited(_fetch());
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    if (!_foreground || !_alive) return;
    try {
      final r = await ref.read(updatesRepositoryProvider).getUnreadCount();
      if (_alive && r.isOk) state = r.value;
    } catch (_) {
      // Offline or busy: keep the last count.
    }
  }
}

/// `{chapters, series, maxId}` of the unread notifications, or null when there are none.
typedef NewChaptersBanner = ({int chapters, int series, int maxId});

final newChaptersBannerProvider = FutureProvider<NewChaptersBanner?>(
  (ref) async {
    final count = ref.watch(unreadNotificationCountProvider);
    if (count <= 0) return null;
    final r = await ref.read(updatesRepositoryProvider).listNotifications(unreadOnly: true);
    if (r.isErr || r.value.isEmpty) return null;
    final rows = r.value;
    final series = {for (final n in rows) '${n.sourceId}|${n.seriesKey}'};
    var maxId = 0;
    for (final n in rows) {
      if (n.id > maxId) maxId = n.id;
    }
    return (chapters: count > rows.length ? count : rows.length, series: series.length, maxId: maxId);
  },
  name: 'newChaptersBanner',
);
