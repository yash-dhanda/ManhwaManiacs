import 'dart:io';

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/network/base_url.dart';

/// The outcome of probing a server address before it is saved (cinematic 8.1).
sealed class ServerCheck {
  const ServerCheck();
  const factory ServerCheck.ok(String normalisedUrl) = ServerCheckOk;
  const factory ServerCheck.offline() = ServerCheckOffline;
  const factory ServerCheck.httpInRelease() = ServerCheckHttpInRelease;
  const factory ServerCheck.notManhwaManiacs() = ServerCheckNotManhwaManiacs;
  const factory ServerCheck.tls() = ServerCheckTls;
  const factory ServerCheck.timeout() = ServerCheckTimeout;
  const factory ServerCheck.unreachable(String message) = ServerCheckUnreachable;
}

class ServerCheckOk extends ServerCheck {
  const ServerCheckOk(this.normalisedUrl);
  final String normalisedUrl;
}

class ServerCheckOffline extends ServerCheck {
  const ServerCheckOffline();
}

class ServerCheckHttpInRelease extends ServerCheck {
  const ServerCheckHttpInRelease();
}

class ServerCheckNotManhwaManiacs extends ServerCheck {
  const ServerCheckNotManhwaManiacs();
}

class ServerCheckTls extends ServerCheck {
  const ServerCheckTls();
}

class ServerCheckTimeout extends ServerCheck {
  const ServerCheckTimeout();
}

class ServerCheckUnreachable extends ServerCheck {
  const ServerCheckUnreachable(this.message);
  final String message;
}

/// A plain Dio (no interceptors: the error classification below needs the raw cause).
Dio probeDio(String baseUrl) => Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Accept': 'application/json'},
      ),
    );

/// Checks [input] in the order of the causes: offline, http in release, then `GET /health`.
Future<ServerCheck> checkServer(
  String input, {
  required bool releaseBuild,
  required Future<bool> Function() isOnline,
  required Dio Function(String baseUrl) dioFor,
}) async {
  final url = input.trim().replaceFirst(RegExp(r'/+$'), '');
  if (!await isOnline()) return const ServerCheck.offline();
  if (releaseBuild && url.toLowerCase().startsWith('http://')) {
    return const ServerCheck.httpInRelease();
  }
  final policy = BaseUrl.validate(url);
  if (policy != null) {
    return url.toLowerCase().startsWith('http://')
        ? const ServerCheck.httpInRelease()
        : ServerCheck.unreachable(policy.message);
  }
  try {
    final r = await dioFor(url).get<dynamic>('/health');
    final data = r.data;
    if (data is Map && data['name'] == 'ManhwaManiacs') return ServerCheck.ok(url);
    return const ServerCheck.notManhwaManiacs();
  } on DioException catch (e) {
    final cause = e.error;
    if (cause is HandshakeException ||
        (e.message ?? '').contains('CERTIFICATE_VERIFY_FAILED') ||
        cause.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
        e.type == DioExceptionType.badCertificate) {
      return const ServerCheck.tls();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ServerCheck.timeout();
    }
    if (e.response != null) return const ServerCheck.notManhwaManiacs();
    return ServerCheck.unreachable(e.message ?? 'Unable to reach server.');
  } catch (e) {
    return ServerCheck.unreachable(e.toString());
  }
}
