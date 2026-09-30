import 'dart:async';

import 'package:manhwamaniacs/features/library/models/world_item.dart';

const _words = ['Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];

/// Follows every pick that has a source (its first), [concurrency] at a time, in pick order.
/// Information-only picks (`available` empty) are neither followed nor failed.
Future<({List<WorldItem> followed, List<WorldItem> failed})> runFollows(
  List<WorldItem> picks,
  Future<bool> Function({required String sourceId, required String seriesKey}) follow, {
  int concurrency = 4,
}) async {
  final todo = [for (final p in picks) if (p.available.isNotEmpty) p];
  final ok = List<bool?>.filled(todo.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < todo.length) {
      final i = next++;
      final a = todo[i].available.first;
      try {
        ok[i] = await follow(sourceId: a.sourceId, seriesKey: a.seriesKey);
      } catch (_) {
        ok[i] = false;
      }
    }
  }

  await Future.wait([for (var k = 0; k < concurrency; k++) worker()]);
  return (
    followed: [for (var i = 0; i < todo.length; i++) if (ok[i] ?? false) todo[i]],
    failed: [for (var i = 0; i < todo.length; i++) if (!(ok[i] ?? false)) todo[i]],
  );
}

/// Null when everything was followed, else "Followed 4 of 5. One couldn't be added.".
String? followedToast(int ok, int total) {
  final bad = total - ok;
  if (bad <= 0) return null;
  final n = bad < 10 ? _words[bad] : '$bad';
  return "Followed $ok of $total. $n couldn't be added.";
}

/// The posters that fly: the first 12 followed picks in pick order.
List<WorldItem> flightList(List<WorldItem> followed) => followed.take(12).toList();
