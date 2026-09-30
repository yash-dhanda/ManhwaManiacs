import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Newsreader Italic 22 for the byline (`CineType.literal`).
TextStyle bookLiteral(Color color, {double size = 22}) => TextStyle(
      fontFamily: 'Newsreader',
      fontStyle: FontStyle.italic,
      fontSize: size,
      color: color,
    );

/// The cover plate: square-cornered, 1 px `rule.2`; without a cover the
/// Bodoni initial on `paper.1`. 96 x 144 on phones, 168 x 248 on tablets.
class CoverPlate extends StatelessWidget {
  const CoverPlate({super.key, required this.title, required this.wide, this.url, this.heroTag});
  final String title;
  final bool wide;
  final String? url;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final initial = Center(
      child: Text(
        title.isEmpty ? '' : title[0],
        style: TextStyle(fontFamily: 'BodoniModa', fontSize: 48, color: t.colorInk100),
      ),
    );
    Widget plate = Container(
      key: const Key('cover-plate'),
      width: wide ? 168 : 96,
      height: wide ? 248 : 144,
      decoration: BoxDecoration(color: t.colorPaper1, border: Border.all(color: t.colorRule2)),
      child: url == null
          ? initial
          : Image.network(url!, fit: BoxFit.cover, errorBuilder: (c, e, s) => initial),
    );
    if (heroTag != null) {
      plate = Hero(
        tag: heroTag!,
        transitionOnUserGestures: Theme.of(context).platform == TargetPlatform.iOS,
        child: plate,
      );
    }
    return plate;
  }
}

/// Phone and tablet front matter: kicker, title (Bodoni masthead, letters set),
/// byline, the 56 px rule that draws after it, facts, estimate note, and the
/// blurb with its drop cap set last, collapsed to five lines with `More`.
class BookFrontMatter extends StatefulWidget {
  const BookFrontMatter({
    super.key,
    required this.kicker,
    required this.title,
    required this.byline,
    required this.facts,
    required this.estimateNote,
    required this.blurb,
    required this.genres,
    required this.sourceId,
    required this.onCover,
    this.coverUrl,
    this.heroTag,
  });

  final String kicker;
  final String title;
  final String? byline;
  final String facts;
  final String? estimateNote;
  final String? blurb;
  final List<String> genres;
  final String sourceId;
  final String? coverUrl;
  final Object? heroTag;
  final VoidCallback onCover;

  @override
  State<BookFrontMatter> createState() => _BookFrontMatterState();
}

class _BookFrontMatterState extends State<BookFrontMatter> with SingleTickerProviderStateMixin {
  // 0 - .35 byline, .35 - .60 rule, .60 - 1 drop cap; the title sets first.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  Timer? _timer;
  bool _more = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _timer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) unawaited(_c.forward());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final amb = CineAmbient.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final titleStyle = CineType.style(context, t.typeMasthead).copyWith(color: t.colorInk100);
    final titleSize = setHeadingSize(widget.title, [titleStyle.fontSize!, titleStyle.fontSize! * 0.8, titleStyle.fontSize! * 0.6]);
    final blurb = widget.blurb;
    final long = blurb != null && blurb.length > 220;
    final text = blurb;
    final body = CineType.style(context, t.typeBody).copyWith(color: t.colorInk80);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetHeading(widget.title, id: 'book-${widget.title}', cap: t.typeMasthead.cap, level: 1, trigger: SetTrigger.signal, style: titleStyle.copyWith(fontSize: titleSize)),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Opacity(
            opacity: _seg(0, 0.35),
            child: widget.byline == null
                ? const SizedBox.shrink()
                : Text(widget.byline!, style: bookLiteral(t.colorInk80)),
          ),
        ),
      ],
    );

    final plate = GestureDetector(
      onLongPress: widget.onCover,
      child: CoverPlate(
        title: widget.title,
        wide: wide,
        url: widget.coverUrl,
        heroTag: widget.heroTag,
      ),
    );

    final Widget head = wide
        ? SizedBox(
            height: 320,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text(widget.kicker, style: kickerStyle(context, color: amb.ink)), const SizedBox(height: 8), left],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.coverUrl != null)
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: 56, sigmaY: 56),
                            child: Image.network(widget.coverUrl!,
                                fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox(),),
                          ),
                        ),
                      ColoredBox(color: amb.duo.withValues(alpha: 0.75)),
                      Center(child: plate),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.kicker, style: kickerStyle(context, color: amb.ink)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: left), const SizedBox(width: 12), plate],
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Container(
            key: const Key('title-rule'),
            width: 56 * _seg(0.35, 0.6, CineCurves.settle),
            height: 1,
            color: t.colorInk100,
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.facts, style: kickerStyle(context)),
        if (widget.estimateNote != null)
          Text(widget.estimateNote!, style: TextStyle(fontSize: 12, color: t.colorInk60)),
        if (text != null) ...[
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Opacity(
              opacity: _seg(0.6, 1),
              child: _Collapsed(
                collapsed: long && !_more,
                child: DropCapParagraph(
                  text: text,
                  style: body,
                  capStyle: CineType.dropcap(24).copyWith(color: t.colorInk100),
                ),
              ),
            ),
          ),
          if (long)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => setState(() => _more = !_more),
              child: Text(_more ? 'Less' : 'More'),
            ),
        ],
        Wrap(
          spacing: 8,
          children: [
            for (final g in widget.genres)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => context
                    .push('/sources/${widget.sourceId}?genre=${Uri.encodeQueryComponent(g)}'),
                child: Text(g.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Five 24 px lines of [child], the rest clipped, until expanded.
class _Collapsed extends StatelessWidget {
  const _Collapsed({required this.collapsed, required this.child});
  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!collapsed) return child;
    return SizedBox(
      key: const Key('blurb-collapsed'),
      height: 120,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
