import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/core/utils/fnv1a.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_stamper.dart';
import 'package:manhwamaniacs/features/downloads/services/blob_store.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// `"u{userId}p{profileId}"` — the leading column of every content primary
/// key in the on-device store. `null` when either half of the session is
/// missing, which is exactly when [downloadsStoreProvider] must hand back no
/// store at all.
///
/// [serverPrefix] is empty for the home server and `h{8 hex}` for any other, so a different server
/// can never read this server's rows (see [downloadsServerPrefix]).
String? downloadsScopeId({required int? userId, required int? profileId, String serverPrefix = ''}) {
  if (userId == null || profileId == null) return null;
  return '${serverPrefix}u${userId}p$profileId';
}

/// SharedPreferences key holding the "home" server: the base URL the app first stored downloads under.
const kDownloadsHomeServerKey = 'mm.downloads.home_server';

String normaliseServerUrl(String url) => url.trim().toLowerCase().replaceFirst(RegExp(r'/+$'), '');

/// `""` for the home server, else `h{8 hex digits of FNV-1a 32 of the normalised base URL}`. The
/// home server is recorded on the first read, so rows saved before servers could change keep
/// their ids, and switching back to the old server shows them again.
String downloadsServerPrefix(SharedPreferences prefs, String baseUrl) {
  final n = normaliseServerUrl(baseUrl);
  var home = prefs.getString(kDownloadsHomeServerKey);
  if (home == null) {
    home = n;
    unawaited(prefs.setString(kDownloadsHomeServerKey, n));
  }
  return home == n ? '' : 'h${fnv1a32(n).toRadixString(16).padLeft(8, '0')}';
}

/// The current `(user, profile)` scope id, or `null` outside an active
/// session. Watching this — not [downloadsStoreProvider] directly — is
/// enough for UI that only needs to know *whether* a store exists.
final activeDownloadsScopeIdProvider = Provider<String?>(
  (ref) {
    final userId = ref.watch(
      authControllerProvider.select(
        (auth) => auth is AuthAuthenticated ? auth.user.id : null,
      ),
    );
    final profileId = ref.watch(activeProfileProvider.select((p) => p?.id));
    final prefix = downloadsServerPrefix(ref.watch(sharedPrefsProvider), ref.watch(apiBaseUrlProvider));
    return downloadsScopeId(userId: userId, profileId: profileId, serverPrefix: prefix);
  },
  name: 'activeDownloadsScopeId',
);

/// Generous upper bound for opening the local database/blob directory —
/// real disk I/O never approaches this. Its actual job is turning a wedged
/// platform channel (no native handler registered — every automated widget
/// test, and the one real-world case this could ever matter for: a corrupt
/// plugin registration) into a prompt, catchable failure instead of a hang
/// that never resolves. [DownloadsStore] callers already treat a failure
/// here as "store unavailable" (see `services/offline_reader.dart`'s
/// defensive catches), so timing out degrades exactly like any other
/// platform-channel error.
const _openTimeout = Duration(seconds: 3);

/// How [downloadsDatabaseProvider] opens the database. A provider only so a
/// test can stand in a failing or hanging open.
final downloadsDatabaseOpenerProvider = Provider<Future<Database> Function()>(
  (ref) => openDownloadsDatabase,
  name: 'downloadsDatabaseOpener',
);

/// How [blobStoreProvider] locates the blob tree; see
/// [downloadsDatabaseOpenerProvider].
final blobStoreOpenerProvider = Provider<Future<BlobStore> Function()>(
  (ref) => BlobStore.forApplicationDocuments,
  name: 'blobStoreOpener',
);

/// The single shared database backing every scope's `saved_chapters` /
/// `saved_pages` rows and the cross-scope `blobs` table. Opened once
/// (`keepAlive` — a `Provider`, not `autoDispose`) and reused for the life of
/// the app; switching profiles only changes which `scope_id` rows a
/// [DownloadsStore] built on top of it will read or write.
///
/// Only a SUCCESSFUL open is kept: see [_retriedOnFailure].
final downloadsDatabaseProvider = Provider<Future<Database>>(
  (ref) => _retriedOnFailure(
    ref,
    ref.watch(downloadsDatabaseOpenerProvider)().timeout(_openTimeout),
    failures: ref.watch(_databaseOpenFailuresProvider),
    what: 'downloads database',
  ),
  name: 'downloadsDatabase',
);

