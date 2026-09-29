import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A section of the Index: a `type.kicker` label over its rows.
class IndexSection extends StatelessWidget {
  const IndexSection({super.key, required this.label, required this.rows});
  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: c.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: CineRoleText(label, c.typeKicker, color: c.colorInk60)),
          SizedBox(height: c.space2),
          ...rows,
        ],
      ),
    );
  }
}
