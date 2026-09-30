import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/progress_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/top_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';

/// The bottom bar (cinematic 8.15.3): previous chapter, the progress folio, next chapter, and a
/// 1 px progress hairline along the top edge in the stock ink. `mobile/23` adds the auto-scroll
/// button through [trailing].
class NovelBottomBar extends StatelessWidget {
  const NovelBottomBar({
    super.key,
    required this.stock,
    required this.progress,
    required this.folio,
    required this.onPrevious,
    required this.onNext,
    this.trailing = const [],
  });

  final CineStockColors stock;

  /// 0-1 along the chapter, for the hairline.
  final double progress;
  final Widget folio;
  final VoidCallback? onPrevious, onNext;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          NovelBar(
            stock: stock,
            top: false,
            child: Row(
              children: [
                CineIconButton(label: 'Previous chapter', role: CineIconRole.chapterPrevious, onPressed: onPrevious),
                Expanded(child: Center(child: folio)),
                CineIconButton(label: 'Next chapter', role: CineIconRole.chapterNext, onPressed: onNext),
                ...trailing,
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 1,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: ColoredBox(key: const Key('novel-progress-hairline'), color: stock.ink),
            ),
          ),
        ],
      );
}

/// A convenience: the folio with the value the bar needs, so the screen can hold its state key.
NovelProgressFolio novelFolio({
  required GlobalKey<NovelProgressFolioState> key,
  required CineStockColors stock,
  required int chapterPercent,
  required int minutesLeft,
  required ValueChanged<int> onGoTo,
  int? bookPercent,
  ValueChanged<bool>? onEditingChanged,
}) =>
    NovelProgressFolio(
      key: key,
      stock: stock,
      chapterPercent: chapterPercent,
      bookPercent: bookPercent,
      minutesLeft: minutesLeft,
      onGoTo: onGoTo,
      onEditingChanged: onEditingChanged,
    );

/// The top bar's action buttons in order (contents, bookmark, type, margins), for the screen and
/// the hit-target test. [extra] entries are inserted after the bookmark.
List<Widget> novelTopActions({
  required VoidCallback onContents,
  required VoidCallback onBookmark,
  required bool bookmarked,
  required VoidCallback onType,
  VoidCallback? onMargins,
  bool marginsOpen = false,
  List<Widget> afterBookmark = const [],
}) =>
    [
      CineIconButton(label: 'Contents', role: CineIconRole.contents, onPressed: onContents),
      CineIconButton(label: bookmarked ? 'Bookmarked' : 'Bookmark this spot', role: CineIconRole.bookmark, selected: bookmarked, onPressed: onBookmark),
      ...afterBookmark,
      CineIconButton(label: 'Text and page', role: CineIconRole.type, onPressed: onType),
      if (onMargins != null) CineIconButton(label: 'Margins', codepoint: 0xe34c, selected: marginsOpen, onPressed: onMargins),
    ];
