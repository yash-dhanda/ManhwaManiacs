import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stagger maths of cinematic 4.6; pure, so it is tested without a widget.
int gridDelay(int indexInRow, int row) => math.min(480, 32 * indexInRow + 64 * row);

int listDelay(int i) => math.min(360, 24 * i);

/// Per-grapheme step; [n] counts graphemes excluding spaces.
double letterStep(int n) => n < 2 ? 0 : math.min(24.0, 560 / (n - 1));

/// Each word fades 160 ms.
int wordDelay(int i) => 30 * i;

int typedCount(int elapsedMs, int length) => math.min(length, elapsedMs ~/ 50);

enum EntranceKind { none, dissolve, set }

/// Returning through back never replays a stagger; a skeleton, refetch, append or
/// pull to refresh dissolves as one block; otherwise Set.
EntranceKind decideEntrance({required bool seenThisSession, required bool hadSkeleton, required bool isAppend}) {
  if (seenThisSession) return EntranceKind.none;
  if (hadSkeleton || isAppend) return EntranceKind.dissolve;
  return EntranceKind.set;
}

/// Keys of the form `'${GoRouterState.of(context).uri.path}:$listKey'`.
final seenListsProvider = StateProvider<Set<String>>((ref) => <String>{}, name: 'seenLists');
