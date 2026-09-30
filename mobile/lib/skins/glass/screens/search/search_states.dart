import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';

/// Seconds to wait after a 429: the interceptor's `retryAfter`, else `retry_after` from `details`, else 12.
int retryAfterOf(Object error) {
  if (error is ApiError) {
    final d = error.details;
    final after = d is Map ? d['retry_after'] : null;
    return error.retryAfter?.inSeconds ?? (after is num ? after.toInt() : 12);
  }
  return 12;
}

bool isRateLimited(Object error) => error is ApiError && error.code == 'rate_limited';
bool isNetworkDown(Object error) => error is NetworkError || error is TimeoutError;

/// "Sources are busy. Retrying in 12 s" counting down, then [onRetry] fires on its own.
class SearchRateLimited extends StatefulWidget {
  const SearchRateLimited({super.key, required this.seconds, required this.onRetry});
  final int seconds;
  final VoidCallback onRetry;

  @override
  State<SearchRateLimited> createState() => _SearchRateLimitedState();
}

class _SearchRateLimitedState extends State<SearchRateLimited> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(seconds: widget.seconds), widget.onRetry);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Align(alignment: Alignment.centerLeft, child: GlassStatusCapsule(kind: GlassStatusKind.rateLimit, retryInSeconds: widget.seconds)),
      );
}

/// Three section skeletons (after 180 ms), each a header bar and four posters.
class SearchLoadingSkeleton extends StatelessWidget {
  const SearchLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var g = 0; g < 3; g++) ...[
              const SizedBox(height: 16),
              const GlassSkeleton(width: 160, height: 22, radius: 8),
              const SizedBox(height: 10),
              SizedBox(height: 168, child: Row(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(right: 12), child: GlassSkeleton(width: 112, height: 168, index: i))])),
            ],
          ],
        ),
      );
}

class SearchEmptyLens extends StatelessWidget {
  const SearchEmptyLens({super.key, required this.q, this.onDialogue});
  final String q;
  final VoidCallback? onDialogue;

  @override
  Widget build(BuildContext context) => GlassObjectLens(
        situation: LensSituation.nothingFound,
        title: 'No results for “$q”',
        description: 'Try another spelling, or search the dialogue instead.',
        placement: GlassLensPlacement.inline,
        primary: onDialogue == null ? null : LensAction('Search dialogue', onDialogue!),
      );
}

class SearchErrorLens extends StatelessWidget {
  const SearchErrorLens({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GlassObjectLens(
        situation: LensSituation.loadError,
        tone: GlassLensTone.error,
        title: 'Search failed',
        placement: GlassLensPlacement.inline,
        primary: LensAction('Try again', onRetry),
      );
}

/// A one-line muted helper ("Offline: searching this device only").
class SearchHelper extends StatelessWidget {
  const SearchHelper(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Semantics(liveRegion: true, child: GlassLabel(text, role: gt.typeFootnote, color: warning ? gt.colorWarning : gt.colorLabel2, maxLines: 2)),
      );
}
