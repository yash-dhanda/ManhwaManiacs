import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Whether another member's reaction on a chapter is hidden for the viewer (cinematic 9.3.3): the
/// server's `sealed`, lifted when this phone's progress store or this session says the chapter is
/// finished, never for the viewer's own reaction. Watches only that one chapter's flags.
bool circleGuarded(WidgetRef ref, {required String sourceId, required String seriesKey, required String? chapterKey, required bool? sealed, bool isOwn = false}) {
  final id = chapterKey == null ? null : chapterId(sourceId, seriesKey, chapterKey);
  final session = id != null && ref.watch(completedThisSessionProvider.select((s) => s.contains(id)));
  final local = id != null && ref.watch(sourceProgressProvider.select((m) => m[id]?.completed ?? false));
  return isGuarded(isOwn: isOwn, sealed: sealed, completedLocally: local, completedThisSession: session);
}

/// Unseal (cinematic 4.5, 13 moment 7): when [guarded] turns false the child fades in over 160 ms
/// `settle`, [index] x 40 ms after its neighbours. Reduced motion shows the end state at once. A
/// child that was never guarded is simply shown.
class UnsealFade extends StatefulWidget {
  const UnsealFade({super.key, required this.guarded, required this.child, this.index = 0, this.fadeWhileGuarded = false});
  final bool guarded;
  final Widget child;
  final int index;

  /// Hides the child while guarded (rows whose content only exists once unsealed).
  final bool fadeWhileGuarded;

  @override
  State<UnsealFade> createState() => _UnsealFadeState();
}

class _UnsealFadeState extends State<UnsealFade> {
  double _opacity = 1;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _opacity = widget.fadeWhileGuarded && widget.guarded ? 0 : 1;
  }

  @override
  void didUpdateWidget(UnsealFade old) {
    super.didUpdateWidget(old);
    if (old.guarded && !widget.guarded) {
      if (CineMotion.reduced(context)) {
        setState(() => _opacity = 1);
        return;
      }
      setState(() => _opacity = 0);
      _t?.cancel();
      _t = Timer(Duration(milliseconds: 40 * widget.index), () {
        if (mounted) setState(() => _opacity = 1);
      });
    } else if (!old.guarded && widget.guarded && widget.fadeWhileGuarded) {
      setState(() => _opacity = 0);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _opacity,
        duration: _opacity == 0 || CineMotion.reduced(context) ? Duration.zero : CineDur.beat,
        curve: CineCurves.settle,
        child: widget.child,
      );
}
