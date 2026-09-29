import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// One named move (or a marker such as `SKIN RESTART`) in the motion-timings ring.
class GlassMotionEntry {
  GlassMotionEntry({required this.label, required this.plannedMs, required this.startMicros, this.marker = false});

  final String label;
  final int plannedMs;
  final int startMicros;
  final bool marker;
  int? endMicros;

  /// Frames whose build started while the move ran, and how many of them blew the frame budget.
  int frames = 0;
  int dropped = 0;

  /// The frame budget in ms at the refresh rate the move ran at.
  double budgetMs = 1000 / 60;

  double get actualMs => ((endMicros ?? startMicros) - startMicros) / 1000;

  /// Frames the move should have rendered at the current refresh rate.
  int get expectedFrames => marker ? 0 : (actualMs / budgetMs).round();

  /// A row is flagged when it dropped frames or overran its planned settle by more than one frame.
  bool get flagged => !marker && (dropped > 0 || actualMs > plannedMs + budgetMs);

  Map<String, Object?> toJson() => {
        'label': label,
        'plannedMs': plannedMs,
        'actualMs': double.parse(actualMs.toStringAsFixed(1)),
        'frames': frames,
        'expectedFrames': expectedFrames,
        'dropped': dropped,
        'marker': marker,
      };
}

/// The ring buffer (200 entries) and the frame sampler behind both motion-timings overlays.
/// Skin-neutral: it knows nothing about a skin's motion table.
class GlassMotionRecorder extends ChangeNotifier {
  GlassMotionRecorder({this.capacity = 200, int Function()? clock}) : _clock = clock ?? (() => Timeline.now);

  static final GlassMotionRecorder instance = GlassMotionRecorder();

  final int capacity;
  final int Function() _clock;
  final List<GlassMotionEntry> _entries = [];
  bool _attached = false;

  List<GlassMotionEntry> get entries => List.unmodifiable(_entries);

  /// Starts sampling frames (once per process).
  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  double _budgetMs() {
    final views = ui.PlatformDispatcher.instance.views;
    final rate = views.isEmpty ? 60.0 : views.first.display.refreshRate;
    return 1000 / (rate <= 0 ? 60.0 : rate);
  }

  GlassMotionEntry begin(String label, int plannedMs) {
    final e = GlassMotionEntry(label: label, plannedMs: plannedMs, startMicros: _clock())..budgetMs = _budgetMs();
    _push(e);
    return e;
  }

  void end(GlassMotionEntry e) {
    e.endMicros = _clock();
    notifyListeners();
  }

  /// A one-line marker such as `SKIN RESTART`.
  void mark(String label) {
    final e = GlassMotionEntry(label: label, plannedMs: 0, startMicros: _clock(), marker: true)..endMicros = _clock();
    _push(e);
  }

  void _push(GlassMotionEntry e) {
    _entries.add(e);
    if (_entries.length > capacity) _entries.removeAt(0);
    if (kDebugMode) debugPrint('motion ${e.label} planned ${e.plannedMs} ms');
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Credits one rendered frame that started building at [buildStartMicros] to every move it overlapped.
  void sampleFrame({required int buildStartMicros, required double totalMs}) {
    for (final e in _entries) {
      if (e.marker) continue;
      final end = e.endMicros ?? 1 << 62;
      if (buildStartMicros >= e.startMicros && buildStartMicros <= end) {
        e.frames++;
        if (totalMs > e.budgetMs) e.dropped++;
      }
    }
    notifyListeners();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      sampleFrame(
        buildStartMicros: t.timestampInMicroseconds(ui.FramePhase.buildStart),
        totalMs: (t.buildDuration + t.rasterDuration).inMicroseconds / 1000,
      );
    }
  }

  /// Every entry as JSON, for `Copy log`.
  String toJsonLog() => const JsonEncoder.withIndent('  ').convert([for (final e in _entries) e.toJson()]);
}
