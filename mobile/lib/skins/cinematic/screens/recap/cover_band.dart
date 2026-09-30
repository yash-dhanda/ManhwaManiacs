import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The series cover as a duotone band across the top of the takeover: 34 % of the viewport
/// height on phones, 28 % from 600 dp, `scrim.vignette` over it, `scrim.foot.black` over its bottom
/// 60 % (reaching `#000000` at its bottom edge) and grain at 0.05.
class RecapCoverBand extends StatelessWidget {
  const RecapCoverBand({super.key, required this.url, this.duo, this.title});
  final String? url, title;
  final Color? duo;

  static double heightFor(Size size) => size.height * (size.width >= 600 ? 0.28 : 0.34);

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final h = heightFor(MediaQuery.sizeOf(context));
    return SizedBox(
      height: h,
      child: ExcludeSemantics(
        child: CineGrain(
          opacity: 0.05,
          child: Stack(fit: StackFit.expand, children: [
            CineDuotone(duo: duo ?? c.colorAmbientFallbackDuo, child: CineImage(url: url, title: title)),
            DecoratedBox(decoration: BoxDecoration(gradient: c.scrimVignette)),
            Positioned(left: 0, right: 0, bottom: 0, height: h * 0.6, child: DecoratedBox(decoration: BoxDecoration(gradient: c.scrimFootBlack))),
          ],),
        ),
      ),
    );
  }
}
