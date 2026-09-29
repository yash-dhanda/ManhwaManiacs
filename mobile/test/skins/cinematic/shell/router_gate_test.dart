import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/router_gate.dart';

CineGateState _s({bool setup = true, CineAuth auth = CineAuth.authenticated, bool profile = true}) =>
    CineGateState(setupCompleted: setup, auth: auth, hasActiveProfile: profile);

String? _r(CineGateState s, String loc) => cineRedirect(s, Uri.parse(loc));

void main() {
  test('setup not completed goes to /setup, and /setup is allowed', () {
    expect(_r(_s(setup: false), '/'), '/setup');
    expect(_r(_s(setup: false, auth: CineAuth.unknown), '/library'), '/setup');
    expect(_r(_s(setup: false), '/setup'), isNull);
  });

  test('an unknown session holds on /splash with the requested location', () {
    final r = _r(_s(auth: CineAuth.unknown), '/library?sort=title')!;
    final u = Uri.parse(r);
    expect(u.path, '/splash');
    expect(u.queryParameters['from'], '/library?sort=title');
    expect(_r(_s(auth: CineAuth.unknown), '/splash?from=%2Flibrary'), isNull);
  });

  test('from round-trips awkward locations', () {
    const loc = '/search?q=a%20b&scope=all&x=%25';
    final hold = Uri.parse(_r(_s(auth: CineAuth.unknown), loc)!);
    expect(hold.queryParameters['from'], loc);
    expect(_r(_s(), hold.toString()), loc);
  });

  test('signed out goes to /login unless on login or register', () {
    final s = _s(auth: CineAuth.unauthenticated);
    expect(_r(s, '/'), '/login');
    expect(_r(s, '/splash?from=%2F'), '/login');
    expect(_r(s, '/login'), isNull);
    expect(_r(s, '/register'), isNull);
  });

  test('signed in with no profile goes to the picker', () {
    final s = _s(profile: false);
    expect(_r(s, '/'), '/profiles');
    expect(_r(s, '/login'), '/profiles');
    for (final ok in ['/profiles', '/profiles/new', '/profiles/create', '/profiles/3/edit', '/profiles/edit/3']) {
      expect(_r(s, ok), isNull, reason: ok);
    }
  });

  test('a remembered profile passes the picker', () {
    final s = _s();
    expect(_r(s, '/'), isNull);
    expect(_r(s, '/library'), isNull);
    expect(_r(s, '/profiles'), isNull); // Switch profile
  });

  test('auth routes bounce a signed-in user to from, or home', () {
    final s = _s();
    expect(_r(s, '/login'), '/');
    expect(_r(s, '/register'), '/');
    expect(_r(s, '/setup'), '/');
    expect(_r(s, '/splash'), '/');
    expect(_r(s, '/splash?from=%2Fupdates'), '/updates');
    expect(_r(s, '/splash?from=%2Flogin'), '/');
    expect(_r(s, '/splash?from=http%3A%2F%2Fevil'), '/');
  });

  test('an active profile cleared by profile_required goes back to the picker', () {
    expect(_r(_s(profile: false), '/library'), '/profiles');
  });
}
