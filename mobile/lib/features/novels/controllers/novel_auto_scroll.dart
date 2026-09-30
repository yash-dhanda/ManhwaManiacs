import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_controller.dart';

/// Auto-scroll for the novel scroll layout (cinematic 9.4.1): the shared [AutoScrollController]
/// (ramp, touch and drag pauses) driving a [ScrollController] from a `Ticker`, at
/// `basePxPerSecond() * speedX` (the profile's measured reading pace in px/s at 1.00x). Skin
/// neutral: the skin sets the ramp through [controller.configure].
class NovelAutoScroll extends ChangeNotifier {
  NovelAutoScroll({required this.scroll, required this.vsync, required this.basePxPerSecond, this.onEnd});

  final ScrollController scroll;
  final TickerProvider vsync;

  /// px/s at 1.00x for the chapter as laid out now.
  final double Function() basePxPerSecond;

  /// The end of the chapter was reached: auto-scroll stopped.
  final VoidCallback? onEnd;

  final AutoScrollController controller = AutoScrollController();
  double speedX = 1.0;
  bool _running = false;
  Ticker? _ticker;
  Duration? _last;

  bool get running => _running;

  void start() {
    if (_running) return;
    _running = true;
    controller.start();
    _last = null;
    _ticker = vsync.createTicker(_tick)..start();
    notifyListeners();
  }

  void stop({bool notify = true}) {
    if (!_running) return;
    _running = false;
    _ticker?.dispose();
    _ticker = null;
    controller.reset(notify: notify);
    if (notify) notifyListeners();
  }

  void toggle() => _running ? stop() : start();

  /// Tells the chip and the sheet that [speedX] changed.
  void refresh() => notifyListeners();

  void _tick(Duration t) {
    final prev = _last;
    _last = t;
    if (prev == null || !scroll.hasClients || scroll.positions.length != 1) return;
    final px = controller.advance(t - prev, basePxPerSecond() * speedX);
    if (px <= 0) return;
    final pos = scroll.position;
    final target = pos.pixels + px;
    if (target >= pos.maxScrollExtent) {
      scroll.jumpTo(pos.maxScrollExtent);
      stop();
      onEnd?.call();
      return;
    }
    scroll.jumpTo(target);
  }

  @override
  void dispose() {
    stop(notify: false);
    controller.dispose();
    super.dispose();
  }
}
