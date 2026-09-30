import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The sheet's own mood field (glass 8.6): the same three radial gradients as the ambient field, confined to the top 40 % of the
/// sheet, in the chosen mood's colour at its own opacity, cross-fading over `curveTintShift` when the mood changes.
class ProfileFormField extends ConsumerStatefulWidget {
  const ProfileFormField({super.key, required this.mood, required this.child});
  final Mood mood;
  final Widget child;

  @override
  ConsumerState<ProfileFormField> createState() => _ProfileFormFieldState();
}

class _ProfileFormFieldState extends ConsumerState<ProfileFormField> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: gt.curveTintShift.duration, value: 1);
  late GlassBlobs _from = GlassBlobs.of(GlassAmbientSpec.mood(widget.mood));
  late GlassBlobs _to = _from;

  @override
  void didUpdateWidget(ProfileFormField old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _from = _blend();
      _to = GlassBlobs.of(GlassAmbientSpec.mood(widget.mood));
      final reduced = ref.read(glassReducedProvider);
      _c.duration = reduced ? gt.curveReducedCrossfade.duration : gt.curveTintShift.duration;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  GlassBlobs _blend() {
    final t = gt.curveTintShift.curve.transform(_c.value.clamp(0.0, 1.0));
    return GlassBlobs(
      [for (var i = 0; i < 3; i++) Color.lerp(_from.colors[i], _to.colors[i], t)!],
      [for (var i = 0; i < 3; i++) _from.scales[i] + (_to.scales[i] - _from.scales[i]) * t],
      _from.alpha + (_to.alpha - _from.alpha) * t,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: (c.hasBoundedHeight ? c.maxHeight : 800) * 0.4,
            child: IgnorePointer(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: GlassFieldPainter(blobs: _blend(), anchors: const [Offset.zero, Offset.zero, Offset.zero], blur: wide ? gt.blurFieldDesktop : gt.blurFieldPhone),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
