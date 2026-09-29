
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layers 3 to 6 of glass 2.4.1, low to high.
enum GlassLayerKind { controls, overlays, interruptions, hud }

/// The Flutter budget of glass 2.4.4 / 15.7.
const int kGlassLayerBudget = 6;
const int kGlassShapeBudget = 8;

/// Development galleries only: everything registered below is listed but not counted or warned about.
class GlassBudgetScope extends InheritedWidget {
  const GlassBudgetScope({super.key, required this.exempt, required this.label, required super.child});

  final bool exempt;
  final String label;

  static GlassBudgetScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassBudgetScope>();

  @override
  bool updateShouldNotify(GlassBudgetScope old) => old.exempt != exempt || old.label != label;
}

/// One live surface. A group is one layer with several shapes; a scrim counts on its own.
class GlassRegistration {
  const GlassRegistration({
    required this.id,
    required this.label,
    required this.kind,
    required this.shapes,
    required this.rect,
    this.scrim = false,
    this.exempt = false,
  });

  final int id;
  final String label;
  final GlassLayerKind kind;
  final int shapes;
  final Rect? Function() rect;
  final bool scrim;
  final bool exempt;
}

@immutable
class GlassRegistryState {
  const GlassRegistryState({this.entries = const [], this.forcedSolid = const {}});

  final List<GlassRegistration> entries;

  /// Surfaces that render solid because three layers stack over them (glass 2.4.2 rule 7).
  final Set<int> forcedSolid;

  Iterable<GlassRegistration> get _counted => entries.where((e) => !e.exempt);
  int get layers => _counted.where((e) => !e.scrim).length;
  int get shapes => _counted.where((e) => !e.scrim).fold(0, (n, e) => n + e.shapes);
  int get scrims => _counted.where((e) => e.scrim).length;
}

class GlassRegistryController extends Notifier<GlassRegistryState> {
  int _next = 0;
  bool _warned = false;
  bool _recomputeQueued = false;

  @override
  GlassRegistryState build() => const GlassRegistryState();

  int newId() => ++_next;

  void register(GlassRegistration r) {
    state = GlassRegistryState(entries: [...state.entries, r], forcedSolid: state.forcedSolid);
    _checkBudget();
    scheduleRecompute();
  }

  void unregister(int id) {
    if (!state.entries.any((e) => e.id == id)) return;
    state = GlassRegistryState(
      entries: [for (final e in state.entries) if (e.id != id) e],
      forcedSolid: {...state.forcedSolid}..remove(id),
    );
    scheduleRecompute();
  }

  void _checkBudget() {
    final over = state.layers > kGlassLayerBudget || state.shapes > kGlassShapeBudget;
    if (over && !_warned && kDebugMode) {
      debugPrint('Glass budget exceeded: ${state.layers}/$kGlassLayerBudget layers, ${state.shapes}/$kGlassShapeBudget shapes: '
          '${[for (final e in state.entries) if (!e.exempt) '${e.label}(${e.kind.name}, ${e.shapes})'].join(', ')}');
    }
    _warned = over;
  }

  /// After each register, unregister and metrics change (post frame).
  void scheduleRecompute() {
    if (_recomputeQueued) return;
    _recomputeQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _recomputeQueued = false;
      recompute();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// A surface overlapped by two live surfaces of higher layers that also overlap each other goes solid.
  @visibleForTesting
  void recompute() {
    final live = [for (final e in state.entries) if (!e.scrim) (e, e.rect())];
    final forced = <int>{};
    for (final (e, r) in live) {
      if (r == null) continue;
      final above = [
        for (final (o, or) in live)
          if (or != null && o.kind.index > e.kind.index && or.overlaps(r)) or,
      ];
      outer:
      for (var i = 0; i < above.length; i++) {
        for (var j = i + 1; j < above.length; j++) {
          if (above[i].overlaps(above[j])) {
            forced.add(e.id);
            break outer;
          }
        }
      }
    }
    if (!setEquals(forced, state.forcedSolid)) {
      state = GlassRegistryState(entries: state.entries, forcedSolid: forced);
    }
  }
}

/// `{layers, shapes, scrims}` for the layers row and the budget warning.
final glassRegistryProvider = NotifierProvider<GlassRegistryController, GlassRegistryState>(GlassRegistryController.new);

/// Re-runs the stacking check when the window metrics change (rotation, split screen).
class GlassMetricsWatcher extends ConsumerStatefulWidget {
  const GlassMetricsWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassMetricsWatcher> createState() => _GlassMetricsWatcherState();
}

class _GlassMetricsWatcherState extends ConsumerState<GlassMetricsWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => ref.read(glassRegistryProvider.notifier).scheduleRecompute();

  @override
  Widget build(BuildContext context) => widget.child;
}
