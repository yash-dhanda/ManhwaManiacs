
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/page_pile.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_frame.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show avatarPresetFor;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_figures.dart';

/// Covers on screen: the live authenticated image, or the dark box when the URL is missing.
Widget liveCover(String? url, double w, double h, double radius) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: w, height: h, child: url == null ? const ColoredBox(color: Color(0xFF1A1A20)) : GlassCoverImage(url: url, width: w)),
    );

Widget liveOrb(String name, double size) => GlassProfileOrb(preset: avatarPresetFor(null), size: size, name: name.isEmpty ? null : name);

/// The ground colour of a card: the top cover's duotone when there is one, else `iris900`.
Color cardGround(Annual a) {
  final duo = a.topSeries.firstOrNull?.ambient?.duo;
  final v = duo != null && duo.length == 7 ? int.tryParse(duo.substring(1), radix: 16) : null;
  return v == null ? gt.colorIris900 : Color(0xFF000000 | v);
}

/// One Wrapped card in the 360 x 640 frame (glass 9.2.3): the slots, the count-up, the page pile and the podium drop that start when the
/// card becomes [active], the flame that flares once, and the Export capsule. [reduced] shows every final state at once.
class WrappedCardFace extends ConsumerStatefulWidget {
  const WrappedCardFace({super.key, required this.card, required this.annual, required this.active, required this.reduced, required this.profileName, this.onExport, this.reflow = false, this.togetherName, this.togetherTitle});
  final WrappedCard card;
  final Annual annual;
  final bool active;
  final bool reduced;
  final String profileName;
  final VoidCallback? onExport;

  /// Large text: the same slots as a reflowing column, scrolled vertically.
  final bool reflow;
  final String? togetherName;
  final String? togetherTitle;

  @override
  ConsumerState<WrappedCardFace> createState() => _WrappedCardFaceState();
}

class _WrappedCardFaceState extends ConsumerState<WrappedCardFace> with SingleTickerProviderStateMixin {
  Ticker? _tickerOrNull;
  Ticker get _ticker => _tickerOrNull ??= createTicker(_tick);
  double _ms = 0;
  PagePile? _pile;
  int _flare = 0;


