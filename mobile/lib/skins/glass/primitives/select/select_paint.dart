// Pure selection helpers (glass 7.35): range painting along a pointer path, shift ranges, the 200 cap.

/// The loaded page a "select all" can reach.
const int kSelectAllCap = 200;

/// The paint mode of a drag: the new state of its first item.
bool paintModeFrom({required bool firstWasSelected}) => !firstWasSelected;

/// Applies [mode] (true = select) to the items along the pointer path, in the order they were crossed.
Set<K> paintAlong<K>(Set<K> selected, Iterable<K> path, bool mode, {bool Function(K)? enabled}) {
  final out = {...selected};
  for (final id in path) {
    if (enabled != null && !enabled(id)) continue;
    if (mode) {
      out.add(id);
    } else {
      out.remove(id);
    }
  }
  return out;
}

/// The ids from [a] to [b] inclusive in the order of [visible] (either direction). Empty when one is not visible.
List<K> rangeBetween<K>(List<K> visible, K a, K b) {
  final i = visible.indexOf(a), j = visible.indexOf(b);
  if (i < 0 || j < 0) return const [];
  final lo = i < j ? i : j, hi = i < j ? j : i;
  return visible.sublist(lo, hi + 1);
}

/// "Select all": every visible id up to the loaded page of 200.
List<K> selectAllVisible<K>(List<K> visible, {int cap = kSelectAllCap}) => visible.length <= cap ? visible : visible.sublist(0, cap);

/// The line after a capped select all ("Selected 200 of 412 shown"), or null when everything visible was selected.
String? selectionCapMessage(int selected, int shown, {int cap = kSelectAllCap}) => shown > cap ? 'Selected $selected of $shown shown' : null;

/// The chip label: "Select all (412 visible)".
String selectAllLabel(int visible) => 'Select all ($visible visible)';

/// The polite count announcement.
String selectedCountLabel(int n) => '$n selected';
