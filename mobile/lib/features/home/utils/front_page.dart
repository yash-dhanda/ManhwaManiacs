import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The Front page moment (cinematic 13, moment 2): once per day per profile; the at-risk line
/// types once more the first time it applies after 20:00.
enum FrontVariant { normal, atRisk }

typedef FrontStamp = ({String date, FrontVariant variant});

String localDateString(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// True when the stored date is not today or the stored variant differs.
bool shouldPlayFrontPage(FrontStamp? stored, DateTime now, FrontVariant variant) =>
    stored == null || stored.date != localDateString(now) || stored.variant != variant;

FrontStamp? decodeFrontStamp(String? raw) {
  if (raw == null) return null;
  try {
    final j = jsonDecode(raw);
    if (j is Map<String, dynamic> && j['date'] is String) {
      return (date: j['date'] as String, variant: j['variant'] == 'at-risk' ? FrontVariant.atRisk : FrontVariant.normal);
    }
  } catch (_) {}
  return null;
}

String encodeFrontStamp(FrontStamp s) => jsonEncode({'date': s.date, 'variant': s.variant == FrontVariant.atRisk ? 'at-risk' : 'normal'});

const _prefix = 'mm.tonight.typed.';

String _key(Ref ref, {required bool watch}) => profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: watch);

FrontStamp? readFrontStamp(Ref ref) => decodeFrontStamp(ref.read(sharedPrefsProvider).getString(_key(ref, watch: false)));

void writeFrontStamp(Ref ref, DateTime now, FrontVariant variant) =>
    ref.read(sharedPrefsProvider).setString(_key(ref, watch: false), encodeFrontStamp((date: localDateString(now), variant: variant)));

/// [Provider]-scoped reads for widgets: `ref.read(frontPageStoreProvider)`.
class FrontPageStore {
  FrontPageStore(this._ref);
  final Ref _ref;
  FrontStamp? read() => readFrontStamp(_ref);
  void mark(DateTime now, FrontVariant variant) => writeFrontStamp(_ref, now, variant);
}

final frontPageStoreProvider = Provider<FrontPageStore>(FrontPageStore.new, name: 'frontPageStore');
