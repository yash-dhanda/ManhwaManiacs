import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';

/// The opening lens (glass 8.11, while the first page loads): the source's logo in a 96 px lens, the first three continue-reading
/// covers orbiting it (radius 80, one turn per 9 s, from 0, 120 and 240 degrees), and after 3 s "This source can take about 10 s".
/// Reduced motion: the covers stand at 0, 120 and 240 degrees.
class OpeningLens extends ConsumerStatefulWidget {
  const OpeningLens({super.key, required this.sourceId, required this.name, this.iconUrl});
  final String sourceId;
  final String name;
  final String? iconUrl;

  @override
  ConsumerState<OpeningLens> createState() => _OpeningLensState();
}

class _OpeningLensState extends ConsumerState<OpeningLens> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  Timer? _slow;
  bool _slowShown = false;

  @override
  void initState() {
    super.initState();
    _slow = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _slowShown = true);
    });
  }

  @override
  void dispose() {
    _slow?.cancel();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    if (!reduced && !_orbit.isAnimating) _orbit.repeat();
    if (reduced && _orbit.isAnimating) _orbit.stop();
    final covers = (ref.watch(continueReadingProvider).valueOrNull ?? const []).take(3).toList();
    return Semantics(
      container: true,
      label: 'Opening ${widget.name}',
      child: SizedBox(
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _orbit,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < covers.length; i++)
                      Transform.translate(
                        offset: Offset.fromDirection(2 * math.pi * (_orbit.value + i / 3), 80),
                        child: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 34, height: 50, child: HomeCoverImage(url: covers[i].coverUrl, width: 34))),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorFill2, border: Border.all(color: gt.colorSeparator)),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: ClipOval(child: widget.iconUrl == null || widget.iconUrl!.isEmpty ? GlassSourceMonogram(name: widget.name, sourceId: widget.sourceId, size: 96) : HomeCoverImage(url: widget.iconUrl, width: 96)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24, child: _slowShown ? GlassLabel('This source can take about 10 s', role: gt.typeFootnote, color: gt.colorLabel2) : null),
          ],
        ),
      ),
    );
  }
}
