import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `CHARACTERS IN THIS STORY` and credits rows: `Kim Dokja ........ the reader`.
class RecapCastList extends StatelessWidget {
  const RecapCastList({super.key, required this.cast});
  final List<RecapCast> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(header: true, child: CineRoleText('CHARACTERS IN THIS STORY', c.typeKicker, color: c.colorInk45)),
      SizedBox(height: c.space2),
      for (final m in cast) CineCreditsRow(label: m.name, value: m.role.isEmpty ? '—' : m.role),
    ],);
  }
}
