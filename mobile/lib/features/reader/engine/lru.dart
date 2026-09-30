import 'dart:collection';

/// A least-recently-used map.
class Lru<K, V> {
  Lru(this.capacity);
  final int capacity;
  final LinkedHashMap<K, V> _m = LinkedHashMap<K, V>();

  int get length => _m.length;

  V? operator [](K key) {
    final v = _m.remove(key);
    if (v == null) return null;
    _m[key] = v;
    return v;
  }

  void operator []=(K key, V value) {
    _m.remove(key);
    _m[key] = value;
    if (_m.length > capacity) _m.remove(_m.keys.first);
  }

  bool containsKey(K key) => _m.containsKey(key);
}
