import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import '../../../support/test_overrides.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';

ReaderPrefs resolve({Map<String, dynamic> profile = const {}, Map<String, dynamic>? series}) =>
    ReaderPrefs.resolve(JsonRecord(profile), series == null ? null : JsonRecord(series));

void main() {
  test('a missing cruiseSpeed reads the profile default, then 1.0', () {
    expect(resolve().cruiseSpeed, 1.0);
    expect(resolve(profile: {'glass': {'cruiseDefault': 1.5}}).cruiseSpeed, 1.5);
    expect(resolve(profile: {'glass': {'cruiseDefault': 1.5}}, series: {'cruiseSpeed': 2.0}).cruiseSpeed, 2.0);
  });

  test('cruiseSpeed clamps to 0.25-4.00 and snaps to 0.05', () {
    expect(resolve(series: {'cruiseSpeed': 4.3}).cruiseSpeed, 4.0);
    expect(resolve(series: {'cruiseSpeed': 0.1}).cruiseSpeed, 0.25);
    expect(resolve(series: {'cruiseSpeed': 1.26}).cruiseSpeed, 1.25);
  });

  test('a soundscape record round-trips and a bad scene reads as none', () {
    final r = resolve(series: {'soundscape': const SeriesSoundscape(scene: 'rain', bed: 0.6, detail: 0.2, tone: 0.9).toJson()});
    expect(r.soundscape!.scene, 'rain');
    expect(r.soundscape!.bed, 0.6);
    expect(r.soundscape!.toJson()['mix'], {'bed': 0.6, 'detail': 0.2, 'tone': 0.9});
    expect(resolve(series: {'soundscape': {'scene': 'nope'}}).soundscape, isNull);
    expect(resolve(series: {'soundscape': {'scene': 'wind', 'mix': {'bed': 7}}}).soundscape!.bed, 1.0);
  });

  test('setSoundscape writes and removes the record and keeps unknown fields; profiles stay apart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()]);
    addTearDown(c.dispose);
    final n = c.read(readerSeriesPrefsProvider.notifier);
    await n.setFor('s:1', {'future': 7, 'cruiseSpeed': 1.5});
    await n.setSoundscape('s:1', const SeriesSoundscape(scene: 'wind'));
    var own = c.read(readerSeriesPrefsProvider).child('s:1');
    expect(own.data['future'], 7);
    expect(SeriesSoundscape.of(own.child('soundscape'))!.scene, 'wind');
    await n.setSoundscape('s:1', null);
    own = c.read(readerSeriesPrefsProvider).child('s:1');
    expect(own.data.containsKey('soundscape'), isFalse);
    expect(own.data['future'], 7);
    final keys = prefs.getKeys().where((k) => k.startsWith('mm.reader-prefs.')).toList();
    expect(keys.single, matches(r'^mm\.reader-prefs\.u\d+p\d+$'));
  });
}
