import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/bar_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_paint.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/clock_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/heatmap_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/radar_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/sparkline_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/status_bars.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum GlassChartKind { bars, heatmap, radar, clock, sparkline, statusBars }

/// A Glass chart (glass 7.39): `CustomPainter`s only, no chart package. Every chart has a one-sentence [summary], a readout on tap,
/// drag or hover (a capsule and a 20 px lens ring over the mark), one focus stop with the arrow keys, `Home` and `End`, semantics
/// `increase` and `decrease`, and "Show as table". Zero shows as "0"; a range with no data says so inside the chart area; a partial
/// datum (today) draws at 60 % with "so far" in its readout.
class GlassChart extends ConsumerStatefulWidget {
  const GlassChart({
    super.key,
    required this.kind,
    required this.data,
    required this.chartId,
    required this.summary,
    required this.readout,
    this.title,
    this.onLabel,
    this.emptyText = 'Nothing to show yet',
    this.valueHeader = 'Value',
    this.secondHeader,
    this.today,
  });

  final GlassChartKind kind;
  final List<ChartDatum> data;
  final String chartId;
  final String summary;
  final String Function(ChartDatum d) readout;

  /// The semantics label and the table's label; defaults to the summary.
  final String? title;

  /// Radar axis labels are buttons that call this with the genre.
  final ValueChanged<String>? onLabel;

  /// Shown inside the chart area when there is no data ("Nothing read in the last 7 days"): the caller passes the range words.
  final String emptyText;
  final String valueHeader;
  final String? secondHeader;

  /// For the heatmap's outlined day; defaults to now.
  final DateTime? today;

  @override
  ConsumerState<GlassChart> createState() => _GlassChartState();
}

class _GlassChartState extends ConsumerState<GlassChart> with TickerProviderStateMixin {
  late final AnimationController _rise; // 0..700 ms of the bar wave
  late final AnimationController _grow; // the radar and clock spring out
  final FocusNode _focus = FocusNode(debugLabel: 'GlassChart');
  int? _sel;
  bool _hasFocus = false;

  bool get _noData => widget.data.isEmpty || widget.data.every((d) => d.value <= 0 && (d.second ?? 0) <= 0 && !d.partial);
  int get _n => widget.data.length;

  @override
  void initState() {
    super.initState();
    _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = AnimationController.unbounded(vsync: this);
    _run();
  }

