import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/library_selection_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_paint.dart';

/// Select-mode state for any grid or list (glass 7.35).
class GlassSelectModeController<K> extends ChangeNotifier {
  bool _active = false;
  Set<K> _selected = {};
  K? _last;

  /// The visible ids in order, set by the [GlassSelectableGroup]; ranges and select-all read it.
  List<K> Function() order = () => const [];

  bool get active => _active;
  Set<K> get selected => _selected;
  K? get lastToggled => _last;
  int get count => _selected.length;
  bool isSelected(K id) => _selected.contains(id);

  /// Enters select mode, optionally with [first] already picked.
  void enter([K? first]) {
    _active = true;
    if (first != null) {
      _selected = {..._selected, first};
      _last = first;
    }
    notifyListeners();
  }

  void toggle(K id) {
    _active = true;
    final next = {..._selected};
    if (!next.remove(id)) next.add(id);
    _selected = next;
    _last = id;
    notifyListeners();
  }

  /// Selects the range from the last toggled item to [id] (or just [id] when nothing was toggled).
  void extendTo(K id) {
    _active = true;
    final from = _last;
    final range = from == null ? [id] : rangeBetween(order(), from, id);
    _selected = {..._selected, ...(range.isEmpty ? [id] : range)};
    _last = id;
    notifyListeners();
  }

  void setSelected(Set<K> ids) {
    _selected = ids;
    notifyListeners();
  }

  /// Every visible item, up to the loaded page of 200.
  void selectAll([List<K>? visible]) {
    _active = true;
    _selected = selectAllVisible(visible ?? order()).toSet();
    notifyListeners();
  }

  void clear() {
    if (_selected.isEmpty) return;
    _selected = {};
    _last = null;
    notifyListeners();
  }

  void exit() {
    if (!_active && _selected.isEmpty) return;
    _active = false;
    _selected = {};
    _last = null;
    notifyListeners();
  }
}

/// Mirrors a controller into the shared [librarySelectionProvider] and back (the Library wraps that provider, it never
/// forks it). Returns the disposer.
VoidCallback bridgeLibrarySelection(WidgetRef ref, GlassSelectModeController<int> c) {
  var mirroring = false;
  void toProvider() {
    if (mirroring) return;
    mirroring = true;
    final n = ref.read(librarySelectionProvider.notifier);
    final s = ref.read(librarySelectionProvider);
    if (c.active && !s.active) {
      n.enterSelectionMode();
    } else if (!c.active && s.active) {
      n.exitSelectionMode();
    }
    if (c.active) n.selectAll(c.selected);
    mirroring = false;
  }

  c.addListener(toProvider);
  final sub = ref.listenManual(librarySelectionProvider, (_, s) {
    if (mirroring) return;
    mirroring = true;
    if (s.active) {
      c.active ? c.setSelected(s.selectedIds) : c.enter();
      c.setSelected(s.selectedIds);
    } else {
      c.exit();
    }
    mirroring = false;
  });
  return () {
    c.removeListener(toProvider);
    sub.close();
  };
}
