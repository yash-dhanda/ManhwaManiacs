import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The table form of a chart: the same numbers, a header row, inside `Semantics(container: true, label: title)` (glass 7.39).
class ChartTable extends StatelessWidget {
  const ChartTable({super.key, required this.title, required this.data, required this.headers, required this.rowOf});
  final String title;
  final List<ChartDatum> data;
  final List<String> headers;

  /// The cells of one row.
  final List<String> Function(ChartDatum d) rowOf;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: GlassText(c, role: head ? gt.typeCaption1 : gt.typeFootnote, wght: head ? 600 : null, color: head ? gt.colorLabel3 : gt.colorLabel1),
              ),
          ],
        );
    return Semantics(
      container: true,
      label: title,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2)},
        children: [row(headers, head: true), for (final d in data) row(rowOf(d))],
      ),
    );
  }
}

/// Wraps every chart (glass 7.39): the one-sentence summary above (the chart is never the only carrier of its numbers), the
/// readout capsule, and a plain "Show as table" / "Show as chart" button (`t` from the keyboard) that swaps in the [ChartTable].
/// The choice persists per chart per profile in the scoped `mm.glass.prefs` entry's `chartTables` map.
class ChartFrame extends ConsumerWidget {
  const ChartFrame({super.key, required this.chartId, required this.title, required this.summary, required this.chart, required this.table, this.readout});
  final String chartId;
  final String title;
  final String summary;
  final Widget chart;
  final Widget table;

  /// The readout capsule's text, or null when nothing is selected.
  final String? readout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(glassPrefsRecordProvider);
    final asTable = ref.read(glassPrefsRecordProvider.notifier).chartAsTable(chartId);
    final host = GlassHost.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassText(summary, role: gt.typeFootnote, color: host ? gt.colorOnGlass : gt.colorLabel2, onGlass: host),
        const SizedBox(height: 8),
        if (!asTable) SizedBox(height: 28, child: Align(alignment: Alignment.centerLeft, child: readout == null ? const SizedBox.shrink() : ReadoutCapsule(text: readout!))),
        asTable ? table : chart,
        Align(
          alignment: Alignment.centerLeft,
          child: GlassButton(
            label: asTable ? 'Show as chart' : 'Show as table',
            size: GlassButtonSize.small,
            variant: GlassButtonVariant.plain,
            onPressed: () => ref.read(glassPrefsRecordProvider.notifier).setChartAsTable(chartId, !asTable),
          ),
        ),
      ],
    );
  }
}

/// The readout capsule (a content twin, `footnote` `label1`).
class ReadoutCapsule extends StatelessWidget {
  const ReadoutCapsule({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: DecoratedBox(
          key: const ValueKey('glass-chart-readout'),
          decoration: BoxDecoration(color: const Color(0x9E131317), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: GlassText(text, role: gt.typeFootnote, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ),
      );
}
