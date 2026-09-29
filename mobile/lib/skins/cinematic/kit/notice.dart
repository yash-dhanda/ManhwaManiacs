import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/letter_reveal.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The §7.23 notice: a kicker, a typed headline, an optional line and action.
/// [kickerColor] is `proof` for a CORRECTION.
class CineNotice extends StatelessWidget {
  const CineNotice({
    super.key,
    required this.kicker,
    required this.headline,
    this.line,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.kickerColor = CineColors.ink60,
    this.actionKind = CineButtonKind.primary,
  });

  final String kicker;
  final String headline;
  final String? line;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Color kickerColor;
  final CineButtonKind actionKind;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        CineText(kicker, t.typeKicker, color: kickerColor),
        const SizedBox(height: 12),
        TypedText(headline, style: cineStyle(context, t.typeHeadline), scaler: CineType.scaler(context, t.typeHeadline), header: true),
        if (line != null) ...[const SizedBox(height: 12), CineText(line!, t.typeDeck, color: CineColors.ink60)],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            CineButton(actionLabel!, onPressed: onAction, kind: actionKind),
            if (secondaryLabel != null) CineButton(secondaryLabel!, onPressed: onSecondary, kind: CineButtonKind.quiet),
          ],),
        ],
      ],),
    );
  }
}

/// A galley-proof bar (§7.17): `galley` fill flickering 0.55 <-> 1 on a 1400 ms
/// half-period after 120 ms, [phase] apart. Reduced motion: static 0.8.
class GalleyBar extends StatefulWidget {
  const GalleyBar({super.key, required this.height, this.widthFactor = 1, this.phase = Duration.zero});
  final double height;
  final double widthFactor;
  final Duration phase;

  @override
  State<GalleyBar> createState() => _GalleyBarState();
}

class _GalleyBarState extends State<GalleyBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.flicker);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || cineReduced(context)) return;
    _started = true;
    Future<void>.delayed(const Duration(milliseconds: 120) + widget.phase, () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = cineReduced(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: reduced ? 0.8 : 1 - 0.45 * CineCurves.drift.transform(_c.value),
          child: FractionallySizedBox(
            widthFactor: widget.widthFactor,
            alignment: Alignment.centerLeft,
            child: Container(height: widget.height, color: CineColors.galley.withValues(alpha: 0.10)),
          ),
        ),
      ),
    );
  }
}

/// Keeps [SetHeading] reachable from the kit barrel.
typedef KitSetHeading = SetHeading;
