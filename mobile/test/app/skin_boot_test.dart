import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/skin_boot_check.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs(Map<String, Object> v) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

void main() {
  group('resolveSkin', () {
    test('debug glass is forced to cinematic while glass is unavailable', () async {
      expect(
          SkinBoot.resolveSkin(await _prefs(
              {kSkinDebugKey: 'glass', kSkinActiveKey: 'cinematic'},),),
          SkinId.cinematic,);
    });
    test('glass active with the flag off becomes cinematic', () async {
      expect(SkinBoot.resolveSkin(await _prefs({kSkinActiveKey: 'glass'})),
          SkinId.cinematic,);
    });
    test('invalid strings are ignored, nothing gives the default', () async {
      expect(
          SkinBoot.resolveSkin(
              await _prefs({kSkinDebugKey: 'x', kSkinActiveKey: 'y'}),),
          kDefaultSkin,);
      expect(SkinBoot.resolveSkin(await _prefs({})), kDefaultSkin);
    });
    test('without debug skips the override', () async {
      final p =
          await _prefs({kSkinDebugKey: 'cinematic', kSkinActiveKey: 'legacy'});
      expect(SkinBoot.resolveSkinWithoutDebug(p), SkinId.cinematic);
    });
  });

  test('read consumes the return route and session flag', () async {
    final p = await _prefs({kSkinReturnKey: '/library', kSkinSessionKey: '1'});
    final a = SkinBoot.read(p);
    expect((a.returnRoute, a.carrySession), ('/library', true));
    final b = SkinBoot.read(p);
    expect((b.returnRoute, b.carrySession), (null, false));
  });

  group('resolveBootRestart', () {
    SkinId? r({
      SkinId running = SkinId.legacy,
      SkinId? debug,
      bool known = true,
      String? profile,
      String? queued,
      bool glass = false,
      SkinId def = SkinId.legacy,
    }) =>
        resolveBootRestart(
          running: running,
          debugOverride: debug,
          profileKnown: known,
          profileSkin: profile,
          queuedOutboxSkin: queued,
          glassAvailable: glass,
          defaultSkin: def,
        );
    test('table', () {
      expect(r(debug: SkinId.cinematic, profile: 'glass'),
          isNull,); // debug override
      expect(r(known: false, profile: 'cinematic'), isNull); // offline
      expect(r(profile: 'cinematic', queued: 'legacy'), isNull); // outbox wins
      expect(r(profile: 'cinematic'), SkinId.cinematic); // mismatch
      expect(
          r(running: SkinId.cinematic, profile: 'cinematic'), isNull,); // match
      expect(r(profile: 'glass'), SkinId.cinematic); // glass coerced
      expect(r(running: SkinId.cinematic, profile: 'glass'), isNull);
      expect(r(profile: 'glass', glass: true), SkinId.glass);
      expect(r(), isNull); // default == running
      expect(r(running: SkinId.cinematic), SkinId.legacy);
      expect(r(profile: 'nonsense', running: SkinId.cinematic), SkinId.legacy);
    });
  });

  test('loop guard: same target inside 10 s is refused', () async {
    final p = await _prefs({kSkinBootRestartKey: 'cinematic:100000'});
    expect(bootRestartAllowed(p, SkinId.cinematic, 105000), isFalse);
    expect(bootRestartAllowed(p, SkinId.cinematic, 110000), isTrue);
    expect(bootRestartAllowed(p, SkinId.glass, 101000), isTrue);
    expect(bootRestartAllowed(await _prefs({}), SkinId.cinematic, 1), isTrue);
  });
}
