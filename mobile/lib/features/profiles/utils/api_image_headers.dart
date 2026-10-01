import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The credential headers for an API image (`/sources/.../cover` and the like) loaded by a plain
/// `Image.network` / `NetworkImage`, from any widget under the app's ProviderScope. Native builds carry
/// no session cookie, so without these the API answers 401 and the cover stays blank.
Map<String, String>? apiImageHeadersOf(BuildContext context) {
  final c = ProviderScope.containerOf(context, listen: false);
  return apiImageHttpHeaders(c.read(authTokenStoreProvider).token, profileId: c.read(activeProfileProvider)?.id);
}
