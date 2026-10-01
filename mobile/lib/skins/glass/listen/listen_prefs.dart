import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';

// One owner of `mm.glass.prefs.u{user}p{profile}` (glass 15.5): a second notifier over the same key merged into its own stale
// state and wiped the other's fields on every write.
export 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart' show glassPrefsRecordProvider;

/// The voice orbit's "Auto-play previews" switch, default on.
final glassAutoPlayPreviewsProvider = Provider<bool>((ref) => ref.watch(glassPrefsRecordProvider).boolOf('autoPlayPreviews', true), name: 'glassAutoPlayPreviews');