/// The content-addressed blob tree under `Documents/mm-store/blobs` — shared
/// across scopes for cross-profile dedup, same reasoning as the database.
final blobStoreProvider = Provider<Future<BlobStore>>(
  (ref) => _retriedOnFailure(
    ref,
    ref.watch(blobStoreOpenerProvider)().timeout(_openTimeout),
    failures: ref.watch(_blobStoreOpenFailuresProvider),
    what: 'blob store',
  ),
  name: 'blobStore',
);

/// Failed opens in a row, kept outside the provider it counts for because
/// that provider's own state is discarded on every retry.
class _OpenFailures {
  int count = 0;
}

final _databaseOpenFailuresProvider = Provider<_OpenFailures>(
  (ref) => _OpenFailures(),
  name: 'downloadsDatabaseOpenFailures',
);

final _blobStoreOpenFailuresProvider = Provider<_OpenFailures>(
  (ref) => _OpenFailures(),
  name: 'blobStoreOpenFailures',
);

/// The longest [_retriedOnFailure] waits between two attempts.
const _maxRetryDelay = Duration(seconds: 30);

/// [opening], with the provider building it invalidated if it fails.
///
/// These providers live for the whole process, so a failed Future they
/// returned used to be THE answer until the app was killed: one slow cold
/// start that tripped [_openTimeout] left every progress save throwing before
/// its POST and every outbox flush failing silently, for the rest of the
/// session. Invalidated, the next read opens again — and a store built on
/// the old Future is rebuilt with it, since [downloadsStoreProvider] watches
/// this one.
///
/// The first failure is retried at once. Further ones in a row wait 1 s, 2 s,
/// 4 s … up to [_maxRetryDelay]: every screen watching the store rebuilds on
/// each invalidation and opens again as it does, so an open that fails
/// straight away, every time (a corrupt file), would otherwise be retried
/// once a frame.
Future<T> _retriedOnFailure<T>(
  Ref ref,
  Future<T> opening, {
  required _OpenFailures failures,
  required String what,
}) {
  var disposed = false;
  Timer? retry;
  ref.onDispose(() {
    disposed = true;
    retry?.cancel();
  });
  unawaited(
    opening.then<void>(
      (_) => failures.count = 0,
      onError: (Object error, StackTrace stackTrace) {
        final inARow = failures.count++;
        appLogger.w(
          'Opening the $what failed ($inARow before it in a row); retrying',
          error,
          stackTrace,
        );
        if (disposed) return;
        if (inARow == 0) {
          ref.invalidateSelf();
          return;
        }
        final seconds = 1 << (inARow - 1).clamp(0, 5);
        final wait = Duration(seconds: seconds) > _maxRetryDelay
            ? _maxRetryDelay
            : Duration(seconds: seconds);
        retry = Timer(wait, ref.invalidateSelf);
      },
    ),
  );
  return opening;
}

/// The on-device chapter store for the active `(user, profile)` scope, or
/// `null` when no scope is resolvable — the structural half of isolation
/// (see [DownloadsStore]'s doc comment for the other half). Every screen that
/// reads or writes downloads must watch this, not construct a
/// [DownloadsStore] itself, so there is exactly one place scope resolution
/// can go wrong.
final downloadsStoreProvider = Provider<DownloadsStore?>(
  (ref) {
    final scopeId = ref.watch(activeDownloadsScopeIdProvider);
    if (scopeId == null) return null;
    return DownloadsStore(
      scopeId: scopeId,
      database: ref.watch(downloadsDatabaseProvider),
      blobStore: ref.watch(blobStoreProvider),
      matureResolver: (sourceId, seriesKey) =>
          ref.read(matureStamperProvider).resolve(sourceId, seriesKey),
    );
  },
  name: 'downloadsStore',
);
