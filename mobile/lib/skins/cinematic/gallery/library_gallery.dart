import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/read_state.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/book_list_row.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The gallery section of the Library's parts (mobile/09): every wall poster state, the tight
/// 72 px list row and the book list row. Fixture data only.
const List<String> kLibraryGallerySections = ['library'];

FollowedSeries _series(int i, {bool fav = false, String status = 'reading', int? fresh, bool started = true, String rating = 'safe'}) => FollowedSeries(
      id: i + 1,
      sourceId: 'gallery',
      seriesKey: 'gallery-$i',
      title: galleryTitle(i),
      coverUrl: '',
      isFavorite: fav,
      readingStatus: status,
      notify: false,
      sortOrder: i,
      contentRating: rating,
      rating: rating,
      chapterCount: 40,
      readState: ReadState(started: started, chapterNumber: started ? 12 : null, position: started ? 12 : null, total: 40, latestNumber: 40, newCount: fresh),
    );

class LibraryGallerySection extends StatelessWidget {
  const LibraryGallerySection({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget tag(String s) => Padding(padding: EdgeInsets.only(top: c.space4, bottom: c.space2), child: CineRoleText(s, c.typeKicker, color: c.colorInk45));
    Widget poster(String key, FollowedSeries s, {ShelfDensity density = ShelfDensity.wall, bool gate = false, bool saved = false, bool selectMode = false, bool selected = false, Widget? handle, int i = 0}) => SizedBox(
          width: 96,
          child: LibraryPoster(
            key: Key(key),
            series: s,
            coverUrl: galleryCover(i),
            density: density,
            gateOpen: gate,
            saved: saved,
            selectMode: selectMode,
            selected: selected,
            heroTag: false,
            dragHandle: handle,
            onTap: () {},
            onQuickLook: () {},
            onFavourite: () {},
            onNotify: () {},
          ),
        );
    return Padding(
      key: const Key('gallery-library'),
      padding: EdgeInsets.only(top: c.space10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineRoleText('LIBRARY', c.typeKicker, color: c.colorInk60),
        tag('WALL posters: new count, favourite at rest, status, saved, certificate'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          poster('g-lib-new', _series(0, fresh: 3), saved: true),
          poster('g-lib-fav', _series(1, fav: true, fresh: 0), i: 1),
          poster('g-lib-hold', _series(2, status: 'on_hold', fresh: 0), i: 2),
          poster('g-lib-unread', _series(3, status: 'unread', started: false), i: 3),
          poster('g-lib-mature', _series(4, rating: 'mature', fresh: 12), gate: true, i: 4),
        ],),
        tag('COMPACT: no caption, only the NEW badge'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < 4; i++) SizedBox(width: 64, child: poster('g-lib-compact-$i', _series(i, fresh: i == 0 ? 2 : null), density: ShelfDensity.compact, i: i)),
        ],),
        tag('select mode and manual order handle'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          poster('g-lib-select-off', _series(0), selectMode: true),
          poster('g-lib-select-on', _series(1), selectMode: true, selected: true, i: 1),
          poster('g-lib-handle', _series(2), handle: const CineWallHandle(), i: 2),
        ],),
        tag('LIST rows: 72 px, a 48 x 72 cover'),
        for (var i = 0; i < 2; i++)
          LibraryListRow(
            key: Key('g-row-lib-list-$i'),
            series: _series(i, fresh: i == 0 ? 3 : 0),
            index: i,
            coverUrl: galleryCover(i),
            wide: false,
            now: kGalleryEvening,
            selectMode: false,
            selected: false,
            reorder: false,
            offline: false,
            onTap: () {},
            onSelect: (_) {},
            onQuickLook: () {},
            onFavourite: () {},
            onNotify: () {},
          ),
        tag('the tight row shell: no vertical padding, the divider painted over'),
        const CineRowShell(key: Key('g-row-lib-tight'), tight: true, minHeight: 72, child: SizedBox(height: 72, child: Center(child: Text('72 px')))),
        tag('book list rows'),
        const BookListRow(key: Key('g-row-lib-book'), title: 'The Long Tide', author: 'Ines Vale', credits: '412 CHAPTERS · ONGOING · NOVEL ARCHIVE', blurb: 'A salt trader walks the old road between two drowned cities, and every well she passes has a different story.', note: '42% · CH 212'),
        const BookListRow(key: Key('g-row-lib-book-plain'), title: 'Ember Ledger', credits: '88 CHAPTERS · NOVEL ARCHIVE'),
      ],),
    );
  }
}
