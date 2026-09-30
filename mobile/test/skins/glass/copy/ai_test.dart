import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';

void main() {
  test('every reason has both lines, exactly', () {
    expect(glassAiReasons.keys.toSet(), {'not_configured', 'budget_exhausted', 'rate_limited', 'offline', 'upstream_error'});
    for (final e in glassAiReasons.entries) {
      expect(e.value.short, isNotEmpty, reason: e.key);
      expect(e.value.long, isNotEmpty, reason: e.key);
    }
    expect(glassAiReasons['not_configured']!.short, 'AI picks are off on this server');
    expect(glassAiReasons['not_configured']!.long, "AI isn't set up on this server. Everything else works as usual.");
    expect(glassAiReasons['budget_exhausted']!.short, "Today's AI asks are used up");
    expect(glassAiReasons['budget_exhausted']!.long, "You've used today's AI asks. They reset at midnight UTC.");
    expect(glassAiReasons['offline']!.short, 'AI picks need a connection');
    expect(glassAiReasons['upstream_error']!.long, "The AI service didn't answer. Try again in a moment.");
  });

  test('{n} is filled for the rate limit and an unknown reason reads as an upstream error', () {
    expect(glassAiLines('rate_limited', retrySeconds: 9).short, 'AI is busy, retrying in 9 s');
    expect(glassAiLines('rate_limited', retrySeconds: 9).long, 'Too many requests in a row. Trying again in 9 s.');
    expect(glassAiLines('whatever').short, "AI picks didn't load");
  });

  test('partial, timeout and stale lines pluralise', () {
    expect(glassAiPartialLine, "Some picks didn't come through.");
    expect(glassAiTimeoutLine, 'That took too long. Try again.');
    expect(glassAiStaleLine(1), 'Picked 1 day ago');
    expect(glassAiStaleLine(3), 'Picked 3 days ago');
  });
}
