import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/similar_rails.dart';

/// `03 MORE LIKE THIS`: the Similar rail, the fallback and the Because you read rail (cinematic 9.1.4).
class MoreLikeThisPanel extends StatelessWidget {
  const MoreLikeThisPanel({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        key: const PageStorageKey('more-like-this'),
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            sliver: SliverToBoxAdapter(child: SimilarRails(sourceId: data.sourceId, seriesKey: data.seriesKey, title: data.title)),
          ),
        ],
      );
}
