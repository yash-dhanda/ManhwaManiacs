import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';

/// `mm.glass.prefs.u{user}p{profile}` (glass 15.5): the Glass profile record. Listen reads and writes `autoPlayPreviews` only; unknown
/// fields survive every write.
class GlassPrefsRecordNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => 'mm.glass.prefs.';
}

final glassPrefsRecordProvider = NotifierProvider<GlassPrefsRecordNotifier, JsonRecord>(GlassPrefsRecordNotifier.new, name: 'glassPrefsRecord');

/// The voice orbit's "Auto-play previews" switch, default on.
final glassAutoPlayPreviewsProvider = Provider<bool>((ref) => ref.watch(glassPrefsRecordProvider).boolOf('autoPlayPreviews', true), name: 'glassAutoPlayPreviews');
