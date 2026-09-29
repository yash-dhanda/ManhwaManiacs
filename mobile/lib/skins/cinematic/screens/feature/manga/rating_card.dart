import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The rating card (§7.24): certificate + `18+` and descriptors from the
/// genres, in on `settle` 480 ms, held `durHoldRating` (3000 ms), out 240 ms
/// `lift`. Informational only: it never takes a tap.
class RatingCard extends StatefulWidget {
  const RatingCard({super.key, required this.descriptors});
  final List<String> descriptors;

  static const known = {
    'action': 'Violence',
    'horror': 'Violence',
    'gore': 'Violence',
    'ecchi': 'Sexual content',
    'smut': 'Sexual content',
    'mature': 'Mature themes',
    'adult': 'Mature themes',
  };

  /// "Violence · Sexual content" from genres; empty when none map.
  static List<String> descriptorsFor(Iterable<String> genres) {
    final out = <String>[];
    for (final g in genres) {
      final d = known[g.toLowerCase()];
      if (d != null && !out.contains(d)) out.add(d);
    }
    return out;
  }

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _hold;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _c.duration = const Duration(milliseconds: 480);
    unawaited(_c.forward().then((_) {
      _hold = Timer(CineDur.holdRating, () async {
        if (!mounted) return;
        _c.duration = const Duration(milliseconds: 240);
        await _c.reverse();
        if (mounted) setState(() => _gone = true);
      });
    }),);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final t = cineOf(context);
    final curve = CurvedAnimation(parent: _c, curve: CineCurves.settle, reverseCurve: CineCurves.lift);
    return IgnorePointer(
      child: FadeTransition(
        opacity: curve,
        child: Semantics(
          key: const Key('rating-card'),
          label: 'Rated 18 plus${widget.descriptors.isEmpty ? '' : ', ${widget.descriptors.join(', ')}'}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: t.colorPaper0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CineGlyphs.certificate18Regular, size: 20, color: t.colorInk100),
                const SizedBox(width: 8),
                Text('18+', style: kickerStyle(context, color: t.colorInk100)),
                if (widget.descriptors.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(widget.descriptors.join(' · '),
                      style: TextStyle(fontSize: 12, color: t.colorInk60),),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
