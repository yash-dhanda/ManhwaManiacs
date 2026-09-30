import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';

/// The Glass per-profile preferences entry (`mm.glass.prefs.u{user}p{profile}` in SharedPreferences, glass 15.5). Other Glass
/// steps add their own fields; a write merges, never overwrites the rest.
class GlassPrefsRecord extends ProfileRecordNotifier {
  @override
  String get prefix => 'mm.glass.prefs.';

  /// Settings -> Appearance: the light tilts with the device (default on in the apps); off pins it at 135 degrees.
  bool get lightFollowsDevice => state.boolOf('lightFollowsDevice', true);

  Future<void> setLightFollowsDevice(bool v) => put({'lightFollowsDevice': v});

  bool get autoPlayPreviews => state.boolOf('autoPlayPreviews', true);

  Future<void> setAutoPlayPreviews(bool v) => put({'autoPlayPreviews': v});

  /// Whether [chartId] shows as a table for this profile.
  bool chartAsTable(String chartId) => state.child('chartTables').boolOf(chartId, false);

  Future<void> setChartAsTable(String chartId, bool table) => put({
        'chartTables': {...state.child('chartTables').data, chartId: table},
      });
}

final glassPrefsRecordProvider = NotifierProvider<GlassPrefsRecord, JsonRecord>(GlassPrefsRecord.new, name: 'glassPrefsRecord');
