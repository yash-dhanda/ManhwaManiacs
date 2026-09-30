import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';

class _Fake implements PurgeSteps {
  final List<String> calls = [];
  @override
  void stopMatureAndClearAccessory() => calls.add('stop');
  @override
  void popMatureLevels() => calls.add('pop');
  @override
  void dropSnapshotsAndRecents() => calls.add('drop');
  @override
  void clearImageCaches() => calls.add('images');
  @override
  void runHoldersAndInvalidate() => calls.add('holders');
}

void main() {
  test('the 18+ purge runs its steps in the specified order', () {
    final f = _Fake();
    runMaturePurge(f);
    expect(f.calls, ['stop', 'pop', 'drop', 'images', 'holders']);
  });

  test('registered stops and holders are called, and unregister removes them', () {
    GlassStops.reset();
    var stopped = 0;
    var playback = 0;
    final d1 = registerMatureStop('narration', () => stopped++);
    final d2 = registerPlaybackStop('soundscape', () => playback++);
    GlassStops.stopMature();
    expect((stopped, playback), (1, 0));
    GlassStops.stopAllPlayback();
    expect((stopped, playback), (2, 1));
    d1();
    d2();
    GlassStops.stopAllPlayback();
    expect((stopped, playback), (2, 1));
    GlassStops.reset();
  });
}
