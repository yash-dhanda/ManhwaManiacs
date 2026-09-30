import 'package:manhwamaniacs/features/setup/utils/server_check.dart';

/// Pure copy of Setup (glass 8.1, 12.5): the failure of a server check as the line under the field.
const String kSetupTitle = 'Connect your server';
const String kSetupSubtitle = 'Enter the address of your ManhwaManiacs server. You can change it later in Settings.';
const String kSetupLabel = 'Server address';
const String kSetupPlaceholder = 'https://manhwamaniacs.example';
const String kSetupHttpsHelper = 'https is required.';
const String kSetupOffline = "You're offline. Connect to a network to reach your server.";

/// The line for a failed check; null for [ServerCheckOk].
String? setupFailureLine(ServerCheck c) => switch (c) {
      ServerCheckOk() => null,
      ServerCheckOffline() => kSetupOffline,
      ServerCheckHttpInRelease() => 'Use an https address',
      ServerCheckNotManhwaManiacs() => "That address isn't a ManhwaManiacs server",
      ServerCheckTls() => "The server's certificate isn't trusted. Check the address or the server's HTTPS setup.",
      ServerCheckTimeout() || ServerCheckUnreachable() => "Couldn't reach that address",
    };
