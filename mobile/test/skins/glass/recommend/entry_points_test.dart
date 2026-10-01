import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_card_face.dart';

import '../primitives/support.dart';

void main() {
  testWidgets('Wrapped card 4 carries "Recommend" for the #1 series; other cards and exports do not', (t) async {
    registerRecommendSheets();
    const a = Annual(year: 2026, topSeries: [ShareSeries(sourceId: 's', seriesKey: 'solo', title: 'Solo Leveling')]);
    Widget face(WrappedCard c, {bool live = true}) => primHost(WrappedCardFace(card: c, annual: a, active: false, reduced: true, profileName: 'Yash', onExport: live ? () {} : null));
    await t.pumpWidget(face(WrappedCard.topFive));
    await pumpFor(t, 300);
    expect(find.text('Recommend'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpWidget(face(WrappedCard.topFive, live: false));
    await pumpFor(t, 300);
    expect(find.text('Recommend'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpWidget(face(WrappedCard.time));
    await pumpFor(t, 300);
    expect(find.text('Recommend'), findsNothing);
  });
}
