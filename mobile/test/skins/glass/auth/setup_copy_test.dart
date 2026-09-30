import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/setup_copy.dart';

void main() {
  test('every failed check has its line, success has none', () {
    expect(setupFailureLine(const ServerCheck.ok('https://a')), isNull);
    expect(setupFailureLine(const ServerCheck.offline()), "You're offline. Connect to a network to reach your server.");
    expect(setupFailureLine(const ServerCheck.httpInRelease()), 'Use an https address');
    expect(setupFailureLine(const ServerCheck.notManhwaManiacs()), "That address isn't a ManhwaManiacs server");
    expect(setupFailureLine(const ServerCheck.tls()), "The server's certificate isn't trusted. Check the address or the server's HTTPS setup.");
    expect(setupFailureLine(const ServerCheck.timeout()), "Couldn't reach that address");
    expect(setupFailureLine(const ServerCheck.unreachable('x')), "Couldn't reach that address");
  });
}
