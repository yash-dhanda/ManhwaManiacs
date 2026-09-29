import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// "{n} new chapters across {m} series.", with the singular cases ("1 new chapter in 1 series.",
/// "{n} new chapters in 1 series.").
String stopPressLine(int chapters, int series) {
  final c = chapters == 1 ? '1 new chapter' : '$chapters new chapters';
  if (series == 1) return '$c in 1 series.';
  return '$c across $series series.';
}

/// The highest notification id the reader dismissed this session; a newer one shows it again.
final stopPressDismissedProvider = StateProvider<int>((ref) => 0, name: 'stopPressDismissed');

enum StopPressPlacement { bottom, top }

/// The stop-press banner (cinematic 8.33.3, 7.29): a subtitle-style strip on `paper.2` in
/// `CineStock.raised`, a 1 px `rule.2` border and a 2 px `spot` left rule; kicker `STOP PRESS`,
/// the line, `Read updates` and a `bare` `x` labelled "Dismiss". `top` paints it at the top edge in
/// the given stock colours for the novel reader (mobile/14 verifies it).
class CineStopPressBanner extends StatelessWidget {
  const CineStopPressBanner({
    super.key,
    required this.chapters,
    required this.series,
    required this.onRead,
    required this.onDismiss,
    this.placement = StopPressPlacement.bottom,
    this.stockPage,
    this.stockInk,
  });

  final int chapters, series;
  final VoidCallback onRead, onDismiss;
  final StopPressPlacement placement;

  /// The novel reader's page and ink colours, for `top`.
  final Color? stockPage, stockInk;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final line = stopPressLine(chapters, series);
    final fill = stockPage ?? c.colorPaper2;
    final ink = stockInk ?? c.colorInk100;
    final strip = Container(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: c.colorRule2),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 2, color: c.colorSpot),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(c.space3, c.space2, 0, c.space2),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    CineRoleText('STOP PRESS', c.typeKicker, color: c.colorSpot),
                    CineRoleText(line, c.typeUi, color: ink),
                  ],),
                ),
                CineButton(label: 'Read updates', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onRead),
                CineIconButton(label: 'Dismiss', role: CineIconRole.close, onPressed: onDismiss),
              ],),
            ),
          ),
        ],),
      ),
    );
    return Semantics(container: true, liveRegion: true, label: 'Stop press, $line', child: CineStock.raised(strip));
  }
}
