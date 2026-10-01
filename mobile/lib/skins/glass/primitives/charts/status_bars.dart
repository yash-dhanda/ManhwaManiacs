import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The reading-status breakdown (glass 7.39): one bar per status in the 2.1.4 colours (Reading `iris400`, Completed `success`,
/// On hold `warning`, Plan to read `info`, Dropped `g700`, Unread `g800`), each with its word and count. Datum labels are the
/// [GlassStatus] names ("reading", "completed", ...); values are the counts.
class StatusBars extends StatelessWidget {
  const StatusBars({super.key, required this.data, this.selected, this.grow = 1});
  final List<ChartDatum> data;
  final int? selected;
  final double grow;

  static GlassStatus? statusOf(String? label) {
    for (final s in GlassStatus.values) {
      if (s.name == label || s.spoken == label) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final max = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    // The word column fits the longest word at the current text size (92 px at least, 45 % of the row at most).
    final style = roleStyle(context, gt.typeFootnote);
    final widest = data.fold<double>(0, (m, d) {
      final w = measureText(context, _word(d.label), style).width;
      return w > m ? w : m;
    });
    return LayoutBuilder(builder: (context, outer) {
    final wordW = (widest + 8).clamp(92.0, outer.hasBoundedWidth ? outer.maxWidth * 0.45 : widest + 8).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: wordW, child: GlassText(_word(data[i].label), role: gt.typeFootnote, color: selected == i ? gt.colorLabel1 : gt.colorLabel2, maxLines: 2)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final w = max <= 0 ? 0.0 : box.maxWidth * data[i].value / max * grow.clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: data[i].value <= 0 ? 2 : w.clamp(2.0, box.maxWidth),
                          height: 10,
                          child: DecoratedBox(decoration: BoxDecoration(color: data[i].value <= 0 ? gt.colorFill2 : (statusOf(data[i].label)?.color ?? gt.colorIris500), borderRadius: BorderRadius.circular(5))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(constraints: const BoxConstraints(minWidth: 36), child: GlassText('${data[i].value.round()}', role: gt.typeMono, textAlign: TextAlign.right, color: gt.colorLabel1)),
              ],
            ),
          ),
      ],
    );
    },);
  }

  static String _word(String? label) {
    final s = statusOf(label);
    if (s == null) return label ?? '';
    final w = s.spoken;
    return w[0].toUpperCase() + w.substring(1);
  }
}
