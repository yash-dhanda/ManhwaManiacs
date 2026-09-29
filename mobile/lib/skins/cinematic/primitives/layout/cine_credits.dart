import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Credit rows (cinematic 7.28): a label (`typeCreditLabel`, `ink.45`) and a value (`typeCredit`).
/// One column below 600 px and at text scale >= 1.3; from 600 px two columns with a 1 px `rule.1`
/// column rule between them.
class CineCredits extends StatelessWidget {
  const CineCredits({super.key, required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final two = MediaQuery.sizeOf(context).width >= 600 && !CineReflow.of(context).railCompact;
    Widget row((String, String) r) => Padding(
          padding: EdgeInsets.symmetric(vertical: c.space1),
          child: Semantics(
            container: true,
            label: '${r.$1}: ${r.$2}',
            excludeSemantics: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              CineRoleText(r.$1, c.typeCreditLabel, color: c.colorInk45),
              CineRoleText(r.$2, c.typeCredit),
            ],),
          ),
        );
    if (!two) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [for (final r in rows) row(r)]);
    final half = (rows.length + 1) ~/ 2;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final r in rows.take(half)) row(r)])),
        Container(width: 1, margin: EdgeInsets.symmetric(horizontal: c.space4), color: c.colorRule1),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final r in rows.skip(half)) row(r)])),
      ],),
    );
  }
}
