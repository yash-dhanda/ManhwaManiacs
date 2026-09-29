import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_feature_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `NEW THIS WEEK`, `BECAUSE YOU READ`, `FROM THE CIRCLE`, `ALMOST THERE` by kind (cinematic 8.8).
String alsoKicker(HomeAlsoKind k) => switch (k) {
      HomeAlsoKind.newChapters => 'NEW THIS WEEK',
      HomeAlsoKind.because => 'BECAUSE YOU READ',
      HomeAlsoKind.letter => 'FROM THE CIRCLE',
      HomeAlsoKind.almostThere => 'ALMOST THERE',
    };

AmbientRoles? _roles(Ambient? a) => a == null ? null : AmbientRoles(duo: a.duo, tint: a.tint, ink: a.ink);

/// Also in this issue: three Feature cards as a pager on phones (`viewportFraction` 0.86, a folio
/// and two ruled arrow buttons), 2 + 1 on tablets. Two cards make a pager of two; one or none are
/// not rendered. A rebuild of this row while the header scrubs would be a bug: it never watches the
/// scroll.
class AlsoInThisIssue extends ConsumerStatefulWidget {
  const AlsoInThisIssue({super.key, required this.env});
  final TonightEnv env;

  @override
  ConsumerState<AlsoInThisIssue> createState() => _AlsoState();
}

class _AlsoState extends ConsumerState<AlsoInThisIssue> {
  final PageController _pager = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pager.addListener(() {
      final p = _pager.hasClients ? (_pager.page ?? 0).round() : 0;
      if (p != _page && mounted) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _go(int page, int count) {
    final to = page.clamp(0, count - 1);
    if (CineMotion.reduced(context)) {
      _pager.jumpToPage(to);
    } else {
      _pager.animateToPage(to, duration: CineDur.column, curve: CineCurves.settle);
    }
  }

  void _open(HomeAlso a) {
    if (a.kind == HomeAlsoKind.letter) {
      context.go(Routes.circle());
    } else if (a.sourceId != null && a.seriesKey != null) {
      openSeries(context, a.sourceId!, a.seriesKey!);
    }
  }

  Widget _card(HomeAlso a, int i) => CineAmbient(
        ambient: _roles(a.ambient),
        child: CineFeatureCard(
          title: a.headline,
          kicker: alsoKicker(a.kind),
          deck: a.deck,
          imageUrl: coverAbs(ref, a.coverPath),
          ambientKicker: a.ambient != null,
          heroTag: widget.env.tags.of('also:$i'),
          onTap: () => _open(a),
        ),
      );

  double _cardHeight(BuildContext context, double width) {
    final c = context.cine;
    final image = width * 5 / 4;
    final kicker = measureText(context, 'NEW THIS WEEK', c.typeKicker, width, maxLines: 1);
    final head = measureText(context, 'Headline\nHeadline', c.typeSubhead, width, maxLines: 2);
    final deck = measureText(context, 'Deck\nDeck', c.typeBodyItalic, width, maxLines: 2);
    return image + c.space3 + kicker + c.space1 + head + c.space1 + deck + 8;
  }

  @override
  Widget build(BuildContext context) {
    final also = widget.env.feed.also;
    if (also.length < 2) return const SizedBox.shrink();
    final c = context.cine;
    final wide = tonightWide(context);
    final grid = CineGrid.of(context);
    if (wide) {
      final w = grid.span(4);
      return Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: Wrap(spacing: grid.gutter, runSpacing: 32, children: [
          for (var i = 0; i < also.length; i++) SizedBox(width: w, child: _card(also[i], i)),
        ],),
      );
    }
    final pageW = MediaQuery.sizeOf(context).width * 0.86;
    final h = _cardHeight(context, pageW - 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            key: const Key('tonight-also-pager'),
            controller: _pager,
            itemCount: also.length,
            itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _card(also[i], i)),
          ),
        ),
        SizedBox(height: c.space3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CineIconButton(
            key: const Key('tonight-also-prev'),
            label: 'Previous card',
            role: CineIconRole.back,
            variant: CineIconButtonVariant.ruled,
            onPressed: _page > 0 ? () => _go(_page - 1, also.length) : null,
          ),
          SizedBox(width: c.space4),
          CineRoleText('${math.min(_page + 1, also.length)} / ${also.length}', c.typeFolio, color: c.colorInk45),
          SizedBox(width: c.space4),
          CineIconButton(
            key: const Key('tonight-also-next'),
            label: 'Next card',
            codepoint: CineGlyph.arrowRight,
            variant: CineIconButtonVariant.ruled,
            onPressed: _page < also.length - 1 ? () => _go(_page + 1, also.length) : null,
          ),
        ],),
      ],),
    );
  }
}
