import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Content-layer controls for the Glass development pages: never glass, at least `hitMin` tall and wide,
/// reachable and operable with a hardware keyboard (Tab, Enter, Space) and ringed by the two-tone focus ring.
class DevButton extends StatelessWidget {
  const DevButton({super.key, required this.label, required this.onTap, this.selected = false, this.mono = false});

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    const t = glassTokens;
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GlassFocusRing(
        shape: const GlassShape.capsule(),
        child: FocusableActionDetector(
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onTap())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: hit, minWidth: hit),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? t.colorFill2 : t.colorFill1,
                  borderRadius: BorderRadius.circular(hit / 2),
                ),
                child: GlassText(label, role: mono ? t.typeMono : t.typeCallout, color: selected ? t.colorLabel1 : t.colorLabel2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled on/off row, at least `hitMin` tall, operable with Enter and Space.
class DevToggle extends StatelessWidget {
  const DevToggle({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const t = glassTokens;
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      toggled: value,
      label: label,
      excludeSemantics: true,
      child: GlassFocusRing(
        shape: GlassShape.superellipse(t.radiusMd),
        child: FocusableActionDetector(
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onChanged(!value))},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: hit),
              child: Row(
                children: [
                  Expanded(child: GlassText(label, role: t.typeCallout)),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: hit < 48 ? 30 : 32,
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: value ? t.colorIris600 : t.colorFill2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: t.colorLabel1, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of mutually exclusive [DevButton]s.
class DevSegmented<T> extends StatelessWidget {
  const DevSegmented({super.key, required this.values, required this.labelOf, required this.selected, required this.onSelected});

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values) DevButton(label: labelOf(v), selected: v == selected, onTap: () => onSelected(v)),
        ],
      );
}

/// A section heading in the content layer.
class DevHeading extends StatelessWidget {
  const DevHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: GlassText(text.toUpperCase(), role: glassTokens.typeCaption1, color: glassTokens.colorLabel2),
      );
}

/// A `mono` 12/16 caption.
class DevCaption extends StatelessWidget {
  const DevCaption(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: GlassText(text, role: glassTokens.typeMono, size: 12, height: 16, color: color ?? glassTokens.colorLabel2),
      );
}

