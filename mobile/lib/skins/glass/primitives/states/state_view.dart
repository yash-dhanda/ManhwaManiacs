import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/view_state.dart';

/// Renders a [GlassViewState] (glass 7.24): the skeleton after 180 ms while loading, the lens for `offline`, `error` and `empty`
/// with the screen's copy, or [child]. The region carries the semantics value "Loading" while loading.
class GlassStateView extends ConsumerStatefulWidget {
  const GlassStateView({
    super.key,
    required this.state,
    required this.child,
    required this.emptyTitle,
    this.emptyDescription,
    this.emptySituation = LensSituation.library,
    this.emptyAction,
    this.errorTitle = "Couldn't load this",
    this.errorDescription,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.skeleton,
    this.mood = Mood.neutral,
    this.placement = GlassLensPlacement.full,
  });

  final GlassViewState state;
  final Widget child;
  final String emptyTitle;
  final String? emptyDescription;
  final LensSituation emptySituation;
  final LensAction? emptyAction;
  final String errorTitle;
  final String? errorDescription;
  final Future<bool> Function()? onRetry;
  final String retryLabel;

  /// The loading skeleton; default is a few rows.
  final Widget Function(BuildContext context)? skeleton;
  final Mood mood;
  final GlassLensPlacement placement;

  @override
  ConsumerState<GlassStateView> createState() => _GlassStateViewState();
}

class _GlassStateViewState extends ConsumerState<GlassStateView> {
  Timer? _delay;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(GlassStateView old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _sync();
  }

  void _sync() {
    _delay?.cancel();
    if (widget.state == GlassViewState.loading) {
      _showSkeleton = false;
      _delay = Timer(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _showSkeleton = true);
      });
    } else {
      _showSkeleton = false;
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.state) {
      case GlassViewState.content:
        return widget.child;
      case GlassViewState.loading:
        return Semantics(
          value: 'Loading',
          container: true,
          child: _showSkeleton
              ? (widget.skeleton?.call(context) ??
                  GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), child: GlassSkeleton(height: 56, radius: 12, index: i, delayed: false))])))
              : const SizedBox.shrink(),
        );
      case GlassViewState.offline:
        return GlassObjectLens(
          situation: LensSituation.offline,
          tone: GlassLensTone.offline,
          title: "You're offline",
          description: 'Check your connection. This loads again by itself when you are back.',
          placement: widget.placement,
          mood: widget.mood,
          onRetry: widget.onRetry,
          primary: widget.onRetry == null ? null : LensAction(widget.retryLabel, () => unawaited(widget.onRetry!())),
        );
      case GlassViewState.error:
        return GlassObjectLens(
          situation: LensSituation.loadError,
          tone: GlassLensTone.error,
          title: widget.errorTitle,
          description: widget.errorDescription,
          placement: widget.placement,
          mood: widget.mood,
          primary: widget.onRetry == null ? null : LensAction(widget.retryLabel, () => unawaited(widget.onRetry!())),
        );
      case GlassViewState.empty:
        return GlassObjectLens(
          situation: widget.emptySituation,
          title: widget.emptyTitle,
          description: widget.emptyDescription,
          placement: widget.placement,
          mood: widget.mood,
          primary: widget.emptyAction,
        );
    }
  }
}
