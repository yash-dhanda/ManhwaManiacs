import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Drives [CineCertificate]'s Stamp.
class CineCertificateController extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  /// Fills the square `proof` for 160 ms while the "18" knocks out to `#000`, then settles back to
  /// the outline. The caller fires `gate.confirm` (haptic and `impress` cue) at the fill.
  void stamp() {
    _count++;
    notifyListeners();
  }
}

/// The certificate mark at 160 px (the dialog only; 16 and 20 px are `CineBadge.certificate`): a
/// square with a 2 px `proof` border and "18" in Bodoni Moda Roman weight 900 at 88 px.
class CineCertificate extends StatefulWidget {
  const CineCertificate({super.key, this.controller});
  final CineCertificateController? controller;

  @override
  State<CineCertificate> createState() => _CineCertificateState();
}

class _CineCertificateState extends State<CineCertificate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  int _seen = 0;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_stamp);
  }

  @override
  void didUpdateWidget(CineCertificate old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_stamp);
      widget.controller?.addListener(_stamp);
    }
  }

  void _stamp() {
    final n = widget.controller!.count;
    if (n == _seen) return;
    _seen = n;
    _hold?.cancel();
    final reduced = CineMotion.reduced(context);
    if (reduced) {
      _c.value = 1;
      _hold = Timer(CineDur.beat, () {
        if (mounted) _c.value = 0;
      });
      return;
    }
    // In quickly, hold to 160 ms, then settle back to the outline.
    _c.animateTo(1, duration: CineDur.tick ~/ 2, curve: CineCurves.settle);
    _hold = Timer(CineDur.beat, () {
      if (mounted) _c.animateTo(0, duration: CineDur.line, curve: CineCurves.settle);
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_stamp);
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      label: 'Mature, 18 plus',
      image: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          key: const Key('cine-certificate'),
          width: 160,
          height: 160,
          decoration: BoxDecoration(color: Color.lerp(const Color(0x00000000), c.colorProof, _c.value), border: Border.all(color: c.colorProof, width: 2)),
          alignment: Alignment.center,
          child: CineLit('18', CineFace.bodoni, 88, 88, wght: 900, color: Color.lerp(c.colorProof, const Color(0xFF000000), _c.value)),
        ),
      ),
    );
  }
}
