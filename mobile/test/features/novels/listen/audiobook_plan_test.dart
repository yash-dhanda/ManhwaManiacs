import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/narration_save_state.dart';
import 'package:manhwamaniacs/features/novels/utils/audiobook_plan.dart';

void main() {
  final chapters = [for (var i = 1; i <= 15; i++) AudiobookChapter(key: 'c$i', label: 'Chapter $i')];

  AudiobookPlan plan({Set<String>? rendered, Set<String>? narratable, Map<String, NarrationSaveState>? saved, List<String> revoice = const [], String? from}) => AudiobookPlan(
        chapters: chapters,
        rendered: rendered ?? {'c1', 'c2', 'c3'},
        narratable: narratable ?? {for (var i = 1; i <= 14; i++) 'c$i'},
        saved: saved ?? const {},
        revoice: revoice,
        fromKey: from,
      );

  group('NARRATE', () {
    test('captions cover every status', () {
      final p = plan(saved: {'c1': NarrationSaveState.saved});
      expect(p.caption(AudiobookMode.narrate, 'c1', selected: false), 'ALREADY NARRATED · SAVED');
      expect(p.caption(AudiobookMode.narrate, 'c2', selected: false), 'ALREADY NARRATED');
      expect(p.caption(AudiobookMode.narrate, 'c2', selected: true), 'ALREADY NARRATED · WILL BE RE-VOICED');
      expect(p.caption(AudiobookMode.narrate, 'c15', selected: false), 'DOWNLOAD THE TEXT FIRST');
      expect(p.caption(AudiobookMode.narrate, 'c5', selected: false), isNull);
    });

    test('selectable: narrated (to re-voice) and cached chapters, not uncached ones', () {
      final p = plan();
      expect(p.selectable(AudiobookMode.narrate, 'c1'), isTrue);
      expect(p.selectable(AudiobookMode.narrate, 'c5'), isTrue);
      expect(p.selectable(AudiobookMode.narrate, 'c15'), isFalse);
    });

    test('ALL UN-NARRATED and NEXT 10 start where the reader is', () {
      final p = plan(from: 'c4');
      expect(p.all(AudiobookMode.narrate), ['c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12', 'c13', 'c14']);
      expect(p.nextTen(AudiobookMode.narrate), ['c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12', 'c13']);
      expect(plan().nextTen(AudiobookMode.narrate).first, 'c4');
    });

    test('a send splits by force: narrated chapters force, the rest do not; each group chunks at 200', () {
      final p = plan();
      final g = p.groups(['c1', 'c5', 'c2', 'c6']);
      expect(g.force, [['c1', 'c2']]);
      expect(g.fresh, [['c5', 'c6']]);
      final many = AudiobookPlan(
        chapters: [for (var i = 0; i < 450; i++) AudiobookChapter(key: 'k$i', label: '$i')],
        rendered: const {},
        narratable: {for (var i = 0; i < 450; i++) 'k$i'},
        saved: const {},
      );
      expect(many.groups([for (var i = 0; i < 450; i++) 'k$i']).fresh.map((c) => c.length), [200, 200, 50]);
    });
  });

  group('SAVE', () {
    test('captions cover every status', () {
      final p = plan(saved: {
        'c1': NarrationSaveState.saved,
        'c2': NarrationSaveState.unplayable,
        'c3': NarrationSaveState.failed,
        'c4': NarrationSaveState.saving,
      }, rendered: {'c1', 'c2', 'c3', 'c4', 'c5'},);
      expect(p.caption(AudiobookMode.save, 'c1', selected: false), 'SAVED');
      expect(p.caption(AudiobookMode.save, 'c2', selected: false), "SAVED COPY CAN'T PLAY ON THIS PHONE");
      expect(p.caption(AudiobookMode.save, 'c3', selected: false), "COULDN'T BE SAVED");
      expect(p.caption(AudiobookMode.save, 'c4', selected: false), 'SAVING…');
      expect(p.caption(AudiobookMode.save, 'c5', selected: false), 'NARRATED');
      expect(p.caption(AudiobookMode.save, 'c9', selected: false), 'NOT NARRATED YET');
    });

    test('only narrated chapters that are not saved or saving are pickable', () {
      final p = plan(saved: {'c1': NarrationSaveState.saved, 'c2': NarrationSaveState.unplayable, 'c3': NarrationSaveState.failed});
      expect(p.selectable(AudiobookMode.save, 'c1'), isFalse);
      expect(p.selectable(AudiobookMode.save, 'c2'), isTrue);
      expect(p.selectable(AudiobookMode.save, 'c3'), isTrue);
      expect(p.selectable(AudiobookMode.save, 'c4'), isFalse);
      expect(p.all(AudiobookMode.save), ['c2', 'c3']);
    });
  });

  test('words', () {
    expect(audiobookPrimaryLabel(AudiobookMode.narrate, 12), 'Narrate 12 chapters');
    expect(audiobookPrimaryLabel(AudiobookMode.narrate, 1), 'Narrate 1 chapter');
    expect(audiobookPrimaryLabel(AudiobookMode.save, 12), 'Save audio of 12 chapters');
    expect(audiobookEstimate(AudiobookMode.narrate), 'About 9 minutes of rendering per chapter on the narration PC.');
    expect(audiobookEstimate(AudiobookMode.save), 'Saves while the app is open; the text is saved too.');
  });
}