  @override
  void initState() {
    super.initState();
    if (widget.card == WrappedCard.volume) {
      _pile = PagePile(pages: widget.annual.pagesRead, size: const Size(312, 200));
      if (widget.reduced) _pile!.settle();
    }
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(WrappedCardFace old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
  }

  void _start() {
    if (widget.reduced) {
      _ms = 100000;
      _pile?.settle();
      return;
    }
    _ms = 0;
    if (widget.card == WrappedCard.streak) _flare++;
    if (!_ticker.isActive) _ticker.start();
  }

  Duration _last = Duration.zero;

  void _tick(Duration e) {
    final dt = _last == Duration.zero ? 1 / 60 : (e - _last).inMicroseconds / 1e6;
    _last = e;
    _ms += dt * 1000;
    _pile?.step(dt);
    if (_ms > 4000 && (_pile?.asleep ?? true)) {
      _ticker.stop();
      _last = Duration.zero;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tickerOrNull?.dispose();
    super.dispose();
  }

  FigureInput _input() {
    final final_ = widget.reduced || !widget.active;
    // A card that is not the current one shows its final state, the current one animates.
    final p = final_ ? 1.0 : Curves.easeOutCubic.transform((_ms / 1200).clamp(0.0, 1.0));
    return FigureInput(
      card: widget.card,
      annual: widget.annual,
      cover: liveCover,
      progress: p,
      podiumMs: final_ ? 100000 : _ms,
      pile: final_ ? (_pile?..settle()) : _pile,
      flame: widget.card == WrappedCard.streak ? StreakFlame(size: 220, state: FlameState.litToday, days: widget.annual.longestStreak.days, flare: _flare) : null,
      orb: liveOrb,
      lens: (logo) => SkinGlass(tier: GlassTierId.t2, size: const Size(96, 96), layer: GlassLayerKind.overlays, debugLabel: 'wrapped-source-lens', child: logo),
      togetherName: widget.togetherName,
      togetherTitle: widget.togetherTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.annual;
    final copy = wrappedCopy(widget.card, a, profileName: widget.profileName, togetherName: widget.togetherName, togetherTitle: widget.togetherTitle);
    final cover = widget.card == WrappedCard.cover;
    final italics = switch (widget.card) {
      WrappedCard.firstsLasts => [firstsLastsTitles(a).first, firstsLastsTitles(a).last],
      WrappedCard.together => [widget.togetherTitle ?? ''],
      _ => const <String>[],
    };
    final headline = italics.isNotEmpty
        ? _ItalicTitles(copy.headline, italics)
        : cover
        ? TypedHeadline(copy.headline, role: gt.typeDisplay, placement: 'wrapped.cover', headingLevel: 1, textAlign: TextAlign.center)
        : LetterReveal(copy.headline, role: gt.typeTitle1, screenId: 'wrapped', revealKey: '${a.year}-${widget.card.name}', maxLines: 3, textAlign: TextAlign.center, headingLevel: 2);
    final eyebrow = GlassLabel(copy.eyebrow, role: gt.typeCaption1, color: gt.colorLabel2, upper: true, extraTrackingEm: 0.18, textAlign: TextAlign.center);
    final figure = wrappedFigure(_input());
    final foot = copy.footnote.isEmpty ? const SizedBox.shrink() : GlassLabel(copy.footnote, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2, textAlign: TextAlign.center);
    final export = widget.onExport == null
        ? null
        : SizedBox(width: 104, height: 44, child: GlassButton(label: widget.card == WrappedCard.summary ? 'Share your year' : 'Export', size: GlassButtonSize.small, twin: GlassTwin.onGlass, onPressed: widget.onExport));
    if (widget.reflow) {
      return _Column(ground: cardGround(a), eyebrow: eyebrow, headline: headline, figure: figure, foot: foot, export: export);
    }
    return SizedBox(
      width: kWrappedFrame.width,
      height: kWrappedFrame.height,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -0.3), radius: 1.1, colors: [cardGround(a).withValues(alpha: 0.5), const Color(0x00000000)])))),
        Positioned.fromRect(rect: WrappedSlots.eyebrow, child: Align(child: eyebrow)),
        Positioned.fromRect(rect: cover ? WrappedSlots.coverHeadline : WrappedSlots.headline, child: Align(alignment: Alignment.topCenter, child: headline)),
        Positioned.fromRect(rect: WrappedSlots.figure, child: figure),
        Positioned.fromRect(rect: WrappedSlots.footnote, child: Align(child: foot)),
        if (export != null) Positioned.fromRect(rect: WrappedSlots.export, child: export),
      ],),
    );
  }
}

/// The reflowing column of large text (glass 3.3 rule 5): the same slots stacked, the text at the scaled size, the figure scaled to the
/// width (`wrappedNumeral` unscaled inside it), scrolling vertically.
class _Column extends StatelessWidget {
  const _Column({required this.ground, required this.eyebrow, required this.headline, required this.figure, required this.foot, required this.export});
  final Color ground;
  final Widget eyebrow;
  final Widget headline;
  final Widget figure;
  final Widget foot;
  final Widget? export;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -0.6), radius: 1.2, colors: [ground.withValues(alpha: 0.5), const Color(0x00000000)])),
        child: SingleChildScrollView(
          key: const ValueKey('wrapped-column'),
          padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            eyebrow,
            const SizedBox(height: 8),
            headline,
            const SizedBox(height: 24),
            AspectRatio(aspectRatio: 312 / 304, child: FittedBox(child: MediaQuery.withNoTextScaling(child: figure))),
            const SizedBox(height: 16),
            foot,
            if (export != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerRight, child: export)],
          ],),
        ),
      );
}


/// Cards 9 and 11 set the series titles in italic (glass 9.2.3), so their headline is one rich text; it shows at once.
class _ItalicTitles extends StatelessWidget {
  const _ItalicTitles(this.text, this.titles);
  final String text;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final style = roleStyle(context, gt.typeTitle1, maxScale: 1).copyWith(color: gt.colorLabel1);
    final spans = <TextSpan>[];
    var rest = text;
    for (final t in titles.where((t) => t.isNotEmpty)) {
      final at = rest.indexOf(t);
      if (at < 0) continue;
      spans
        ..add(TextSpan(text: rest.substring(0, at)))
        ..add(TextSpan(text: t, style: const TextStyle(fontStyle: FontStyle.italic)));
      rest = rest.substring(at + t.length);
    }
    spans.add(TextSpan(text: rest));
    return Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Text.rich(TextSpan(style: style, children: spans), maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, textScaler: TextScaler.noScaling),
    );
  }
}
