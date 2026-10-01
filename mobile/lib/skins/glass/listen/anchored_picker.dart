/// An anchored picker (glass 8.0.3): a card that blooms out of its trigger on `springMorph`, with a barrier that closes it (tap outside,
/// `Esc`, back). No `?sheet=`. Used by the speed dial and the sleep menu, above the player sheet.
library;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

typedef PickerBuilder = Widget Function(BuildContext context, VoidCallback close);

/// Where a picker of [size] goes for [anchor] in [screen]: centred over the anchor, above it when it fits (8 px gap), else below,
/// kept [margin] inside the screen.
Offset pickerPosition({required Rect anchor, required Size size, required Size screen, double margin = 8, double gap = 8}) {
  var x = anchor.center.dx - size.width / 2;
  x = x.clamp(margin, (screen.width - size.width - margin).clamp(margin, double.infinity));
  var y = anchor.top - gap - size.height;
  if (y < margin) y = anchor.bottom + gap;
  y = y.clamp(margin, (screen.height - size.height - margin).clamp(margin, double.infinity));
  return Offset(x, y);
}

class _PickerLayout extends SingleChildLayoutDelegate {
  _PickerLayout(this.anchor);
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints(maxWidth: c.maxWidth - 16, maxHeight: c.maxHeight - 16);

  @override
  Offset getPositionForChild(Size size, Size childSize) => pickerPosition(anchor: anchor, size: childSize, screen: size);

  @override
  bool shouldRelayout(_PickerLayout o) => o.anchor != anchor;
}

Future<void> showListenPicker(BuildContext context, {required Rect anchor, required PickerBuilder builder, String label = 'Picker'}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x00000000),
      barrierLabel: 'Dismiss',
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, __) => _PickerHost(anchor: anchor, builder: builder, label: label),
    ),
  );
}

class _PickerHost extends ConsumerStatefulWidget {
  const _PickerHost({required this.anchor, required this.builder, required this.label});
  final Rect anchor;
  final PickerBuilder builder;
  final String label;

  @override
  ConsumerState<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends ConsumerState<_PickerHost> with SingleTickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController.unbounded(vsync: this);

  @override
  void initState() {
    super.initState();
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _bloom.value = 1;
    } else {
      _bloom.animateWith(SpringSimulation(springOf(glassTokens.springMorph), 0, 1, 0));
    }
  }

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: FocusScope(
        autofocus: true,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: widget.label,
          child: CustomSingleChildLayout(
            delegate: _PickerLayout(widget.anchor),
            child: AnimatedBuilder(
              animation: _bloom,
              child: widget.builder(context, _close),
              builder: (context, child) {
                final t = _bloom.value;
                final opacity = reduced ? 1.0 : t.clamp(0.0, 1.0);
                return Opacity(opacity: opacity, child: reduced ? child : Transform.scale(scale: 0.5 + 0.5 * t.clamp(0.0, 1.1), alignment: Alignment.bottomCenter, child: child));
              },
            ),
          ),
        ),
      ),
    );
  }
}
