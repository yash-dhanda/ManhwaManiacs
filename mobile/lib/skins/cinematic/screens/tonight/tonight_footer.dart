import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_keycap.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A 1 px rule and "Issue No. 184 · compiled 21:04 · Refresh R" (cinematic 8.8 "Footer").
class TonightFooter extends StatelessWidget {
  const TonightFooter({super.key, required this.feed});
  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 1, color: c.colorRule1),
      SizedBox(height: c.space3),
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
        CineRoleText('Issue No. ${feed.issueNo} · compiled ${compiledAt(feed)} · Refresh', c.typeCaption, color: c.colorInk45),
        const CineKeycap(keys: [LogicalKeyboardKey.keyR]),
      ],),
      SizedBox(height: c.space10),
    ],);
  }
}
