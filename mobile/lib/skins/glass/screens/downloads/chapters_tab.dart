import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/ocr_banner.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/series_downloads_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/storage_meter_capsule.dart';

/// "Downloaded chapters live inside ManhwaManiacs. For a copy ... use Save to Files." (iOS and Android wordings).
String whereItLives(TargetPlatform p) => p == TargetPlatform.iOS
    ? 'Downloaded chapters live inside ManhwaManiacs. For a copy you can open elsewhere, use Save to Files.'
    : 'Downloaded chapters live inside ManhwaManiacs. For a copy other apps can open, use Save to Files.';

/// The Chapters tab (glass 8.22): the storage meter, the OCR banner, the "Where it lives" note and one card per series, biggest first.
class GlassChaptersTab extends ConsumerWidget {
  const GlassChaptersTab({super.key, required this.groups, this.onFocus, this.platform});
  final List<DownloadedSeriesGroup> groups;
  final void Function(DownloadedSeriesGroup)? onFocus;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const GlassDownloadsMeter(),
        const SizedBox(height: 12),
        const GlassOcrBanner(),
        Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassLabel(whereItLives(platform ?? defaultTargetPlatform), role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 4)),
        for (final g in groups) GlassSeriesDownloadsCard(key: ValueKey('${g.sourceId}|${g.seriesKey}'), group: g, onFocus: () => onFocus?.call(g)),
      ],);
}
