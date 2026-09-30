import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Distance the credits travel (36 px/s over 10 s, `durRollColophon`).
const double kRollDistance = 360;

/// A Bodoni Moda Italic copy of a role (the closing line's face).
CineTextRole italicOf(CineTextRole r) => CineTextRole(family: 'BodoniModa', italic: true, wght: r.wght, axes: r.axes, sizes: r.sizes, lines: r.lines, trackingEm: r.trackingEm, cap: r.cap);

/// Page 10: the end credits (moment 23). On `#000000` with the top series'
/// duotone as a faint band behind; credit lines centred, each a `type.credit`
/// label over a Bodoni Moda Italic value; the block rolls up 360 px over 10 s
/// under a fade mask, then "See you in 2027." held 2 s. A tap skips to the press
/// run; holding pauses the roll. Reduced motion: a still page.
class AnnualColophonPage extends ConsumerStatefulWidget {
  const AnnualColophonPage({super.key, required this.env, required this.index});
  final AnnualEnv env;

  /// This page's index in the story.
  final int index;

  @override
  ConsumerState<AnnualColophonPage> createState() => _AnnualColophonPageState();
}

class _AnnualColophonPageState extends ConsumerState<AnnualColophonPage> with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(vsync: this, duration: CineDur.rollColophon);

  @override
  void initState() {
    super.initState();
    widget.env.player.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    final p = widget.env.player;
    final go = p.index == widget.index && p.running && !CineMotion.reduced(context);
    if (go && !_roll.isCompleted) {
      _roll.forward();
    } else {
      _roll.stop();
    }
  }

  @override
  void dispose() {
    widget.env.player.removeListener(_sync);
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final a = widget.env.annual;
    final reduced = CineMotion.reduced(context);
    final top = a.topSeries.isEmpty ? null : a.topSeries.first;
    final lines = colophonLines(a);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.30);
    const valueStyle = TextStyle(fontFamily: 'BodoniModa', fontStyle: FontStyle.italic, fontSize: 24, height: 1.2, fontWeight: FontWeight.w500, color: CineColors.ink100, fontVariations: [FontVariation('wght', 500), FontVariation('opsz', 28)]);

    final Widget credits = Column(mainAxisSize: MainAxisSize.min, children: [
      for (final (label, value) in lines) ...[
        CineRoleText(label, t.typeCreditLabel, color: CineColors.ink60, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value, style: valueStyle, textAlign: TextAlign.center, textScaler: scaler),
        const SizedBox(height: 28),
      ],
    ],);
    final closing = Center(child: AnnualTitle(closingLine(a.year), italicOf(t.typeHeadline), id: 'closing'));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.env.goTo(widget.env.player.pages.length - 1),
      child: ColoredBox(
        color: CineColors.paper0,
        child: LayoutBuilder(builder: (context, box) {
          final h = box.maxHeight;
          return Stack(fit: StackFit.expand, children: [
            if (top?.coverUrl != null)
              Positioned(
                left: 0,
                right: 0,
                top: h * 0.3,
                height: h * 0.4,
                child: AnnualArt(url: top!.coverUrl!, duo: parseAmbientHex(top.ambient?.duo), opacity: 0.3),
              ),
            if (reduced)
              Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [credits, closing])))
            else
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)], stops: [0, 0.15, 0.85, 1]).createShader(r),
                child: AnimatedBuilder(
                  animation: _roll,
                  builder: (context, _) => Stack(children: [
                    Positioned(
                      key: const ValueKey('credits-roll'),
                      left: 20,
                      right: 20,
                      top: h * 0.75 - kRollDistance * _roll.value,
                      child: credits,
                    ),
                    if (_roll.isCompleted) Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: closing)),
                  ],),
                ),
              ),
          ],);
        },),
      ),
    );
  }
}
