import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

/// What follows a change of the ACTIVE profile's `mature_content_enabled` through the profile form: the server value is read again
/// and every gated cache is dropped, so the device stores (through `matureGateOpenProvider`) follow. Both skins call it.
void applyMatureGateChanged(WidgetRef ref) {
  ref.invalidate(matureContentProvider);
  ref.read(matureOverrideChangedProvider)();
}
