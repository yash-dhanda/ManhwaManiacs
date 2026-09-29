import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The tablet directory table's column heads (no `LANGUAGE` column): they sit
/// on the same rules as [SourceRow]'s KIND and health cells, so every mark and
/// status reads down one column like a festival listing. Phones render none.
class SourceTableHead extends StatelessWidget {
  const SourceTableHead({super.key});

  /// Widths shared with the row cells.
  static const kindWidth = 72.0;
  static const healthWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return const SizedBox.shrink();
    final t = context.cine;
    TextStyle head() => cineText(context, t.typeFolio, color: t.colorInk45);
    return ExcludeSemantics(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: CineSpace.s2),
            child: Row(
              children: [
                const SizedBox(width: 32 + CineSpace.s3),
                Expanded(child: Text('SOURCE', style: head())),
                SizedBox(width: kindWidth, child: Text('KIND', style: head())),
                SizedBox(width: healthWidth, child: Text('HEALTH', style: head())),
                const SizedBox(width: 6 + CineSpace.s2 + 48 + 48),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: t.colorRule1),
        ],
      ),
    );
  }
}
