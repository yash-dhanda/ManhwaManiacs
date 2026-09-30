import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/similar_rails.dart';

/// The chapter-end credits' More like this (cinematic 8.14.6): the caught-up notice's rail, the
/// same data as the series page's tab (Similar, with the same-genre fallback when the desk is
/// closed). The end of a Completed series shows the `Up next` chain instead
/// (`features/ai/utils/up_next_chain.dart`).
///
/// TODO(mobile/12): mount in the manga reader's credits (caught up, and the end).
class CreditsMoreLikeThis extends StatelessWidget {
  const CreditsMoreLikeThis({super.key, required this.sourceId, required this.seriesKey, required this.title});
  final String sourceId, seriesKey, title;

  @override
  Widget build(BuildContext context) => SimilarRails(sourceId: sourceId, seriesKey: seriesKey, title: title, heading: 'More like this', because: false);
}
