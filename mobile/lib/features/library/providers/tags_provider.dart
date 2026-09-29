import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';

export 'package:manhwamaniacs/features/library/providers/tags_controller.dart' show TagsController, tagsControllerProvider;

/// The profile's tags (`GET /library/tags`, with `series_count` when the server sends it).
/// The same provider the series page reads, so a change in one shows in the other.
final tagsProvider = profileTagsProvider;
