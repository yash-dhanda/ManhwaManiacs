import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has any network at all. Optimistic until the platform
/// answers, so a slow first read never disables a control.
final deviceOnlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  try {
    yield !(await c.checkConnectivity()).contains(ConnectivityResult.none);
    yield* c.onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none));
  } catch (_) {
    yield true;
  }
});

/// `false` only when the platform says there is no network.
bool isOnline(WidgetRef ref) => ref.watch(deviceOnlineProvider).valueOrNull ?? true;
