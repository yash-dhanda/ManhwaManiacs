import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `1.25×`: the chip's speed folio, two decimals.
String speedFolio(double speedX) => '${speedX.toStringAsFixed(2)}×';

/// The chip's text: `1.25×`, `1.25× · PACED`, `PAUSED FOR LISTEN`, or [autoLabel] (guided view's
/// `AUTO · PACED` / `AUTO · 3.5 S`).
String autoScrollChipText({required double speedX, required bool paced, bool pausedForListen = false, String? autoLabel}) {
  if (pausedForListen) return 'PAUSED FOR LISTEN';
  if (autoLabel != null) return autoLabel;
  return paced ? '${speedFolio(speedX)} · PACED' : speedFolio(speedX);
}

/// The auto-scroll chip (cinematic 9.4.1): a floating square-cornered chip, 40 px tall with a
/// 44 / 48 hit area, `paper.2` at 90 % with a 1 px `rule.2`, inside `CineStock.raised`. A tap
/// toggles running and paused, a 450 ms long-press opens the speed ruler. A 2 px `spot` rule along
/// its bottom edge shows chapter progress. In the novel reader it paints in the stock.
class CineAutoScrollChip extends StatelessWidget {
  const CineAutoScrollChip({
    super.key,
    required this.speedX,
    required this.running,
    required this.onToggle,
    required this.onOpenRuler,
    this.paced = false,
    this.pausedForListen = false,
    this.autoLabel,
    this.progress = 0,
    this.stock,
  });

  final double speedX;
  final bool running, paced, pausedForListen;
  final String? autoLabel;
  final double progress;
  final VoidCallback onToggle, onOpenRuler;

  /// The novel stock's colours; null in the manga reader.
  final CineStockColors? stock;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final playing = running && !pausedForListen;
    final text = autoScrollChipText(speedX: speedX, paced: paced, pausedForListen: pausedForListen, autoLabel: autoLabel);
    final ink = stock?.ink ?? c.colorInk100;
    final muted = stock?.muted ?? c.colorInk60;
    final fill = (stock?.page ?? c.colorPaper2).withValues(alpha: 0.9);
    final rule = stock?.muted ?? c.colorRule2;
    final colour = playing ? ink : muted;
    final label = pausedForListen
        ? 'Auto-scroll, paused for listen'
        : 'Auto-scroll, ${speedX.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')} times, ${playing ? 'playing' : 'paused'}';
    final chip = CinePressable(
      onTap: onToggle,
      onLongPress: onOpenRuler,
      builder: (context, st) => Semantics(
        button: true,
        toggled: playing,
        label: label,
        hint: 'Long press for speed',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, border: Border.all(color: rule)),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CineIcon(playing ? CineIconRole.play : CineIconRole.pause, size: 16, weight: playing ? CineIconWeight.fill : CineIconWeight.regular, color: colour),
                      const SizedBox(width: 8),
                      Flexible(child: CineRoleText(text, c.typeFolio, color: colour)),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: ColoredBox(color: c.colorSpot)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return stock == null ? CineStock.raised(chip) : chip;
  }
}

/// Where the chip sits: bottom-right, 16 px from the right edge (plus the safe inset) and 16 px
/// above the folio bar, or above the bottom inset when the chrome is hidden.
Widget positionAutoScrollChip(BuildContext context, {required bool chromeVisible, required Widget child}) {
  final pad = MediaQuery.viewPaddingOf(context);
  final hit = cineHitMin(context);
  final bar = chromeVisible ? 64.0 : 0.0;
  return Positioned(right: 16 + pad.right, bottom: 16 + pad.bottom + bar, child: ConstrainedBox(constraints: BoxConstraints(minHeight: hit), child: child));
}
