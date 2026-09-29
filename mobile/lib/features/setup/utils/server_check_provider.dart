import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';

typedef ServerChecker = Future<ServerCheck> Function(String input);

/// The real dependencies wired in. Tests override it with a fake.
final serverCheckProvider = Provider<ServerChecker>(
  (ref) => (input) => checkServer(
        input,
        releaseBuild: kReleaseMode,
        isOnline: () async {
          final r = await Connectivity().checkConnectivity();
          return !r.every((c) => c == ConnectivityResult.none);
        },
        dioFor: probeDio,
      ),
  name: 'serverCheck',
);
