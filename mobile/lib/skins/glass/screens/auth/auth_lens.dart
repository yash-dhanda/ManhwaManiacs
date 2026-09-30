import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';

enum GlassAuthLensState { mark, spinning, unreachable }

/// The lens of Setup, Login and Register (glass 8.1 to 8.4): a glass circle holding the neutral MM column. A fixed-size lens keeps T2
/// whatever its size (glass 2.4.3). `spinning` draws the liquid ring 8 px outside; `unreachable` swaps the mark for `cloud-slash`.
class GlassAuthLens extends ConsumerStatefulWidget {
  const GlassAuthLens({super.key, this.size = 56, this.state = GlassAuthLensState.mark});

  /// 56 on Login and Register, 72 on Setup.
  final double size;
  final GlassAuthLensState state;

  @override
  ConsumerState<GlassAuthLens> createState() => GlassAuthLensHandle();
}

class GlassAuthLensHandle extends ConsumerState<GlassAuthLens> {
  final GlobalKey<SkinGlassState> _glass = GlobalKey<SkinGlassState>();

  /// One specular sweep across the rim (the Address drain's arrival).
  void flashRim() {
    final s = _glass.currentState;
    if (s != null) GlassSweep.request(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final ring = s + 16;
    final Widget face = switch (widget.state) {
      GlassAuthLensState.unreachable => GlyphIcon(GlassGlyph28.cloudSlash, size: 24, color: gt.colorDanger, weight: GlassIconWeight.light),
      _ => GlassMark(height: s >= 72 ? 30 : 24),
    };
    return Semantics(
      label: switch (widget.state) {
        GlassAuthLensState.spinning => 'Working',
        GlassAuthLensState.unreachable => 'Server unreachable',
        _ => 'ManhwaManiacs',
      },
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: ring,
          height: ring,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.state == GlassAuthLensState.spinning) GlassSpinner(size: ring, color: gt.colorIris400),
              SkinGlass(
                key: _glass,
                tier: GlassTierId.t2,
                shape: const GlassShape.circle(),
                size: Size.square(s),
                debugLabel: 'auth-lens',
                child: Center(child: face),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
