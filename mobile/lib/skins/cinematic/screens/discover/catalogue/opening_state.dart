import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/sources/utils/source_wash.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const kCatalogueTips = [
  'Press / to search this source.',
  'Pick a browse mode to change the order.',
  'Tap a genre on any series to browse it here.',
  'Your progress syncs across devices.',
];

/// First-load state of a catalogue: after 400 ms a leader dial; after 3 s the
/// deck changes, a tip types itself (rotating every 3.5 s) and the source wash
/// fades in over 800 ms (no dissolve under reduced motion).
class OpeningState extends StatefulWidget {
  const OpeningState({super.key, required this.sourceId, required this.deck});

  final String sourceId;
  final String deck;

  @override
  State<OpeningState> createState() => _OpeningStateState();
}

class _OpeningStateState extends State<OpeningState> {
  bool _dial = false;
  bool _slow = false;
  int _tip = 0;
  Timer? _dialTimer;
  Timer? _slowTimer;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _dialTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _dial = true);
    });
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _slow = true);
      _tipTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (mounted) setState(() => _tip = (_tip + 1) % kCatalogueTips.length);
      });
    });
  }

  @override
  void dispose() {
    _dialTimer?.cancel();
    _slowTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _slow ? 1 : 0,
              duration: cineReduced(context) ? Duration.zero : CineDur.dissolve,
              curve: CineCurves.turn,
              child: FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: 0.3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [sourceWash(widget.sourceId), const Color(0xFF000000)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CineSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _slow ? 'This source can take about 10 s.' : widget.deck,
                        style: cineText(context, t.typeDeck, color: t.colorInk60),
                      ),
                    ),
                  ),
                  if (_dial) const LeaderDial(size: 32),
                ],
              ),
              if (_slow) ...[
                const SizedBox(height: CineSpace.s3),
                TypedText(
                  kCatalogueTips[_tip],
                  key: ValueKey(_tip),
                  style: cineText(context, t.typeCaption, color: t.colorInk60),
                ),
              ],
              const SizedBox(height: CineSpace.s4),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isTablet(context) ? 5 : 3,
                mainAxisSpacing: CineSpace.s3,
                crossAxisSpacing: CineSpace.s3,
                childAspectRatio: 2 / 3.6,
                children: [for (var i = 0; i < 9; i++) const FlickerPlate()],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
