import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Written 2 d ago" (a cached recap), null for a fresh one.
String? writtenAgo(DateTime? savedAt, DateTime now) {
  if (savedAt == null) return null;
  final d = now.difference(savedAt);
  if (d.inHours < 1) return 'Written just now';
  if (d.inHours < 24) return 'Written ${d.inHours} h ago';
  return 'Written ${d.inDays} d ago';
}

/// The spoiler-guard footer (glass 9.1.3): who wrote it, from which chapters, and that nothing past where the reader stopped is in it.
String footerText(DeckDone done, {DateTime? savedAt, required DateTime now}) {
  final range = done.rangeLabel;
  final covered = done.coveredThrough ?? done.to;
  String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  final b = StringBuffer();
  b.write(done.model.isEmpty ? 'Written' : 'Written by ${done.model}');
  if (range != null) b.write(' from chapters $range');
  b.write('.');
  if (covered != null) b.write(' Covers up to chapter ${n(covered)}.');
  b.write(' Nothing after where you stopped.');
  final ago = writtenAgo(savedAt, now);
  if (ago != null) b.write(' $ago.');
  return b.toString();
}

class RecapFooter extends StatelessWidget {
  const RecapFooter({super.key, required this.done, this.savedAt, required this.now, this.onGlass = false});
  final DeckDone done;
  final DateTime? savedAt;
  final DateTime now;
  final bool onGlass;

  @override
  Widget build(BuildContext context) {
    final text = footerText(done, savedAt: savedAt, now: now);
    return Semantics(
      label: '$text, suggested by AI',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 2, right: 6), child: MachineBadge(size: 12)),
          Expanded(child: GlassText(text, role: gt.typeFootnote, color: onGlass ? gt.colorOnGlass : gt.colorLabel3, onGlass: onGlass)),
        ],
      ),
    );
  }
}
