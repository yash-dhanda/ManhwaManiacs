import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

/// "Clear metadata cache": invalidates the same providers the legacy Storage screen's button
/// does ([metadataCacheInvalidators]); nothing on disk is touched.
void clearMetadataCache(Ref ref) {
  for (final invalidate in metadataCacheInvalidators) {
    invalidate(ref);
  }
}

/// The widget-side twin, for a screen that holds a [WidgetRef].
void clearMetadataCacheFromWidget(WidgetRef ref) => ref.read(settingsActionsProvider).clearMetadataCache();
