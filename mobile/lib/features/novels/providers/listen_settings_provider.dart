import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/listen_settings.dart';

export 'package:manhwamaniacs/features/novels/models/listen_settings.dart';

/// The raw record views Settings (mobile/18) reads and writes under the same field names.
extension ListenSettingsView on JsonRecord {
  double get speed => normaliseListenSpeed(doubleOf('speed', 1.0));
  String get sleepDefault => choice('sleepDefault', kSleepDefaults, 'off');
  bool get autoPlayNext => boolOf('autoPlayNext', true);
  bool get keepPlayerVisible => boolOf('keepPlayerVisible', false);
  bool get shakeToExtend => boolOf('shakeToExtend', true);
  bool get glassShakeToExtend => boolOf('glassShakeToExtend', false);
}

class ListenSettingsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => kListenSettingsPrefix;
}

/// `mm.listen-settings.u{user}p{profile}`.
final listenSettingsProvider = NotifierProvider<ListenSettingsNotifier, JsonRecord>(ListenSettingsNotifier.new, name: 'listenSettings');

/// The normalised, typed view of [listenSettingsProvider].
final listenSettingsValueProvider = Provider<ListenSettings>(
  (ref) => ListenSettings.fromRecord(ref.watch(listenSettingsProvider)),
  name: 'listenSettingsValue',
);
