import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/collections/adder_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/collection_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// "Shared with Aarav", "Shared with Aarav and Mira", "Shared with 3 people".
String sharedWithLine(SharedShelf s) {
  final names = [for (final m in s.shared?.members ?? const <ProfileRef>[]) m.name];
  if (names.isEmpty) return '';
  if (names.length == 1) return 'Shared with ${names.first}';
  if (names.length == 2) return 'Shared with ${names[0]} and ${names[1]}';
  return 'Shared with ${names.length} people';
}

/// A shared shelf as a fanned stack (glass 7.7, 9.3.3): the `bloomRim`, the owner's 24 px orb at the bottom-left for others'
/// shelves, "Shared with …" under the name of this profile's. The count is what the server sent (mature members already left out).
class SharedShelfCard extends ConsumerWidget {
  const SharedShelfCard({super.key, required this.shelf, this.width = 320});
  final SharedShelf shelf;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = shelf.role == 'owner';
    final card = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: gt.colorBloomRim, width: 0.5)),
      child: GlassCollectionCard(
        name: shelf.name,
        count: shelf.seriesCount,
        width: width,
        covers: [for (final u in shelf.previewCovers.take(3)) GlassCoverImage(url: u, width: 96)],
        onTap: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.collection(shelf.id), extra: const GlassNavExtra(presentation: GlassPresentation.page))),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        card,
        if (!mine && shelf.owner != null) Positioned(left: 12, bottom: 12, child: AdderOrb(member: shelf.owner!, size: 24, verb: 'Shared by')),
      ],),
      if (mine && sharedWithLine(shelf).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: GlassText(sharedWithLine(shelf), role: gt.typeFootnote, color: gt.colorLabel2)),
    ],);
  }
}

/// The Shelves tab: others' shelves first, then this profile's shared ones.
List<SharedShelf> shelvesForCircle(({List<SharedShelf> collections, List<SharedShelf> sharedWithMe}) all) => [
      ...all.sharedWithMe,
      for (final c in all.collections) if (c.role == 'owner' && (c.shared?.members.isNotEmpty ?? false)) c,
    ];
