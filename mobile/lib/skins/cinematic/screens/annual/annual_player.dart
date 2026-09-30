import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';

/// The story clock (cinematic 9.2.4, D6): the current page holds its time, then
/// advances. It pauses while held, while the app is not resumed and while
/// keyboard focus is inside the story's controls, and it never runs under
/// reduced motion or while a screen reader runs.
class AnnualPlayer extends ChangeNotifier {
  AnnualPlayer({required TickerProvider vsync, required this.pages, required this.onAdvance})
      : _c = AnimationController(vsync: vsync) {
    _c.addListener(notifyListeners);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && _autoAdvance && index < pages.length - 1) {
        onAdvance(index + 1);
      }
    });
    _start();
  }

  final List<AnnualPageSpec> pages;

  /// Called when the hold elapses: the story moves to this index.
  final ValueChanged<int> onAdvance;

  final AnimationController _c;
  int index = 0;
  bool _autoAdvance = true;
  bool _held = false;
  bool _userPaused = false;
  bool _inactive = false;
  bool _focusInside = false;

  /// 0..1 fill of the current segment.
  double get progress => pages[index].hold == null ? 1 : _c.value;

  bool get running => _autoAdvance && !_held && !_userPaused && !_inactive && !_focusInside && pages[index].hold != null;
  bool get paused => !running;
  bool get userPaused => _userPaused;

  /// Freezes the segment animation and everything keyed on [isRunning].
  bool get isRunning => running;

  void _start() {
    final hold = pages[index].hold;
    if (hold == null) {
      _c.value = 1;
      return;
    }
    _c.duration = hold;
    _c.value = 0;
    _sync();
  }

  void _sync() {
    if (pages[index].hold == null) return;
    if (running) {
      _c.forward();
    } else {
      _c.stop();
    }
    notifyListeners();
  }

  void showPage(int i) {
    if (i == index) return;
    index = i.clamp(0, pages.length - 1);
    _start();
    notifyListeners();
  }

  set autoAdvance(bool v) {
    if (_autoAdvance == v) return;
    _autoAdvance = v;
    _sync();
  }

  set held(bool v) {
    if (_held == v) return;
    _held = v;
    _sync();
  }

  set inactive(bool v) {
    if (_inactive == v) return;
    _inactive = v;
    _sync();
  }

  set focusInside(bool v) {
    if (_focusInside == v) return;
    _focusInside = v;
    _sync();
  }

  void togglePause() {
    _userPaused = !_userPaused;
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
