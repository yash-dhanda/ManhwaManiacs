import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';

/// Whether [sourceId] serves prose (the Book page) rather than pages (the
/// Feature page). A property of the SOURCE, not of the reader's current mode.
/// `null` while unknown (never today: the scope answers synchronously).
bool? isNovelSource(ContentModeScope scope, String sourceId) =>
    scope.modeOf(sourceId) == ContentMode.novel;
