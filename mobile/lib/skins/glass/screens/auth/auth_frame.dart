import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass_scroll_behavior.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The bare frame of Setup, Login and Register (glass 8.0.1, 8.2): no navigation, the brand aurora, one scroll view whose keyboard
/// closes on a downward drag, a 420 px column. On tablet and desktop frames (`slab`) the column sits in a content-layer slab: a
/// blurred 440 px panel that is not glass and not registered (glass 8.3).
class GlassAuthFrame extends ConsumerWidget {
  const GlassAuthFrame({super.key, required this.child, this.slab = false, this.controller, this.condense});

  final Widget child;

  /// Wrap the column in the slab on frames whose shorter side is 600 or more.
  final bool slab;
  final ScrollController? controller;

  /// 0 to 1: the Slab condense shrinks the slab toward its lens (its contents fade in the screen itself).
  final Animation<double>? condense;

  static const Color slabFill = Color(0x9E131317);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final margin = GlassFrame.screenMargin(context);
    final wide = mq.size.shortestSide >= 600;
    final useSlab = slab && wide;
    final solid = ref.watch(glassA11yProvider.select((a) => a.solid));
    Widget column = ConstrainedBox(constraints: BoxConstraints(maxWidth: useSlab ? 440 : 420), child: child);
    if (useSlab) {
      final radius = BorderRadius.circular(32);
      column = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ClipRSuperellipse(
          borderRadius: radius,
          child: solid
              ? ColoredBox(color: gt.glassSolid1, child: Padding(padding: const EdgeInsets.all(32), child: child))
              : BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: ColoredBox(color: slabFill, child: Padding(padding: const EdgeInsets.all(32), child: child)),
                ),
        ),
      );
    }
    if (useSlab && condense != null) {
      final inner = column;
      column = AnimatedBuilder(
        animation: condense!,
        builder: (context, child) {
          final t = condense!.value.clamp(0.0, 1.0);
          return Opacity(opacity: t > 0.9 ? (1 - (t - 0.9) / 0.1).clamp(0.0, 1.0) : 1, child: Transform.scale(scale: 1 + (24 / 440 - 1) * t, alignment: Alignment.topCenter, child: child));
        },
        child: inner,
      );
    }
    final bottom = math.max(mq.padding.bottom, mq.viewInsets.bottom) + 24;
    return GlassAmbientScope(
      spec: const GlassAmbientSpec.aurora(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0x00000000),
        body: SingleChildScrollView(
          controller: controller,
          physics: glassScrollPhysics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(margin, mq.padding.top + 48, margin, bottom),
          child: Align(alignment: Alignment.topCenter, child: column),
        ),
      ),
    );
  }
}
