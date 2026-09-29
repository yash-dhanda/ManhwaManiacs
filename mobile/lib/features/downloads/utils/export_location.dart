import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';

/// Human directions to what an export just wrote.
///
/// On iOS this is a *route through the Files app*, not a filesystem path,
/// because that is the only form of the answer the owner can act on:
/// `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`
/// (`ios/Runner/Info.plist`) put the app's Documents directory under
/// *On My iPhone → ManhwaManiacs*, and everything below it shows up there
/// exactly as named. Elsewhere the real path is the honest answer, since no
/// system file browser reaches app-private storage.
String exportLocationDescription(
  ChapterExportResult result,
  TargetPlatform platform,
) {
  if (platform == TargetPlatform.iOS) {
    return 'Files → On My iPhone → ManhwaManiacs → '
        '${ChapterExporter.exportsFolderName} → ${result.seriesFolderName}';
  }
  return result.directory.path;
}
