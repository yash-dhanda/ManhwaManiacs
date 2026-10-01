import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart'
    show RecapCast;
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart'
    show GlassGlyph28;
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Each word fades in over this long as it arrives (glass 4.10, Word stream; no movement).
const Duration kWordFade = Duration(milliseconds: 120);

/// Words of a streaming section, each fading in over [kWordFade] from the moment it first shows (reduced motion: at once).
class StreamingWords extends ConsumerStatefulWidget {
  const StreamingWords(this.words, {super.key, this.role});
  final List<String> words;
  final GlassTypeRole? role;

  @override
  ConsumerState<StreamingWords> createState() => _StreamingWordsState();
}

class _StreamingWordsState extends ConsumerState<StreamingWords>
    with SingleTickerProviderStateMixin {
  final List<Duration> _born = [];
  Duration _now = Duration.zero;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      _now = d;
      if (_born.isNotEmpty && _now - _born.last >= kWordFade) _ticker.stop();
      if (mounted) setState(() {});
    });
    _stamp();
  }

  void _stamp() {
    while (_born.length < widget.words.length) {
      _born.add(_now);
    }
    if (_born.isNotEmpty &&
        !_ticker.isActive &&
        !ref.read(glassMotionPrefsProvider).reduced) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(StreamingWords old) {
    super.didUpdateWidget(old);
    final before = _born.length;
    if (widget.words.length > before) {
      _stamp();
      if (!_ticker.isActive && !ref.read(glassMotionPrefsProvider).reduced) {
        unawaited(_ticker.start().then((_) {}, onError: (_) {}));
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final style = GlassTypeStyle.style(context, widget.role ?? gt.typeCallout)
        .copyWith(color: gt.colorLabel1);
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.words.length; i++) {
      final age = reduced || i >= _born.length ? kWordFade : _now - _born[i];
      final a = (age.inMicroseconds / kWordFade.inMicroseconds).clamp(0.0, 1.0);
      spans.add(TextSpan(
          text: i == 0 ? widget.words[i] : ' ${widget.words[i]}',
          style: style.copyWith(color: style.color!.withValues(alpha: a)),),);
    }
    return Semantics(
        label: widget.words.join(' '),
        excludeSemantics: true,
        child: Text.rich(TextSpan(children: spans),
            textScaler: TextScaler.noScaling,),);
  }
}

/// One card of the deck: radius 26, `surface1`, the 0.5 px `machineRim`; [brightness] is the black overlay of a card behind.
class DeckCardFrame extends StatelessWidget {
  const DeckCardFrame(
      {super.key,
      required this.title,
      required this.child,
      this.overlay = 0,
      this.onTap,});
  final String title;
  final Widget child;
  final double overlay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  color: gt.colorSurface1,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: gt.colorMachineRim, width: 0.5),),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                        header: true,
                        headingLevel: 2,
                        child: GlassText(title, role: gt.typeTitle3),),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
            if (overlay > 0)
              Positioned.fill(
                  child: IgnorePointer(
                      child: ColoredBox(
                          color: const Color(0xFF000000)
                              .withValues(alpha: overlay),),),),
          ],
        ),
      );
}

class _Lines extends StatelessWidget {
  const _Lines();
  @override
  Widget build(BuildContext context) => const GlassSkeletonGroup(
      ai: true,
      label: 'Writing your recap',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassSkeleton(height: 14, radius: 7),
        SizedBox(height: 10),
        GlassSkeleton(height: 14, radius: 7),
        SizedBox(height: 10),
        GlassSkeleton(width: 180, height: 14, radius: 7),
      ],),);
}

/// The body of a section: skeleton lines until its first word, then the words.
Widget sectionBody(DeckSection? s, {bool bullets = false}) {
  if (s == null || s.text.trim().isEmpty) return const _Lines();
  if (!bullets) return StreamingWords(s.words);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final b in sectionBullets(s.text))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: GlyphIcon(GlassGlyph28.drop,
                    size: 12, color: gt.colorMachine,),),
            Expanded(
                child: StreamingWords(
                    b.split(' ').where((w) => w.isNotEmpty).toList(),),),
          ],),
        ),
    ],
  );
}

/// Who's who: up to 6 rows with a 24 px orb (the speaker's hue for a novel's cast, else `g700`).
Widget castBody(List<RecapCast> cast, {Color? Function(String name)? hueOf}) {
  if (cast.isEmpty) return const _Lines();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final c in cast.take(6))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                  decoration: BoxDecoration(
                      color: hueOf?.call(c.name) ?? gt.colorG700,
                      shape: BoxShape.circle,),
                  child: const SizedBox(width: 24, height: 24),),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    GlassText(c.name, role: gt.typeHeadline),
                    if (c.role.isNotEmpty)
                      GlassText(c.role,
                          role: gt.typeFootnote, color: gt.colorLabel2,),
                  ],),),
            ],
          ),
        ),
    ],
  );
}

/// The four sections in order with their titles.
const List<(String, String)> kDeckKinds = [
  ('left_off', 'Where you left off'),
  ('happened', 'What happened'),
  ('cast', "Who's who"),
  ('threads', 'Open threads'),
];

String deckTitleOf(String kind, DeckState s) => s.sections
            .where((x) => x.kind == kind)
            .map((x) => x.title)
            .firstOrNull
            ?.trim()
            .isNotEmpty ??
        false
    ? s.sections.firstWhere((x) => x.kind == kind).title
    : kDeckKinds.firstWhere((k) => k.$1 == kind, orElse: () => (kind, kind)).$2;

Widget deckBodyFor(String kind, DeckState s, {Color? Function(String name)? hueOf}) {
  final sec = s.sections.where((x) => x.kind == kind).firstOrNull;
  return switch (kind) {
    'happened' || 'threads' => sectionBody(sec, bullets: true),
    'cast' => castBody(s.done?.cast ?? const [], hueOf: hueOf),
    _ => sectionBody(sec),
  };
}

/// The AI stamp line of a card or footer: sparkle plus text.
Widget aiLine(String text, {bool streaming = false}) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2, right: 6),
          child: MachineBadge(streaming: streaming, size: 12),),
      Expanded(
          child: GlassText(text, role: gt.typeFootnote, color: gt.colorLabel3),),
    ],);
