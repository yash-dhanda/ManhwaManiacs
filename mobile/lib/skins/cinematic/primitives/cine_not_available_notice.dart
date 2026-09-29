import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Content that is no longer available (cinematic 8.0.10): kicker `NOT IN THIS ISSUE`, a typed
/// headline, a deck and two actions. Removed and 18+-gated content answer the same codes, so the
/// wording never reveals which.
class CineNotAvailableNotice extends StatelessWidget {
  const CineNotAvailableNotice({super.key, required this.kind, this.title, this.sourceId});

  final NotAvailableKind kind;

  /// The series title when known: `Search for it` opens Discover with it prefilled.
  final String? title;

  /// For [NotAvailableKind.notBrowsable]: the source `Search it` scopes Discover to.
  final String? sourceId;

  @override
  Widget build(BuildContext context) {
    final (headline, deck) = switch (kind) {
      NotAvailableKind.series => ("This series isn't available here any more.", 'It may have been removed from its source.'),
      NotAvailableKind.source => ("This source isn't available here any more.", 'It may have been removed from its source.'),
      NotAvailableKind.notBrowsable => ('This source can only be searched, not browsed.', null),
    };
    CineNoticeAction? quiet;
    if (kind == NotAvailableKind.notBrowsable) {
      quiet = CineNoticeAction('Search it', () {
        GoRouter.of(context).go(Routes.discover({'scope': sourceId == null ? null : 'sources'}));
      });
    } else if (title != null && title!.isNotEmpty) {
      quiet = CineNoticeAction('Search for it', () => GoRouter.of(context).go(Routes.discover({'q': title})));
    }
    return CineNotice(
      tone: CineNoticeTone.empty,
      kicker: 'NOT IN THIS ISSUE',
      wholeScreen: true,
      headline: headline,
      deck: deck,
      primary: CineNoticeAction('Back to Tonight', () => goSection(context, 0)),
      quiet: quiet,
    );
  }
}
