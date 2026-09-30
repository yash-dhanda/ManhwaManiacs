import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The 1 px `rule.1` rule with a kicker between two of them: `CH 143 · THE RETURN`.
class _RuledKicker extends StatelessWidget {
  const _RuledKicker(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Row(
      children: [
        Expanded(child: SizedBox(height: 1, child: ColoredBox(color: c.colorRule1))),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CineRoleText(label, c.typeKicker, color: c.colorInk45, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
        Expanded(child: SizedBox(height: 1, child: ColoredBox(color: c.colorRule1))),
      ],
    );
  }
}

/// The 96 px seam between two chapters (cinematic 8.14.5): the previous chapter's end on one
/// line, then the entering chapter between two rules.
class SeamBand extends StatelessWidget {
  const SeamBand({super.key, required this.endLine, required this.entering});
  final String endLine, entering;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: '$endLine. $entering',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: c.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CineRoleText(endLine, c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: c.space3),
              _RuledKicker(entering),
            ],
          ),
        ),
      ),
    );
  }
}

/// `↑ CH 141 · keep scrolling up`, or `Loading CH 141…` with a 16 px leader dial.
class TopBand extends StatelessWidget {
  const TopBand({super.key, required this.label, required this.loading});
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Center(
      child: loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CineLeaderDial(size: 16, showAfter: Duration.zero),
                SizedBox(width: c.space2),
                CineRoleText('Loading $label…', c.typeKicker, color: c.colorInk45),
              ],
            )
          : CineRoleText('↑ $label · keep scrolling up', c.typeKicker, color: c.colorInk45),
    );
  }
}

/// `CH 143 IS ON ITS WAY` under the seam: a 16 px leader dial after 400 ms, and "This source can
/// take a while." after 8 s.
class NextLoadingBand extends StatefulWidget {
  const NextLoadingBand({super.key, required this.label});
  final String label;

  @override
  State<NextLoadingBand> createState() => _NextLoadingBandState();
}

class _NextLoadingBandState extends State<NextLoadingBand> {
  Timer? _slow;
  bool _long = false;

  @override
  void initState() {
    super.initState();
    _slow = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _long = true);
    });
  }

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return SizedBox(
      height: 96,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CineRoleText('${widget.label} IS ON ITS WAY', c.typeKicker, color: c.colorInk45),
            SizedBox(height: c.space2),
            const CineLeaderDial(size: 16),
            if (_long) ...[
              SizedBox(height: c.space2),
              CineRoleText('This source can take a while.', c.typeCaption, color: c.colorInk60),
            ],
          ],
        ),
      ),
    );
  }
}

/// A band the strip draws for [kind], the builder the engine's `bandBuilder` slot takes. The copy
/// of `nextFailed`, `offlineEnd` and `rateLimited` lives with the end states.
Widget cineBand(
  BuildContext context,
  BandKind kind, {
  required String endLine,
  required String entering,
  required String previousLabel,
  required String nextLabel,
  required Widget Function(BuildContext) nextFailed,
  required Widget Function(BuildContext) offlineEnd,
  required bool loadingPrevious,
  Duration? retryIn,
}) =>
    switch (kind) {
      BandKind.seam => SeamBand(endLine: endLine, entering: entering),
      BandKind.top || BandKind.topLoading => TopBand(label: previousLabel, loading: kind == BandKind.topLoading || loadingPrevious),
      BandKind.nextLoading => NextLoadingBand(label: nextLabel),
      BandKind.nextFailed => nextFailed(context),
      BandKind.offlineEnd => offlineEnd(context),
      BandKind.rateLimited => RateLimitedBand(retryIn: retryIn ?? const Duration(seconds: 10)),
    };

/// `SLOW DOWN — the source asked us to wait. Retrying in 12 s.` with a live countdown.
class RateLimitedBand extends StatefulWidget {
  const RateLimitedBand({super.key, required this.retryIn});
  final Duration retryIn;

  @override
  State<RateLimitedBand> createState() => _RateLimitedBandState();
}

class _RateLimitedBandState extends State<RateLimitedBand> {
  late int _left = widget.retryIn.inSeconds.clamp(0, 3600);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _left > 0) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      liveRegion: false,
      label: 'Slow down. The source asked us to wait. Retrying in $_left seconds.',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space3),
          color: const Color(0xFF000000),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              CineRoleText('SLOW DOWN — the source asked us to wait.', c.typeKicker, color: c.colorProof),
              CineRoleText('Retrying in $_left s.', c.typeFolio, color: c.colorInk100),
            ],
          ),
        ),
      ),
    );
  }
}
