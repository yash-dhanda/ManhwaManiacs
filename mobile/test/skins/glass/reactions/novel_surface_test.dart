import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/end_matter.dart';

import '../novel/novel_rig.dart';

void main() {
  testWidgets("the novel end matter carries the chapter's reactions and reaching it unseals them", (t) async {
    final rig = await pumpGlassNovel(t);
    await settle(t);
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await settle(t, ms: 600);
    expect(find.descendant(of: find.byType(GlassEndMatter), matching: find.byType(GlassChapterReactions)), findsOneWidget);
    expect(rig.container.read(completedThisSessionProvider), contains(chapterId(kNovelSource, kNovelSeries, '1')));
    await disposeGlassNovel(t);
  });
}