  @override
  void didUpdateWidget(GlassChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      if (_sel != null && _sel! >= _n) _sel = null;
      _run();
    }
  }

  void _run() {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    _rise.value = 0;
    _grow.value = 0;
    if (reduced) {
      _rise.animateTo(1, duration: const Duration(milliseconds: 150));
      _grow.animateTo(1, duration: const Duration(milliseconds: 150));
      return;
    }
    unawaited(GlassMotion.play(MotionName.chartRise, controller: _rise, target: 1).then((_) => null));
    unawaited(_grow.springTo(1, gt.springCelebrate));
  }

  @override
  void dispose() {
    _rise.dispose();
    _grow.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _readout(ChartDatum d) => widget.readout(d) + (d.partial ? ' so far' : '');

  void _select(int? i, {bool haptic = true}) {
    if (i == _sel || _n == 0) return;
    setState(() => _sel = i);
    if (i != null) {
      if (haptic) glassFire(ref, HapticEvent.select);
      try {
        unawaited(SemanticsService.sendAnnouncement(View.of(context), _readout(widget.data[i]), Directionality.of(context)));
      } catch (_) {}
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final heat = widget.kind == GlassChartKind.heatmap;
    if (k == LogicalKeyboardKey.keyT) {
      final prefs = ref.read(glassPrefsRecordProvider.notifier);
      unawaited(prefs.setChartAsTable(widget.chartId, !prefs.chartAsTable(widget.chartId)));
      return KeyEventResult.handled;
    }
    if (_n == 0) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.arrowRight) {
      _select(stepSelection(_sel, 1, _n));
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _select(stepSelection(_sel, -1, _n));
    } else if (heat && k == LogicalKeyboardKey.arrowDown) {
      _select(stepSelection(_sel, 7, _n));
    } else if (heat && k == LogicalKeyboardKey.arrowUp) {
      _select(stepSelection(_sel, -7, _n));
    } else if (k == LogicalKeyboardKey.home) {
      _select(homeIndex());
    } else if (k == LogicalKeyboardKey.end) {
      _select(endIndex(_n));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _day(ChartDatum d) {
    if (d.label != null) return d.label!;
    final t = d.day;
    if (t == null) return '';
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wd[t.weekday - 1]} ${t.day} ${kMonthShort[t.month - 1]}';
  }

  String _num(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  TextStyle _labelStyle(BuildContext context) => roleStyle(context, gt.typeCaption2, maxScale: 1.3).copyWith(color: gt.colorLabel3);

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final title = widget.title ?? widget.summary;
    final selected = _sel != null && _sel! < _n ? _sel : null;
    final readout = selected == null ? null : _readout(widget.data[selected]);
    final chart = _noData
        ? SizedBox(height: 96, child: Center(child: GlassText(widget.emptyText, role: gt.typeCallout, color: gt.colorLabel2, textAlign: TextAlign.center)))
        : _body(context, reduced, selected);
    final framed = ChartFrame(
      chartId: widget.chartId,
      title: title,
      summary: widget.summary,
      readout: readout,
      chart: chart,
      table: ChartTable(
        title: title,
        data: widget.data,
        headers: [widget.kind == GlassChartKind.clock ? 'Hour' : (widget.kind == GlassChartKind.bars || widget.kind == GlassChartKind.heatmap || widget.kind == GlassChartKind.sparkline ? 'Day' : 'Name'), widget.valueHeader, if (widget.secondHeader != null) widget.secondHeader!],
        rowOf: (d) => [_day(d), _num(d.value), if (widget.secondHeader != null) _num(d.second ?? 0)],
      ),
    );
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      onFocusChange: (f) => setState(() => _hasFocus = f),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Stack(
          children: [
            framed,
            if (_hasFocus) Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: gt.colorIris400.withValues(alpha: 0.6), width: 1.5))))),
          ],
        ),
      ),
    );
  }

  Widget _semantic(Widget child, int? selected) => Semantics(
        label: widget.title ?? widget.summary,
        value: selected == null ? widget.summary : _readout(widget.data[selected]),
        increasedValue: _readout(widget.data[stepSelection(selected, 1, _n)]),
        decreasedValue: _readout(widget.data[stepSelection(selected, -1, _n)]),
        focusable: true,
        onIncrease: () => _select(stepSelection(_sel, 1, _n)),
        onDecrease: () => _select(stepSelection(_sel, -1, _n)),
        child: ExcludeSemantics(child: child),
      );

  Widget _ring(Offset at) => Positioned(
        left: at.dx - 10,
        top: at.dy - 10,
        width: 20,
        height: 20,
        child: IgnorePointer(child: DecoratedBox(key: const ValueKey('glass-chart-ring'), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x9E131317), border: Border.all(color: const Color(0x47FFFFFF), width: 1.5)))),
      );

  Widget _interactive({required Widget child, required int? Function(Offset local) indexAt}) => GlassDragOwner(
        kind: GlassDragOwnerKind.row,
        child: MouseRegion(
          onHover: (e) => _select(indexAt(e.localPosition), haptic: false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(indexAt(d.localPosition)),
            onHorizontalDragUpdate: (d) => _select(indexAt(d.localPosition)),
            onVerticalDragUpdate: widget.kind == GlassChartKind.heatmap ? (d) => _select(indexAt(d.localPosition)) : null,
            child: child,
          ),
        ),
      );

  Widget _body(BuildContext context, bool reduced, int? selected) {
    final label = _labelStyle(context);
    final data = widget.data;
    switch (widget.kind) {
      case GlassChartKind.bars:
        return LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, 140);
            final every = math.max(1, (data.length / math.max(1, box.maxWidth / 26)).ceil());
            return _semantic(
              _interactive(
                indexAt: (p) => data.isEmpty ? null : (p.dx / (size.width / data.length)).floor().clamp(0, data.length - 1),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: AnimatedBuilder(
                    animation: _rise,
                    builder: (context, _) => Stack(children: [
                      Positioned.fill(child: Opacity(opacity: reduced ? _rise.value.clamp(0.0, 1.0) : 1, child: CustomPaint(painter: BarPainter(data: data, tMs: _rise.value * 700, label: label, selected: selected, labelEvery: every, reduced: reduced)))),
                      if (selected != null) _ring(BarPainter.markCenter(data, selected, size)),
                    ],),
                  ),
                ),
              ),
              selected,
            );
          },
        );
      case GlassChartKind.heatmap:
        final size = HeatmapPainter.sizeFor(data);
        final today = widget.today ?? DateTime.now();
        return _semantic(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: _interactive(
              indexAt: (p) => HeatmapPainter.indexAt(data, p),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: AnimatedBuilder(
                  animation: _rise,
                  builder: (context, _) => Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: HeatmapPainter(data: data, label: label, selected: selected, today: today, fade: reduced ? _rise.value.clamp(0.0, 1.0) : 1))),
                    if (selected != null) _ring(HeatmapPainter.cellRect(data, selected).center),
                  ],),
                ),
              ),
            ),
          ),
          selected,
        );
      case GlassChartKind.radar:
        return LayoutBuilder(
          builder: (context, box) {
            final side = math.min(box.maxWidth, 280.0);
            final size = Size(side, side);
            return Center(
              child: _semantic(
                SizedBox(
                  width: side,
                  height: side,
                  child: AnimatedBuilder(
                    animation: _grow,
                    builder: (context, _) => Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: RadarPainter(data: data, scale: _grow.value, selected: selected, reduced: reduced))),
                      for (var i = 0; i < data.length; i++) _radarLabel(i, size, label),
                      if (selected != null) _ring(RadarPainter.vertexAt(data, selected, size) * (reduced ? 1 : _grow.value.clamp(0.0, 1.2)) + (reduced ? Offset.zero : RadarPainter.center(size) * (1 - _grow.value.clamp(0.0, 1.2)))),
                    ],),
                  ),
                ),
                selected,
              ),
            );
          },
        );
      case GlassChartKind.clock:
        const size = Size(200, 200);
        final peak = peakHour([for (final d in data) d.value]);
        return Column(children: [
          _semantic(
            _interactive(
              indexAt: (p) => ClockPainter.indexAt(p, size),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: AnimatedBuilder(
                  animation: _grow,
                  builder: (context, _) => Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: ClockPainter(data: data, grow: _grow.value, selected: selected, reduced: reduced))),
                    if (selected != null) _ring(ClockPainter.markCenter(data, selected, size)),
                  ],),
                ),
              ),
            ),
            selected,
          ),
          if (peak != null) Padding(padding: const EdgeInsets.only(top: 8), child: GlassText('${peakLine(peak)} · ${bandWord(peak)}', role: gt.typeCallout, color: gt.colorLabel2, textAlign: TextAlign.center)),
        ],);
      case GlassChartKind.sparkline:
        return LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth.isFinite ? box.maxWidth : 120, SparklinePainter.height);
            return _semantic(
              _interactive(
                indexAt: (p) => data.length <= 1 ? 0 : ((p.dx - 2) / ((size.width - 4) / (data.length - 1))).round().clamp(0, data.length - 1),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: AnimatedBuilder(
                    animation: _rise,
                    builder: (context, _) => Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: SparklinePainter(data: data, progress: reduced ? 1 : Curves.easeOutCubic.transform(_rise.value), selected: selected))),
                      if (selected != null) _ring(SparklinePainter.pointAt(data, selected, size)),
                    ],),
                  ),
                ),
              ),
              selected,
            );
          },
        );
      case GlassChartKind.statusBars:
        return _semantic(
          _interactive(
            indexAt: (p) => data.isEmpty ? null : (p.dy / 26).floor().clamp(0, data.length - 1),
            child: AnimatedBuilder(animation: _rise, builder: (context, _) => StatusBars(data: data, selected: selected, grow: reduced ? 1 : Curves.easeOutCubic.transform(_rise.value))),
          ),
          selected,
        );
    }
  }

  Widget _radarLabel(int i, Size size, TextStyle style) {
    final at = RadarPainter.labelAt(i, widget.data.length, size);
    final name = widget.data[i].label ?? '';
    return Positioned(
      left: at.dx - 40,
      top: at.dy - 24,
      width: 80,
      height: 48,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.95,
        onTap: widget.onLabel == null ? null : () => widget.onLabel!(name),
        enabled: widget.onLabel != null,
        semanticsLabel: name,
        builder: (context, info) => Center(child: Text(name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textScaler: TextScaler.noScaling)),
      ),
    );
  }
}
