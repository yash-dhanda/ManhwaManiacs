import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// `capabilities` of `GET /settings`. Everything is true while unknown or offline, which is
/// what the app does today.
class ServerCapabilities {
  const ServerCapabilities({
    this.onlineSources = true,
    this.clientDownloads = true,
    this.ocr = true,
    this.collections = true,
    this.bookmarks = true,
    this.continueReading = true,
    this.readingProgress = true,
  });

  final bool onlineSources, clientDownloads, ocr, collections, bookmarks, continueReading, readingProgress;

  factory ServerCapabilities.fromJson(Object? json) {
    if (json is! Map) return const ServerCapabilities();
    bool f(String k) => json[k] is bool ? json[k] as bool : true;
    return ServerCapabilities(
      onlineSources: f('online_sources'),
      clientDownloads: f('client_downloads'),
      ocr: f('ocr'),
      collections: f('collections'),
      bookmarks: f('bookmarks'),
      continueReading: f('continue_reading'),
      readingProgress: f('reading_progress'),
    );
  }
}

final serverCapabilitiesProvider = FutureProvider<ServerCapabilities>(
  (ref) async {
    try {
      final r = await ref.watch(dioProvider).get<Map<String, dynamic>>('/settings');
      return ServerCapabilities.fromJson(r.data?['capabilities']);
    } on DioException {
      return const ServerCapabilities();
    } catch (_) {
      return const ServerCapabilities();
    }
  },
  name: 'serverCapabilities',
);
