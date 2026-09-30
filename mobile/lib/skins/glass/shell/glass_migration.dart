import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/utils/glass_prefs_migration.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';

/// Runs the one-time Glass prefs migration (glass 8.25.3) for each profile the first time it is active in the Glass skin, then
/// drops the records it may have written under a screen that already read them. The Glass router keeps it alive.
final glassPrefsMigrationProvider = Provider<void>((ref) {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  void run() {
    final auth = ref.read(authControllerProvider);
    final profile = ref.read(activeProfileProvider);
    if (auth is! AuthAuthenticated || profile == null) return;
    runGlassPrefsMigration(ref.read(sharedPrefsProvider), userId: auth.user.id, profileId: profile.id).then((ran) {
      if (!ran || disposed) return;
      ref
        ..invalidate(readerSettingsProvider)
        ..invalidate(glassPrefsRecordProvider);
    });
  }

  ref.listen(activeProfileProvider, (_, __) => run(), fireImmediately: true);
}, name: 'glassPrefsMigration',);
