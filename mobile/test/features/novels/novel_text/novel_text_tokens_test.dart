import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_tokens.dart';

void main() {
  test('words: 2+ characters, folded, lower-cased', () {
    expect(novelTextWords('The Café, a Tower!'), ['the', 'cafe', 'tower']);
    expect(novelTextWords('a b c'), isEmpty);
    expect(novelTextWords('탑 사랑'), ['사랑']);
    expect(novelTextWords('room 101'), ['room', '101']);
  });
  test('match query is quoted terms, never an operator', () {
    expect(novelTextMatchQuery('tower rabbit'), '"tower" "rabbit"');
    expect(novelTextMatchQuery('tower OR rabbit NEAR/2 "x"*'), '"tower" "or" "rabbit" "near"');
    expect(novelTextMatchQuery('a'), isNull);
    expect(novelTextMatchQuery('   '), isNull);
  });
}
