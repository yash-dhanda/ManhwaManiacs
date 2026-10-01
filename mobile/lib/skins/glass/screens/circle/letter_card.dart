import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Literata italic 16/24 for a letter's note (glass 3.4).
TextStyle noteStyle(BuildContext context) => roleStyle(context, gt.typeBody, size: 16, height: 24 / 16).copyWith(fontFamily: 'Literata', fontStyle: FontStyle.italic);

/// The series of a letter in the world-title-card layout: the cover, the title in `title3`, the `bloomRim` and no machine light.
class _SeriesBlock extends StatelessWidget {
  const _SeriesBlock({required this.title, required this.coverUrl});
  final String title;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(gt.radiusMd),
          child: SizedBox(width: 64, height: 96, child: coverUrl == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: coverUrl!, width: 64)),
        ),
        const SizedBox(width: 12),
        Expanded(child: GlassText(title, role: gt.typeTitle3, maxLines: 3, overflow: TextOverflow.ellipsis)),
      ],);
}

/// A received letter (glass 9.3.1): the sender's orb, the series, the note in Literata italic, "Add to library" (secondary;
/// follows, then `read` if it was `new`) and "Not now" (plain; `dismissed`, the card leaves on `springDismiss`). A tap on the
/// card opens the series and sends `read`. A `kept` letter renders as an ordinary read one.
class GlassLetterCard extends ConsumerStatefulWidget {
  const GlassLetterCard({super.key, required this.letter});
  final Letter letter;

  @override
  ConsumerState<GlassLetterCard> createState() => _GlassLetterCardState();
}

class _GlassLetterCardState extends ConsumerState<GlassLetterCard> {
  bool _leaving = false;
  bool _adding = false;

  Letter get l => widget.letter;

  Future<void> _notNow() async {
    setState(() => _leaving = true);
    glassFire(ref, HapticEvent.select);
    await Future<void>.delayed(ref.read(glassReducedProvider) ? Duration.zero : const Duration(milliseconds: 320));
    final ok = await ref.read(lettersProvider.notifier).patch(l.id, LetterState.dismissed);
    if (!ok && mounted) setState(() => _leaving = false);
  }

  Future<void> _add() async {
    setState(() => _adding = true);
    final ok = await followFromCircle(ref, sourceId: l.sourceId, seriesKey: l.seriesKey, title: l.title);
    if (ok) markLetterRead(ref, l);
    if (mounted) setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final unread = l.state == LetterState.newLetter;
    final card = GlassSlab(
      padding: const EdgeInsets.all(16),
      borderColor: gt.colorBloomRim,
      semanticsLabel: '${l.from.name} recommends ${l.title}${unread ? ', new' : ''}',
      onTap: () {
        markLetterRead(ref, l);
        unawaited(openCircleSeries(ref, l.sourceId, l.seriesKey, from: rectOf(context)));
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          CircleOrbButton(member: l.from, size: 32, semanticsLabel: '${l.from.name}, open their Circle page'),
          const SizedBox(width: 8),
          Expanded(child: GlassText(l.from.name, role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: gt.colorBloom, shape: BoxShape.circle)),
        ],),
        const SizedBox(height: 12),
        _SeriesBlock(title: l.title, coverUrl: l.coverUrl),
        if ((l.note ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(l.note!, style: noteStyle(context).copyWith(color: gt.colorLabel1))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          GlassButton(label: 'Add to library', size: GlassButtonSize.small, loading: _adding, onPressed: _adding ? null : () => unawaited(_add())),
          GlassButton(label: 'Not now', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => unawaited(_notNow())),
        ],),
      ],),
    );
    return SpringValue(
      value: _leaving ? 0 : 1,
      spring: _leaving ? gt.springDismiss : gt.springSnappy,
      builder: (context, v, _) => ClipRect(
        child: Align(alignment: Alignment.topCenter, heightFactor: v.clamp(0.0, 1.0), child: Opacity(opacity: v.clamp(0.0, 1.0), child: card)),
      ),
    );
  }
}

/// A sent letter (glass 9.3.1): the recipients' orbs with "Not opened yet" or "Opened", never whether it was added.
class GlassSentLetterCard extends StatelessWidget {
  const GlassSentLetterCard({super.key, required this.letter});
  final SentLetter letter;

  @override
  Widget build(BuildContext context) => GlassSlab(
        padding: const EdgeInsets.all(16),
        borderColor: gt.colorBloomRim,
        semanticsLabel: 'You recommended ${letter.title} to ${[for (final t in letter.to) '${t.name}, ${t.opened ? 'opened' : 'not opened yet'}'].join('; ')}',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          _SeriesBlock(title: letter.title, coverUrl: letter.coverUrl),
          if ((letter.note ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(letter.note!, style: noteStyle(context).copyWith(color: gt.colorLabel2))),
          const SizedBox(height: 12),
          for (final t in letter.to)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                GlassProfileOrb(preset: glassPresetFor(t.avatarKey), size: 24, friend: true, name: t.name),
                const SizedBox(width: 8),
                Expanded(child: GlassText(t.name, role: gt.typeSubhead, maxLines: 1, overflow: TextOverflow.ellipsis)),
                GlassText(t.opened ? 'Opened' : 'Not opened yet', role: gt.typeFootnote, color: t.opened ? gt.colorLabel2 : gt.colorBloom),
              ],),
            ),
        ],),
      );
}
