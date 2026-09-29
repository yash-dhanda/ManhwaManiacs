import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The pieces of a shortcut as keycaps read them (glass 7.27): `⌘ ⌥ ⇧ ⌃` on iOS, the words `Ctrl`, `Alt`,
/// `Shift` on Android. `meta` is the platform's "mod": `⌘` on iOS and `Ctrl` on Android.
List<String> keycapLabel(SingleActivator a, {TargetPlatform platform = TargetPlatform.iOS}) {
  final ios = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  final out = <String>[];
  if (a.control) out.add(ios ? '⌃' : 'Ctrl');
  if (a.alt) out.add(ios ? '⌥' : 'Alt');
  if (a.shift) out.add(ios ? '⇧' : 'Shift');
  if (a.meta) out.add(ios ? '⌘' : 'Ctrl');
  final k = a.trigger;
  final label = k.keyLabel.isNotEmpty ? k.keyLabel : k.debugName ?? '?';
  out.add(label.length == 1 ? label.toUpperCase() : label);
  return out;
}

/// One key: `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, a 0.5 px rim.
class GlassKeycap extends StatelessWidget {
  const GlassKeycap(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: gt.colorSurface3,
            borderRadius: BorderRadius.circular(gt.radiusXs),
            border: Border.all(color: const Color(0x38FFFFFF), width: 0.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GlassText(label, role: gt.typeMono, size: 12, height: 16, wght: 600, color: gt.colorLabel1, maxScale: 1.5),
              ),
            ),
          ),
        ),
      );
}

/// A combo: keycaps 4 px apart.
class GlassKeycaps extends StatelessWidget {
  const GlassKeycaps(this.parts, {super.key});
  final List<String> parts;

  /// A shortcut on the current platform.
  GlassKeycaps.shortcut(BuildContext context, SingleActivator a, {Key? key})
      : this(keycapLabel(a, platform: Theme.of(context).platform), key: key);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            GlassKeycap(parts[i]),
          ],
        ],
      );
}
