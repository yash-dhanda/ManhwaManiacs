import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';

void main() {
  String? g(String r) => r.split(':').last == '-' ? null : r.split(':').last;
  test('a matching rail moves up one place', () {
    expect(rerankRails(['a:x', 'b:y', 'c:z'], ['z'], g), ['a:x', 'c:z', 'b:y']);
  });
  test('never above the floor and unmatched rails stay', () {
    expect(rerankRails(['cover:z', 'cont:z', 'b:y'], ['z'], g, floor: 2), ['cover:z', 'cont:z', 'b:y']);
    expect(rerankRails(['a:x', 'b:y'], ['q'], g), ['a:x', 'b:y']);
    expect(rerankRails(['a:x', 'b:-'], ['x'], g), ['a:x', 'b:-']);
  });
  test('newest noted genre applies last', () {
    expect(rerankRails(['a:1', 'b:2', 'c:3', 'd:4'], ['3', '4'], g), ['a:1', 'c:3', 'd:4', 'b:2']);
  });
  test('notes are unique, newest last', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(rerankNotesProvider.notifier)
      ..noteOpenedFromRail('Action')
      ..noteOpenedFromRail('Romance')
      ..noteOpenedFromRail('action');
    expect(c.read(rerankNotesProvider), ['Romance', 'action']);
  });
}
