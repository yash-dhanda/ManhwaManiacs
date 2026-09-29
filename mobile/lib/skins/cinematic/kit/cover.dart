import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Resolves a cover URL (a backend-relative proxy path or an absolute URL) to
/// an authenticated [ImageProvider]. A provider of its own so tests and the
/// screenshot harness can swap in in-repo art.
final coverImageProvider = Provider<ImageProvider Function(String url, {double? width})>((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  final token = ref.watch(authTokenStoreProvider).token;
  final profileId = ref.watch(activeProfileProvider)?.id;
  return (url, {width}) {
    final resolved = coverUrlAtWidth(resolveApiResourceUrl(base, url), width == null ? null : coverRequestWidth(width, 3));
    return CachedNetworkImageProvider(resolved, headers: apiImageHttpHeaders(token, profileId: profileId));
  };
});
