import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profile_scope.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Changing the API server from Settings (cinematic 8.30.2 row 13). Validation is Setup's
/// (`GET /health`, name `ManhwaManiacs`, https in release, 8 s); confirming signs out on the OLD
/// server, drops every profile-scoped cache and the image cache, then stores the new address.
/// Downloads stay: their scope ids carry the server (`downloadsServerPrefix`).
class ServerSwitch {
  ServerSwitch(this._ref);

  final Ref _ref;

  Future<ServerCheck> check(String input) => _ref.read(serverCheckProvider)(input);

  /// The address the app currently talks to.
  String get current => _ref.read(apiBaseUrlProvider);

  /// True when [normalisedUrl] is the server already in use.
  bool isSame(String normalisedUrl) => normaliseAddress(normalisedUrl) == normaliseAddress(current);

  /// Sign out, clear, save. Null on success.
  Future<AppError?> confirm(String normalisedUrl) async {
    await _ref.read(authControllerProvider.notifier).logout();
    invalidateProfileScopedProviders(_ref);
    await _ref.read(imageCacheServiceProvider).clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    return _ref.read(settingsActionsProvider).saveApiUrl(normalisedUrl);
  }

  /// Back to the built-in default address. When that changes the server it signs out and drops
  /// the profile caches first, exactly like [confirm]; then the saved override is cleared so the
  /// next cold start boots against the same default. Null on success.
  Future<AppError?> reset() async {
    if (!isSame(Env.defaultApiUrl)) {
      final err = await confirm(Env.defaultApiUrl);
      if (err != null) return err;
    }
    await _ref.read(settingsActionsProvider).resetApiUrl();
    return null;
  }
}

String normaliseAddress(String url) => url.trim().toLowerCase().replaceFirst(RegExp(r'/+$'), '');

final serverSwitchProvider = Provider<ServerSwitch>(ServerSwitch.new, name: 'serverSwitch');
