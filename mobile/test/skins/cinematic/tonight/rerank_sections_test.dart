import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';

HomeSection _rail(HomeSectionType t, String genre, {String title = 'x'}) => HomeSection(
      type: t,
      title: title,
      items: [HomePickItem(world: WorldItem(title: 'A', genres: [genre]))],
    );

void main() {
  final feed = HomeFeed(headline: 'h', deck: 'd', sections: [
    _rail(HomeSectionType.picked, 'Action', title: 'Picked'),
    _rail(HomeSectionType.because, 'Romance', title: 'Because'),
    _rail(HomeSectionType.popular, 'Fantasy', title: 'Popular'),
  ],);

  List<String> order(List<String> noted) => [for (final p in planSections(feed, noted: noted)) p.section.title];

  test('without notes the server order stands', () {
    expect(order(const []), ['Picked', 'Because', 'Popular']);
  });

  test('a genre opened from a rail moves its rail up one place; folios stay gapless', () {
    expect(order(const ['Fantasy']), ['Picked', 'Popular', 'Because']);
    expect([for (final p in planSections(feed, noted: const ['Fantasy'])) p.folio], ['01', '02', '03']);
  });

  test('the newest note applies last; an unknown genre changes nothing', () {
    expect(order(const ['Romance', 'Fantasy']), ['Because', 'Popular', 'Picked']);
    expect(order(const ['Horror']), ['Picked', 'Because', 'Popular']);
  });

  test('a rail never moves above Continue', () {
    final withContinue = HomeFeed(headline: 'h', deck: 'd', sections: [
      const HomeSection(type: HomeSectionType.continueReading, title: 'Continue', items: [HomePickItem(world: WorldItem(title: 'C', genres: ['Action']))]),
      _rail(HomeSectionType.picked, 'Action', title: 'Picked'),
    ],);
    final r = planSections(withContinue, noted: const ['Action']);
    expect(r.first.section.title, 'Continue');
  });
}
