import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/stocks.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';

export 'package:manhwamaniacs/skins/cinematic/stock.dart' show CineStockColors;

/// The Page frame (cinematic 8.0.1): no app chrome, everything painted in the stock. Provides the
/// one `CineStock.stock` scope and the brightness layer (an `IgnorePointer` black at alpha
/// `|v| / 100`); the profile's mood grade never reaches the page.
class NovelPageFrame extends StatelessWidget {
  const NovelPageFrame({super.key, required this.colors, required this.brightness, required this.child});

  final CineStockColors colors;

  /// -75..0, from the left-edge swipe.
  final int brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) => CineStock.stock(
        colors,
        Material(
          color: colors.page,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (brightness < 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(key: const ValueKey('novel-brightness-layer'), color: Color.fromRGBO(0, 0, 0, brightnessAlpha(brightness))),
                  ),
                ),
            ],
          ),
        ),
      );
}
