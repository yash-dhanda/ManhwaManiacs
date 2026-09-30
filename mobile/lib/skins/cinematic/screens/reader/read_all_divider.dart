import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The divider between two chapters of the read-all strip (cinematic 8.14.5): a 48 px band with
/// `142 → 143` in `type.folio` between `rule.1` hairlines. No card and no pause.
class ReadAllDivider extends StatelessWidget {
  const ReadAllDivider({super.key, required this.from, required this.to});

  /// The chapter numbers (`142`, `143`).
  final String from, to;

  static const double extent = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: 'Chapter $from ends. Chapter $to begins.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: extent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: c.space4),
            child: Row(
              children: [
                Expanded(child: SizedBox(height: 1, child: ColoredBox(color: c.colorRule1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CineRoleText('$from → $to', c.typeFolio, color: c.colorInk60),
                ),
                Expanded(child: SizedBox(height: 1, child: ColoredBox(color: c.colorRule1))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
