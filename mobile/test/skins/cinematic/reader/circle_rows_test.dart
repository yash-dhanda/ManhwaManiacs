import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/circle_rows.dart';

CircleMemberRef m(int id, String name) => CircleMemberRef(profileId: id, name: name);

void main() {
  final data = CircleSeriesData(
    readers: [
      CircleReader(member: m(1, 'Asha'), chapterKey: 'c142', chapterNumber: 142),
      CircleReader(member: m(2, 'Riya'), chapterKey: 'c150', chapterNumber: 150),
      CircleReader(member: m(3, 'Kabir'), chapterKey: 'c141', chapterNumber: 141),
    ],
    chapters: [
      CircleChapterReactions(chapterKey: 'c142', chapterNumber: 142, by: [ReactionBy.of(m(1, 'Asha'), ReactionKind.chefsKiss)]),
      CircleChapterReactions(chapterKey: 'c144', chapterNumber: 144, by: [ReactionBy.of(m(4, 'Dev'), ReactionKind.tears)]),
    ],
  );

  test('guarded while the open chapter is not finished', () {
    final rows = circleRows(data, openKey: 'c142', openNumber: 142, completedOpen: false);
    final asha = rows.firstWhere((r) => r.member.name == 'Asha');
    expect(asha.kind, CircleRowKind.guarded);
    expect(asha.chapterNumber, 142);
    expect(rows.firstWhere((r) => r.member.name == 'Dev').kind, CircleRowKind.guarded);
    expect(rows.firstWhere((r) => r.member.name == 'Dev').chapterNumber, 144);
    final riya = rows.firstWhere((r) => r.member.name == 'Riya');
    expect(riya.kind, CircleRowKind.further);
    expect(riya.chapterNumber, 150);
    expect(rows.any((r) => r.member.name == 'Kabir'), isFalse, reason: 'Kabir has not read this chapter');
  });

  test('unseals when the chapter completes', () {
    final rows = circleRows(data, openKey: 'c142', openNumber: 142, completedOpen: true);
    final asha = rows.firstWhere((r) => r.member.name == 'Asha');
    expect(asha.kind, CircleRowKind.label);
    expect(asha.label, "CHEF'S KISS");
  });

  test('the server seal counts too; labels and short chapter names', () {
    final d = CircleSeriesData(chapters: [
      CircleChapterReactions(chapterKey: 'c142', chapterNumber: 142, sealed: false, by: [ReactionBy.of(m(1, 'Asha'), ReactionKind.loved)]),
    ],);
    expect(circleRows(d, openKey: 'c142', openNumber: 142, completedOpen: false).single.label, 'LOVED');
    expect(chapterShort(142), 'Ch. 142');
    expect(chapterShort(142.5), 'Ch. 142.5');
    expect(reactionLabel(ReactionKind.wrecked), 'WRECKED');
  });

  test('a member on this chapter with no reaction is here', () {
    final d = CircleSeriesData(readers: [CircleReader(member: m(1, 'Asha'), chapterKey: 'c142', chapterNumber: 142)]);
    expect(circleRows(d, openKey: 'c142', openNumber: 142, completedOpen: false).single.kind, CircleRowKind.here);
  });
}
