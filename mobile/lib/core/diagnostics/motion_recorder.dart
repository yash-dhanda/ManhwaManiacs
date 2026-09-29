import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One recorded move (cinematic 15.9). `plannedMs == 0` marks a scroll-linked
/// move that logs frames and drops per gesture instead of a duration.
class MotionEntry {
  MotionEntry({
    required this.label,
    required this.plannedMs,
    required this.startUs,
    this.endUs,
    this.frames = 0,
    this.dropped = 0,
    this.interrupted = false,
    this.note,
  });

  final String label;
  final int plannedMs;
  final int startUs;
  int? endUs;
  int frames;
  int dropped;
  bool interrupted;

  /// Free text between the label and the duration ("confirm → first splash frame").
  final String? note;

  int get actualMs => (((endUs ?? startUs) - startUs) / 1000).round();

  Map<String, Object?> toJson() => {
        'label': label,
        'plannedMs': plannedMs,
        'actualMs': actualMs,
        'frames': frames,
        'dropped': dropped,
        'interrupted': interrupted,
        if (note != null) 'note': note,
      };
}

/// Handle returned by [MotionRecorder.start]; ending twice is harmless.
class MotionHandle {
  MotionHandle._(this._recorder, this._entry);
  final MotionRecorder? _recorder;
  final MotionEntry? _entry;

  static final MotionHandle noop = MotionHandle._(null, null);

  void end({bool interrupted = false}) => _recorder?._end(_entry!, interrupted);
}

String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// `COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP`.
String formatEntry(MotionEntry e) {
  final label = e.label.padRight(math.max(14, e.label.length + 3));
  if (e.note != null) return '${e.label}  ${e.note}  ${_thousands(e.actualMs)} MS';
  final onTime = e.frames - e.dropped;
  if (e.plannedMs == 0) return '${label}GESTURE   ${e.frames} F   ${e.dropped} DROP';
  return '$label${e.plannedMs} → ${e.actualMs} MS   $onTime/${e.frames} F   ${e.dropped} DROP';
}

/// Late: over plan by more than one frame interval, or any frame dropped.
bool isLate(MotionEntry e, {double frameMs = 1000 / 60}) {
  if (e.dropped > 0) return true;
  if (e.plannedMs == 0) return false;
  return e.actualMs - e.plannedMs > frameMs;
}

const int kSkinRestartBudgetMs = 1500;

class MotionRecorder extends ChangeNotifier {
  MotionRecorder({int Function()? nowUs}) : _nowUs = nowUs ?? (() => DateTime.now().microsecondsSinceEpoch);

  static final MotionRecorder instance = MotionRecorder();

  static const int capacity = 200;

  final int Function() _nowUs;
  final List<MotionEntry> _entries = [];
  final List<MotionEntry> _open = [];
  bool _listening = false;
  bool recording = false;

  List<MotionEntry> get entries => List.unmodifiable(_entries);

  double get frameMs {
    try {
      final d = WidgetsBinding.instance.platformDispatcher.displays;
      final hz = d.isEmpty ? 60.0 : d.first.refreshRate;
      return hz > 0 ? 1000 / hz : 1000 / 60;
    } catch (_) {
      return 1000 / 60;
    }
  }

  MotionHandle start(String label, int plannedMs) {
    if (!recording) return MotionHandle.noop;
    final e = MotionEntry(label: label, plannedMs: plannedMs, startUs: _nowUs());
    _open.add(e);
    if (!_listening) {
      _listening = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
    return MotionHandle._(this, e);
  }

  void _onTimings(List<FrameTiming> timings) {
    final budgetUs = frameMs * 1000;
    for (final t in timings) {
      final late = t.totalSpan.inMicroseconds > budgetUs;
      for (final e in _open) {
        e.frames++;
        if (late) e.dropped++;
      }
    }
  }

  void _end(MotionEntry e, bool interrupted) {
    if (!_open.remove(e)) return;
    e
      ..endUs = _nowUs()
      ..interrupted = interrupted;
    if (_open.isEmpty && _listening) {
      _listening = false;
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    _add(e);
  }

  void _add(MotionEntry e) {
    _entries.add(e);
    if (_entries.length > capacity) _entries.removeRange(0, _entries.length - capacity);
    debugPrint('[motion] ${formatEntry(e)}');
    notifyListeners();
  }

  /// Adds a finished entry regardless of [recording] (SKIN RESTART only).
  void record(MotionEntry e) => _add(e);

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportJson() => jsonEncode([for (final e in _entries) e.toJson()]);
}

/// Reads and removes `mm.skin.t0` (written by `switchSkin()`), records
/// `SKIN RESTART` against the 1,500 ms budget even while recording is off.
/// mobile/06's splash calls it on its first frame.
Future<void> logSkinRestart(SharedPreferences prefs, {MotionRecorder? recorder, int? nowMs}) async {
  final t0 = prefs.getInt('mm.skin.t0');
  if (t0 == null) return;
  await prefs.remove('mm.skin.t0');
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  (recorder ?? MotionRecorder.instance).record(MotionEntry(
    label: 'SKIN RESTART',
    plannedMs: kSkinRestartBudgetMs,
    startUs: t0 * 1000,
    endUs: now * 1000,
    note: 'confirm → first splash frame',
  ),);
}
