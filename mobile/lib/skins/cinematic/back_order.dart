import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Priorities of the modal back order (cinematic 8.0.5 "Back inside modal states").
abstract final class CineBackPriority {
  /// Exit select or reorder mode, like `Done`; the selection is discarded.
  static const int selectMode = 1;

  /// Collapse the Listen full player to the mini player.
  static const int fullPlayer = 2;

  /// Close the settings search.
  static const int settingsSearch = 3;

  /// Onboarding step n to n - 1 (from the first shown step, back returns to the picker).
  static const int onboarding = 4;
}

typedef CineBackEntry = ({Object token, int priority});

/// The token whose handler runs: the highest priority wins, the latest registered on a tie.
Object? cineBackWinner(List<CineBackEntry> active) {
  Object? best;
  var bestPriority = -1;
  for (final e in active) {
    if (e.priority >= bestPriority) {
      best = e.token;
      bestPriority = e.priority;
    }
  }
  return best;
}

class CineBackOrder extends Notifier<List<CineBackEntry>> {
  final Map<Object, VoidCallback> _handlers = {};

  @override
  List<CineBackEntry> build() => const [];

  void set(Object token, int priority, {required bool active, VoidCallback? onBack}) {
    final without = [for (final e in state) if (e.token != token) e];
    if (active && onBack != null) {
      _handlers[token] = onBack;
    } else {
      _handlers.remove(token);
    }
    state = active ? [...without, (token: token, priority: priority)] : without;
  }

  /// Runs the winning modal state's handler (the shell calls it when the back press reaches it
  /// instead of the modal's own `PopScope`); false when no modal state is active.
  bool handleBack() {
    final winner = cineBackWinner(state);
    final handler = winner == null ? null : _handlers[winner];
    if (handler == null) return false;
    handler();
    return true;
  }
}

final cineBackOrderProvider = NotifierProvider<CineBackOrder, List<CineBackEntry>>(
  CineBackOrder.new,
  name: 'cineBackOrder',
);

/// Wraps [child] in `PopScope(canPop: !active)` and registers in [cineBackOrderProvider]: when
/// several are active only the highest priority reacts. On iOS `canPop: false` disables the edge
/// swipe for states 1 to 4, as 8.0.5 requires; their visible `Done`, collapse, close and `Back`
/// controls are the way out.
class CineModalBack extends ConsumerStatefulWidget {
  const CineModalBack({super.key, required this.priority, required this.active, required this.onBack, required this.child});

  final int priority;
  final bool active;
  final VoidCallback onBack;
  final Widget child;

  @override
  ConsumerState<CineModalBack> createState() => _CineModalBackState();
}

class _CineModalBackState extends ConsumerState<CineModalBack> {
  final Object _token = Object();
  late final CineBackOrder _order = ref.read(cineBackOrderProvider.notifier);
  bool _alive = true;

  /// False while the state sits in a hidden shell branch or under a covering route (`TickerMode` off): a back press there must not
  /// be spent on a select mode the user cannot see.
  bool _shown = true;

  bool get _active => widget.active && _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(CineModalBack old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.priority != widget.priority) _sync();
  }

  void _sync() => Future.microtask(() {
        if (_alive) _order.set(_token, widget.priority, active: _active, onBack: () => widget.onBack());
      });

  @override
  void dispose() {
    _alive = false;
    Future.microtask(() => _order.set(_token, widget.priority, active: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_active,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || !_active) return;
          if (cineBackWinner(ref.read(cineBackOrderProvider)) == _token) widget.onBack();
        },
        child: widget.child,
      );
}
