import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A notice across four columns (phones) or six of eight (tablets), under a hub tab's toolbar.
class HubNoticeBox extends StatelessWidget {
  const HubNoticeBox({super.key, required this.notice});
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

/// The notice for a load that failed: `OFFLINE EDITION` for a network error, `SLOW DOWN` with the
/// live retry for a 429, else `CORRECTION`.
class HubErrorNotice extends StatelessWidget {
  const HubErrorNotice({
    super.key,
    required this.error,
    required this.offlineHeadline,
    required this.errorHeadline,
    required this.onRetry,
    this.errorDeck = "The server didn't answer.",
    this.offlineDeck,
    this.offlineExtra,
  });

  final Object error;
  final String offlineHeadline, errorHeadline, errorDeck;
  final String? offlineDeck;
  final VoidCallback onRetry;

  /// An extra quiet action for the offline notice.
  final CineNoticeAction? offlineExtra;

  @override
  Widget build(BuildContext context) {
    final e = error;
    if (e is NetworkError) {
      return HubNoticeBox(
        notice: CineNotice(
          key: const Key('hub-offline'),
          tone: CineNoticeTone.offline,
          kicker: 'OFFLINE EDITION',
          headline: offlineHeadline,
          deck: offlineDeck,
          primary: CineNoticeAction('Try again', onRetry),
          quiet: offlineExtra,
        ),
      );
    }
    if (e is ApiError && e.statusCode == 429) {
      return HubNoticeBox(
        notice: CineNotice(
          key: const Key('hub-rate-limit'),
          tone: CineNoticeTone.rateLimit,
          kicker: 'SLOW DOWN',
          headline: 'Too many requests.',
          retryAfter: e.retryAfter ?? const Duration(seconds: 10),
          onRetry: onRetry,
        ),
      );
    }
    return HubNoticeBox(
      notice: CineNotice(
        key: const Key('hub-error'),
        tone: CineNoticeTone.error,
        kicker: 'CORRECTION',
        headline: errorHeadline,
        deck: errorDeck,
        primary: CineNoticeAction('Try again', onRetry),
      ),
    );
  }
}

/// [count] greeked rows after the 120 ms wait (a hub tab's loading state).
class HubGalley extends StatelessWidget {
  const HubGalley({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) => Column(children: [for (var i = 0; i < count; i++) const CineRow(loading: true, title: '')]);
}

/// One entry of a hub tab's hardware-key group: a single key, or one with modifiers.
ShortcutEntry hubKey(
  String group,
  LogicalKeyboardKey key,
  String description,
  VoidCallback onInvoke, {
  bool shift = false,
  bool alt = false,
  bool single = true,
  List<String>? keys,
}) =>
    ShortcutEntry(
      group: group,
      activator: SingleActivator(key, shift: shift, alt: alt),
      description: description,
      singleKey: single && !shift && !alt,
      keys: keys,
      onInvoke: onInvoke,
    );

/// "just now", "12 min ago", "3 h ago", "2 d ago".
String agoWords(DateTime at, DateTime now) {
  final gap = now.difference(at);
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inMinutes < 60) return '${gap.inMinutes} min ago';
  if (gap.inHours < 24) return '${gap.inHours} h ago';
  return '${gap.inDays} d ago';
}

/// How long a programmatic scroll (a focus move by key) takes: 240 ms, and none under reduced motion.
Duration hubScroll(BuildContext context) => CineMotion.reduced(context) ? Duration.zero : CineDur.line;
