import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A notice across four columns (phones) or six of eight (tablets), under the toolbar.
class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.notice});
  final Widget notice;

  @override
  Widget build(BuildContext context) {
    final grid = CineGrid.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, 32, grid.right, 48),
      child: Align(alignment: Alignment.topLeft, child: SizedBox(width: wide ? grid.span(6) : double.infinity, child: notice)),
    );
  }
}

/// `EMPTY SHELF`: nothing followed yet.
class ShelfEmptyNotice extends StatelessWidget {
  const ShelfEmptyNotice({super.key, required this.novels, required this.onFind});
  final bool novels;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) => _NoticeBox(
        notice: CineNotice(
          key: const Key('shelf-empty'),
          tone: CineNoticeTone.empty,
          kicker: 'EMPTY SHELF',
          headline: novels ? 'No books on your shelf yet.' : 'Nothing on your shelf yet.',
          deck: novels ? 'Add a book from a novel source and it lands here.' : 'Follow a series from Discover and it lands here.',
          primary: CineNoticeAction('Find something', onFind),
        ),
      );
}

/// `NOTHING MATCHES` with filters on and no search text.
class ShelfFilteredEmpty extends StatelessWidget {
  const ShelfFilteredEmpty({super.key, required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => _NoticeBox(
        notice: CineNotice(
          key: const Key('shelf-filtered-empty'),
          tone: CineNoticeTone.empty,
          kicker: 'NOTHING MATCHES',
          headline: 'No series match these filters.',
          primary: CineNoticeAction('Clear filters', onClear),
        ),
      );
}

/// `NOTHING MATCHES` for a search: try every source, or clear the search.
class ShelfSearchEmpty extends StatelessWidget {
  const ShelfSearchEmpty({super.key, required this.onSearchAll, required this.onClearSearch});
  final VoidCallback onSearchAll, onClearSearch;

  @override
  Widget build(BuildContext context) => _NoticeBox(
        notice: CineNotice(
          key: const Key('shelf-search-empty'),
          tone: CineNoticeTone.empty,
          kicker: 'NOTHING MATCHES',
          headline: 'Nothing on your shelf matches that.',
          deck: 'Try another title, or search every source.',
          primary: CineNoticeAction('Search every source', onSearchAll),
          quiet: CineNoticeAction('Clear search', onClearSearch),
        ),
      );
}

/// The offline edition's banner strip (cinematic 7.29): only saved series are shown.
class ShelfOfflineBanner extends StatelessWidget {
  const ShelfOfflineBanner({super.key, required this.onDownloads});
  final VoidCallback onDownloads;

  @override
  Widget build(BuildContext context) => CineBannerStrip(
        key: const Key('shelf-offline-banner'),
        kicker: 'OFFLINE EDITION',
        line: 'Only series saved on this device are shown.',
        actions: [CineBannerAction('Go to Downloads', onDownloads)],
      );
}

/// Offline with nothing saved.
class ShelfOfflineEmpty extends StatelessWidget {
  const ShelfOfflineEmpty({super.key, required this.onDownloads});
  final VoidCallback onDownloads;

  @override
  Widget build(BuildContext context) => _NoticeBox(
        notice: CineNotice(
          key: const Key('shelf-offline-empty'),
          tone: CineNoticeTone.offline,
          kicker: 'OFFLINE EDITION',
          headline: 'Your shelf needs a connection.',
          deck: 'Saved chapters still open from Downloads.',
          primary: CineNoticeAction('Go to Downloads', onDownloads),
        ),
      );
}

/// `CORRECTION`: the shelf did not load and nothing is saved to show instead.
class ShelfError extends StatelessWidget {
  const ShelfError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _NoticeBox(
        notice: CineNotice(
          key: const Key('shelf-error'),
          tone: CineNoticeTone.error,
          headline: "Your shelf didn't load.",
          deck: "The server didn't answer. Saved chapters still open.",
          primary: CineNoticeAction('Try again', onRetry),
        ),
      );
}

/// A refresh failed after data had loaded: a caption line above the wall, the wall stays.
class ShelfPageError extends StatelessWidget {
  const ShelfPageError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, c.space2, grid.right, c.space2),
      child: Row(key: const Key('shelf-page-error'), children: [
        Expanded(child: CineRoleText("Couldn't refresh your shelf.", c.typeCaption, color: c.colorProof)),
        CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onRetry),
      ],),
    );
  }
}

/// "Showing the first 200 of 212 — narrow it with search or a filter."
class ShelfOverflowNote extends StatelessWidget {
  const ShelfOverflowNote({super.key, required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, c.space2, grid.right, c.space2),
      child: CineRoleText('Showing the first 200 of $total — narrow it with search or a filter.', c.typeCaption, color: c.colorInk60),
    );
  }
}

/// The galley proof of the wall (cinematic 7.17): 12 (WALL), 24 (COMPACT) or 8 (LIST) flickering
/// plates or greeked rows, after 120 ms of waiting.
class ShelfGalley extends StatelessWidget {
  const ShelfGalley({super.key, required this.density, required this.novels});
  final ShelfDensity density;
  final bool novels;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    Widget body;
    if (novels || density == ShelfDensity.list) {
      body = Column(children: [for (var i = 0; i < 8; i++) const CineRow(loading: true, title: '')]);
    } else {
      final g = ShelfGeometry.of(context, density);
      final n = density == ShelfDensity.compact ? 24 : 12;
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: g.delegate,
          itemCount: n,
          itemBuilder: (context, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 2 / 3, child: CineFlicker(index: i, child: const CineGalleyPlate())),
            if (density != ShelfDensity.compact) ...[
              SizedBox(height: c.space2),
              CineGalleyLine(lineHeight: roleLineHeight(context, c.typeTitle), index: i),
            ],
          ],),
        ),
      );
    }
    return Padding(
      key: const Key('shelf-galley'),
      padding: EdgeInsets.fromLTRB(novels || density == ShelfDensity.list ? 0 : grid.left, 8, novels || density == ShelfDensity.list ? 0 : grid.right, 24),
      child: CineDelayed(child: body),
    );
  }
}
