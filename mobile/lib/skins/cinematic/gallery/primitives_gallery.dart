import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/primitives.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Every section id of the gallery, in page order.
const List<String> kGallerySections = [
  'buttons',
  'icon-buttons',
  'fields',
  'search',
  'slug-lines',
  'cards',
  'posters',
  'rails',
  'galleys',
  'progress',
  'badges',
  'avatars',
  'keycaps',
  'masthead',
  'layout',
  'grain-duotone',
  'reveals',
  'motion-timings',
];

/// The Diagnostics-only primitives gallery (mobile/04): one section per primitive with every
/// variant and prop-driven state side by side, fixture data only. [section] renders one section.
class CinePrimitivesGalleryPage extends StatelessWidget {
  const CinePrimitivesGalleryPage({super.key, this.section});
  final String? section;

  @override
  Widget build(BuildContext context) {
    final theme = CinematicSkin.baseTheme.copyWith(splashFactory: NoSplash.splashFactory, highlightColor: const Color(0x00000000));
    return Theme(
      data: theme,
      child: CineContrastScope(
        child: CineMotionScope(
          child: CineTextSettings(
            child: ScrollConfiguration(behavior: const CineScrollBehavior(), child: _GalleryBody(section: section)),
          ),
        ),
      ),
    );
  }
}

class _GalleryBody extends ConsumerStatefulWidget {
  const _GalleryBody({this.section});
  final String? section;

  @override
  ConsumerState<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends ConsumerState<_GalleryBody> {
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ids = widget.section == null ? kGallerySections : [widget.section!];
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CineButton(
                  key: const Key('g-gallery-close'),
                  label: 'Close',
                  variant: CineButtonVariant.quiet,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              for (final id in ids) KeyedSubtree(key: ValueKey('$id-$_replay'), child: _section(context, id)),
            ],),
          ),
        ),
        const Positioned.fill(child: CineGridOverlay()),
        if (ref.watch(motionTimingsOverlayProvider)) const Positioned(left: 8, bottom: 8, child: CineMotionTimingsPanel()),
      ],),
    );
  }

  Widget _section(BuildContext context, String id) {
    return switch (id) {
      'buttons' => _buttons(context),
      'icon-buttons' => _iconButtons(context),
      'fields' => _fields(context),
      'search' => _search(context),
      'slug-lines' => _slugLines(context),
      'cards' => _cards(context),
      'posters' => _posters(context),
      'rails' => _rails(context),
      'galleys' => _galleys(context),
      'progress' => _progress(context),
      'badges' => _badges(context),
      'avatars' => _avatars(context),
      'keycaps' => _keycaps(context),
      'masthead' => _masthead(context),
      'layout' => _layout(context),
      'grain-duotone' => _grainDuotone(context),
      'reveals' => _reveals(context),
      'motion-timings' => _timings(context),
      _ => const SizedBox.shrink(),
    };
  }

  // ---- helpers ----

  Widget _sec(BuildContext context, String id, String title, List<Widget> children) {
    final c = context.cine;
    return Padding(
      key: Key('gallery-$id'),
      padding: EdgeInsets.only(top: c.space10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineRoleText('GALLERY · ${title.toUpperCase()}', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        const CineRuleDraw(kind: CineRuleKind.heavy),
        SizedBox(height: c.space4),
        ...children,
      ],),
    );
  }

  Widget _tag(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: CineRoleText(text, context.cine.typeCaption, color: context.cine.colorInk45),
      );

  Widget _wrap(List<Widget> children) => Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: children);

  // ---- sections ----

  Widget _buttons(BuildContext context) {
    final c = context.cine;
    return _sec(context, 'buttons', 'Buttons', [
      _tag(context, 'primary lg / md / sm'),
      _wrap([
        const CineButton(key: Key('g-button-primary-lg'), label: 'Start reading', size: CineButtonSize.lg, onPressed: _noop),
        const CineButton(key: Key('g-button-primary-md'), label: 'Continue', onPressed: _noop),
        const CineButton(key: Key('g-button-primary-sm'), label: 'Open', size: CineButtonSize.sm, onPressed: _noop),
      ]),
      _tag(context, 'split (folio button)'),
      const CineButton(key: Key('g-button-split'), label: 'Continue', variant: CineButtonVariant.split, folio: 'CH 143 · p.12', onPressed: _noop),
      _tag(context, 'secondary, quiet, destructive, link'),
      _wrap([
        const CineButton(key: Key('g-button-secondary'), label: 'Add to library', variant: CineButtonVariant.secondary, onPressed: _noop),
        const CineButton(key: Key('g-button-quiet'), label: 'Not now', variant: CineButtonVariant.quiet, onPressed: _noop),
        const CineButton(key: Key('g-button-destructive'), label: 'Delete download', variant: CineButtonVariant.destructive, onPressed: _noop),
        const CineButton(key: Key('g-button-link'), label: 'Read the terms', variant: CineButtonVariant.link, onPressed: _noop),
      ]),
      _tag(context, 'onArt, play 56 / mini 36'),
      const SizedBox(
        height: 120,
        child: Stack(fit: StackFit.expand, children: [
          CineImage(url: 'assets/gallery/covers/17-petal-almanac.webp'),
          Positioned(left: 12, bottom: 12, child: CineButton(key: Key('g-button-onart'), label: 'Trailer', variant: CineButtonVariant.onArt, onPressed: _noop)),
          Positioned(
            right: 12,
            bottom: 12,
            child: Row(children: [
              CineButton(key: Key('g-button-play'), label: 'Play', variant: CineButtonVariant.play, icon: CineIconRole.play, onPressed: _noop),
              SizedBox(width: 12),
              CineButton(key: Key('g-button-play-mini'), label: 'Pause', variant: CineButtonVariant.play, size: CineButtonSize.sm, icon: CineIconRole.pause, onPressed: _noop),
            ],),
          ),
        ],),
      ),
      _tag(context, 'states: disabled, loading, selected, error, caught up'),
      _wrap([
        const CineButton(key: Key('g-button-disabled'), label: 'Download', onPressed: null, disabledReason: 'Connect to a source first'),
        const CineButton(key: Key('g-button-loading'), label: 'Sign in', loadingLabel: 'Signing in…', loading: true, onPressed: _noop),
        const CineButton(key: Key('g-button-selected'), label: 'Following', variant: CineButtonVariant.secondary, toggle: true, selected: true, onPressed: _noop),
        const CineButton(key: Key('g-button-error'), label: 'Retry', errorText: 'The server didn’t answer.', onPressed: _noop),
        const CineButton(key: Key('g-button-caught-up'), label: 'All caught up', leadingGlyph: CineGlyph.check, onPressed: null),
      ]),
      SizedBox(height: c.space2),
    ]);
  }

  Widget _iconButtons(BuildContext context) => _sec(context, 'icon-buttons', 'Icon buttons and tooltips', [
        _tag(context, 'bare, onArt, ruled, badged'),
        _wrap([
          const CineIconButton(key: Key('g-iconbutton-bare'), label: 'Search', role: CineIconRole.search, onPressed: _noop, shortcut: [LogicalKeyboardKey.slash]),
          Container(
            color: const Color(0xFFB8B2A4),
            padding: const EdgeInsets.all(8),
            child: const CineIconButton(key: Key('g-iconbutton-onart'), label: 'Share', role: CineIconRole.share, variant: CineIconButtonVariant.onArt, onPressed: _noop),
          ),
          const CineIconButton(key: Key('g-iconbutton-ruled'), label: 'Zoom in', role: CineIconRole.zoomIn, variant: CineIconButtonVariant.ruled, onPressed: _noop),
          const CineIconButton(key: Key('g-iconbutton-badged'), label: 'Updates, 3 new', role: CineIconRole.updates, variant: CineIconButtonVariant.badged, count: 3, onPressed: _noop),
        ]),
        _tag(context, 'states: disabled, loading, selected, error'),
        _wrap([
          const CineIconButton(key: Key('g-iconbutton-disabled'), label: 'Download', role: CineIconRole.download, onPressed: null),
          const CineIconButton(key: Key('g-iconbutton-loading'), label: 'Refresh', role: CineIconRole.refresh, loading: true, onPressed: _noop),
          const CineIconButton(key: Key('g-iconbutton-selected'), label: 'Bookmark', role: CineIconRole.bookmark, selected: true, onPressed: _noop, shortcut: [LogicalKeyboardKey.keyB]),
          const CineIconButton(key: Key('g-iconbutton-error'), label: 'Favourite', role: CineIconRole.favourite, errorReason: 'Could not save. Try again.', onPressed: _noop),
        ]),
      ]);

  Widget _fields(BuildContext context) => _sec(context, 'fields', 'Fields', [
        const CineTextField(
          key: Key('g-field-text'),
          label: 'USERNAME',
          hint: 'name',
          helperText: 'Lower case, no spaces.',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autofillHints: [AutofillHints.username],
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 16),
        const CineTextField(key: Key('g-field-email'), label: 'EMAIL', initialValue: 'reader@example.test', keyboardType: TextInputType.emailAddress, autofillHints: [AutofillHints.email], textInputAction: TextInputAction.next),
        const SizedBox(height: 16),
        const CineTextField(key: Key('g-field-url'), label: 'SERVER ADDRESS', hint: 'https://', keyboardType: TextInputType.url, autofillHints: [AutofillHints.url], textInputAction: TextInputAction.go, autocorrect: false),
        const SizedBox(height: 16),
        const CinePasswordField(key: Key('g-field-password'), label: 'PASSWORD', hint: 'at least eight characters', textInputAction: TextInputAction.done),
        const SizedBox(height: 16),
        const CineNumberField(key: Key('g-field-number'), label: 'DAILY GOAL', unit: 'min', helperText: 'Minutes read each day.'),
        const SizedBox(height: 16),
        const CineTextarea(key: Key('g-field-textarea'), label: 'NOTE', hint: 'Write a line or two.'),
        _tag(context, 'states: error, disabled, loading, success'),
        const CineTextField(key: Key('g-field-error'), label: 'EMAIL', initialValue: 'not an address', errorText: 'That is not an email address.'),
        const SizedBox(height: 16),
        const CineTextField(key: Key('g-field-disabled'), label: 'SERVER', initialValue: 'locked', enabled: false),
        const SizedBox(height: 16),
        const CineTextField(key: Key('g-field-loading'), label: 'USERNAME', initialValue: 'checking', loading: true),
        const SizedBox(height: 16),
        const CineTextField(key: Key('g-field-success'), label: 'SERVER', initialValue: 'connected', success: true),
      ]);

  Widget _search(BuildContext context) => _sec(context, 'search', 'Search', [
        const CineSearchField(key: Key('g-search-index'), semanticLabel: 'Search every source', placeholder: 'Search every source'),
        const SizedBox(height: 24),
        const CineSearchField(key: Key('g-search-compact'), variant: CineSearchVariant.compact, semanticLabel: 'Search or jump', placeholder: 'Search or jump'),
      ]);

  final Set<String> _single = {'reading'};
  final Set<String> _multi = {'romance', 'action'};
  int _seg = 0;
  CineTriState _tri1 = CineTriState.neutral, _tri2 = CineTriState.include, _tri3 = CineTriState.exclude;

  Widget _slugLines(BuildContext context) => _sec(context, 'slug-lines', 'Slug lines, segments, tri-state', [
        _tag(context, 'single-select'),
        CineSlugLines(
          key: const Key('g-slug-single'),
          items: const [CineSlug('all', 'All', count: 24), CineSlug('reading', 'Reading', count: 12), CineSlug('plan', 'Plan', count: 5), CineSlug('done', 'Done', disabled: true)],
          selected: _single,
          onChanged: (id) => setState(() => _single
            ..clear()
            ..add(id),),
        ),
        _tag(context, 'multi-select with removable tokens'),
        CineSlugLines(
          key: const Key('g-slug-multi'),
          multi: true,
          items: const [CineSlug('romance', 'Romance'), CineSlug('action', 'Action'), CineSlug('fantasy', 'Fantasy'), CineSlug('tok', 'Completed', removable: true)],
          selected: _multi,
          onChanged: (id) => setState(() => _multi.contains(id) ? _multi.remove(id) : _multi.add(id)),
          onRemove: (_) {},
        ),
        _tag(context, 'loading counts'),
        const CineSlugLines(key: Key('g-slug-loading'), loading: true, items: [CineSlug('a', 'Following', count: 0), CineSlug('b', 'Updates', count: 0)], selected: {'a'}, onChanged: _ignore),
        _tag(context, 'segmented control'),
        CineSegmentedControl(
          key: const Key('g-segmented'),
          labels: const ['STRIP', 'SINGLE', 'DOUBLE'],
          index: _seg,
          onChanged: (i) => setState(() => _seg = i),
          disabledReasons: const {2: 'Double needs a wide screen'},
        ),
        _tag(context, 'tri-state genre filter: neutral, include, exclude'),
        _wrap([
          CineTriStateFilter(key: const Key('g-tri-neutral'), label: 'Romance', value: _tri1, onChanged: (v) => setState(() => _tri1 = v)),
          CineTriStateFilter(key: const Key('g-tri-include'), label: 'Action', value: _tri2, onChanged: (v) => setState(() => _tri2 = v)),
          CineTriStateFilter(key: const Key('g-tri-exclude'), label: 'Horror', value: _tri3, onChanged: (v) => setState(() => _tri3 = v)),
        ]),
      ]);

  static void _ignore(String _) {}

  Widget _cards(BuildContext context) {
    final c = context.cine;
    return _sec(context, 'cards', 'Cards', [
      _tag(context, 'feature: default, loading, error'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: CineFeatureCard(key: const Key('g-card-feature'), title: 'The lamp that would not go out', kicker: 'IN THIS ISSUE', deck: 'A courier, a lantern and a road that keeps moving.', imageUrl: galleryCover(0), onTap: _noop)),
        SizedBox(width: c.space3),
        const Expanded(child: CineFeatureCard(key: Key('g-card-feature-loading'), title: '', loading: true)),
        SizedBox(width: c.space3),
        const Expanded(child: CineFeatureCard(key: Key('g-card-feature-error'), title: 'Night Ward', error: true)),
      ],),
      _tag(context, 'cutting: progress, next, nudges'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: CineCuttingCard(key: const Key('g-card-cutting'), title: 'Ember Ledger', folio: 'CH 142 · 63%', progress: 0.63, nudge: '3 NEW', imageUrl: galleryCover(1), onTap: _noop, onQuickLook: _noop)),
        SizedBox(width: c.space3),
        Expanded(child: CineCuttingCard(key: const Key('g-card-cutting-next'), title: 'Moonlit Bakery', folio: 'NEXT · CH 143', nudge: 'PAUSED 21 D', imageUrl: galleryCover(2), onTap: _noop, onQuickLook: _noop)),
      ],),
      _tag(context, 'world: available, information only, shelf'),
      CineWorldCard(key: const Key('g-card-world-available'), kind: CineWorldKind.available, title: 'Salt and Iron', kicker: 'MANHWA · ONGOING · ★ 8.4', imageUrl: galleryCover(0), why: 'Because you finished three slow-burn road stories this month.', credit: 'ON MANGADEX, ASURA +1', onOpen: _noop, onDismiss: _noop, onLongPress: _noop),
      SizedBox(height: c.space4),
      CineWorldCard(key: const Key('g-card-world-info'), kind: CineWorldKind.infoOnly, title: 'Petal Almanac', kicker: 'MANHWA · COMPLETED', imageUrl: galleryCover(4), duo: const Color(0xFFC46A8B), credit: 'NOT ON YOUR SOURCES', readOnLabel: 'the publisher', onSearchMySources: _noop, onReadOn: _noop),
      SizedBox(height: c.space4),
      CineWorldCard(key: const Key('g-card-world-shelf'), kind: CineWorldKind.shelf, title: 'Night Ward', kicker: 'HARBOUR SOURCE · 88 CHAPTERS', byline: 'M. Verrill', imageUrl: galleryCover(3), why: 'A quiet one for the late show.', onOpen: _noop),
      _tag(context, 'stat block: value, loading'),
      Row(children: [
        const Expanded(child: CineStatBlock(key: Key('g-card-stat'), kicker: 'READ THIS YEAR', value: '312', caption: 'chapters')),
        SizedBox(width: c.space4),
        const Expanded(child: CineStatBlock(key: Key('g-card-stat-loading'), kicker: 'STREAK', value: '', loading: true)),
      ],),
      _tag(context, 'letter'),
      CineLetterCard(key: const Key('g-card-letter'), from: 'Riya', title: 'Glass Tide', note: 'You will love the tower arc.', imageUrl: galleryCover(2), isNew: true, onOpen: _noop, onRead: _noop, onAdd: _noop, onKeep: _noop, onDismiss: _noop),
      _tag(context, 'collection plate: default, selected'),
      CineCollectionPlate(key: const Key('g-card-plate'), name: 'Slow burns', credit: '24 SERIES · SMART · SHARED', coverUrls: [for (var i = 0; i < 4; i++) galleryCover(i)], sharedWith: const ['rose', 'cyan'], onTap: _noop),
      SizedBox(height: c.space3),
      CineCollectionPlate(key: const Key('g-card-plate-selected'), name: 'Night reads', credit: '9 SERIES', coverUrls: [for (var i = 2; i < 6; i++) galleryCover(i)], selected: true, onTap: _noop),
    ]);
  }

  bool _selectMode = false;

  Widget _posters(BuildContext context) => _sec(context, 'posters', 'Posters', [
        _tag(context, 'wall of 24 plates (Rack focus caps at 12)'),
        CinePosterGroup(
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < 24; i++)
              SizedBox(width: 64, child: CinePoster(key: Key('g-poster-wall-$i'), title: galleryTitle(i), url: galleryCover(i), caption: CinePosterCaption.wall, groupIndex: i, onTap: _noop)),
          ],),
        ),
        _tag(context, 'caption below, ranked'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-below'), title: 'Salt and Iron', url: galleryCover(0), folio: 'CH 142 · 3 NEW', onTap: _noop, onQuickLook: _noop, duo: const Color(0xFFC4541C))),
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-favourite'), title: 'Ember Ledger', url: galleryCover(1), folio: 'CAUGHT UP', favourited: true, onTap: _noop)),
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-ranked'), title: 'Night Ward', url: galleryCover(3), caption: CinePosterCaption.ranked, rank: 3, onTap: _noop)),
        ],),
        _tag(context, 'badges, disabled, loading, error, selected'),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-badges'), title: 'Moonlit Bakery', url: galleryCover(2), folio: 'NOT STARTED', badges: [CineBadge.newCount(3, onArt: true), CineBadge.certificate()], onTap: _noop)),
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-disabled'), title: 'Petal Almanac', url: galleryCover(4), disabled: true, onTap: _noop)),
          const SizedBox(width: 96, child: CinePoster(key: Key('g-poster-loading'), title: 'Glass Tide', loading: true)),
          const SizedBox(width: 96, child: CinePoster(key: Key('g-poster-error'), title: 'Cold Orbit', error: true, onTap: _noop, onRetry: _noop)),
        ],),
        _tag(context, 'select mode'),
        CineButton(key: const Key('g-poster-select-toggle'), label: _selectMode ? 'Done' : 'Select', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: () => setState(() => _selectMode = !_selectMode)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-select-off'), title: 'Salt and Iron', url: galleryCover(0), selectMode: _selectMode, onTap: _noop)),
          SizedBox(width: 96, child: CinePoster(key: const Key('g-poster-select-on'), title: 'Ember Ledger', url: galleryCover(1), selectMode: true, selected: true, onTap: _noop)),
        ],),
      ]);

  Widget _rails(BuildContext context) {
    CinePoster item(BuildContext ctx, int i, double w, FocusNode node) =>
        CinePoster(title: galleryTitle(i), url: galleryCover(i), folio: 'CH ${140 + i}', focusNode: node, groupIndex: i, onTap: _noop);
    CineSlateData? slate(int i) => CineSlateData(title: galleryTitle(i), kicker: 'MANHWA · ONGOING · ${40 + i} CHAPTERS', deck: 'A courier, a lantern and a road that keeps moving.', why: 'Picked for your slow-burn streak.', coverUrl: galleryCover(i), onRead: _noop, onAdd: _noop, onDetails: _noop);
    return _sec(context, 'rails', 'Rails', [
      CineRail(key: const Key('g-rail-ready'), headingId: 'g-ready', heading: 'Continue reading', folio: '04', itemCount: 8, itemBuilder: item, slateBuilder: slate, onSeeAll: _noop),
      const SizedBox(height: 32),
      const CineRail(key: Key('g-rail-loading'), headingId: 'g-loading', heading: 'New this week', itemCount: 0, itemBuilder: _none, state: CineRailState.loading, placeholderTitles: ['Salt and Iron', 'Ember Ledger', 'Moonlit Bakery']),
      const SizedBox(height: 32),
      const CineRail(key: Key('g-rail-empty'), headingId: 'g-empty', heading: 'In progress', itemCount: 0, itemBuilder: _none, state: CineRailState.empty, emptyText: 'Nothing in progress. Start something below.'),
      const SizedBox(height: 32),
      const CineRail(key: Key('g-rail-error'), headingId: 'g-error', heading: 'Popular now', itemCount: 0, itemBuilder: _none, state: CineRailState.error, onRetry: _noop),
      const SizedBox(height: 32),
      const CineRail(key: Key('g-rail-ai'), headingId: 'g-ai', heading: 'Picked for you', itemCount: 0, itemBuilder: _none, state: CineRailState.aiUnavailable, aiReason: CineAiReason.budget, fallback: CineRoleTextPlaceholder()),
      const SizedBox(height: 32),
      const CineRail(key: Key('g-rail-ai-slow'), headingId: 'g-ai2', heading: 'Ask the editors', itemCount: 0, itemBuilder: _none, state: CineRailState.aiUnavailable, aiReason: CineAiReason.rateLimited, retryAfterSeconds: 12),
      const SizedBox(height: 32),
      CineRail(key: const Key('g-rail-stale'), headingId: 'g-stale', heading: 'Your shelf', itemCount: 6, itemBuilder: item, staleAgo: '3 H', pickedAgo: '3 DAYS AGO'),
    ]);
  }

  static Widget _none(BuildContext c, int i, double w, FocusNode n) => const SizedBox.shrink();

  Widget _galleys(BuildContext context) => _sec(context, 'galleys', 'Galleys', [
        _tag(context, 'line, headline, plate, numeral'),
        const CineGalleyLine(lineHeight: 24),
        const CineGalleyLine(lineHeight: 24, index: 1),
        const SizedBox(height: 16),
        const CineGalleyHeadline(lineHeight: 32),
        const SizedBox(height: 16),
        const Row(children: [
          SizedBox(width: 96, height: 144, child: CineGalleyPlate(title: 'Night Ward')),
          SizedBox(width: 24),
          CineGalleyNumeral(size: 48),
        ],),
        _tag(context, 'CineDelayed shows after 120 ms'),
        const CineDelayed(child: CineGalleyLine(lineHeight: 24)),
      ]);

  Widget _progress(BuildContext context) => _sec(context, 'progress', 'Progress and marks', [
        _tag(context, 'rule progress 63 %, indeterminate, poster and micro'),
        const CineRuleProgress(value: 0.63),
        const SizedBox(height: 16),
        const CineIndeterminateRule(),
        const SizedBox(height: 16),
        const SizedBox(height: 72, child: Stack(children: [Positioned.fill(child: ColoredBox(color: Color(0xFF121211))), Positioned(left: 0, right: 0, bottom: 0, child: CinePosterProgress(value: 0.4))])),
        const SizedBox(height: 16),
        const SizedBox(height: 24, child: CineMicroProgress(value: 0.25)),
        _tag(context, 'leader dial 32 / 24 / 16 / 12, countdown, folio counter'),
        _wrap([
          const CineLeaderDial(showAfter: Duration.zero),
          const CineLeaderDial(size: 24, showAfter: Duration.zero),
          const CineLeaderDial(size: 16, showAfter: Duration.zero),
          const CineLeaderDial(size: 12, showAfter: Duration.zero),
          const CineCountdownDial(),
          const CineFolioCounter(index: 7, total: 40),
        ]),
        _tag(context, 'download marks'),
        _wrap([
          for (final s in CineDownloadState.values) CineDownloadMark(key: Key('g-download-${s.name}'), state: s, progress: 0.3, onTap: _noop),
        ]),
        _tag(context, 'storage meter'),
        const CineStorageMeter(key: Key('gallery-storage'), otherGb: 2.4, appGb: 1.7, totalGb: 10, capGb: 8, note: 'The 10 GB cap is close.'),
      ]);

  Widget _badges(BuildContext context) => _sec(context, 'badges', 'Badges', [
        _wrap([
          CineBadge.newCount(null),
          CineBadge.newCount(3),
          CineBadge.newCount(120),
          CineBadge.status('Ongoing'),
          CineBadge.status('Completed'),
          CineBadge.reading('reading'),
          CineBadge.reading('plan_to_read'),
          CineBadge.certificate(),
          CineBadge.certificate(large: true),
          const CineBadge('SAVED', variant: CineBadgeVariant.saved),
          const CineBadge('EPUB', variant: CineBadgeVariant.text),
          CineBadge.stale('3 H'),
          const CineBadge('PICKED', variant: CineBadgeVariant.picked),
          CineBadge.pickedAgo('3 DAYS AGO'),
          const CineBadge('SMART', variant: CineBadgeVariant.smart),
          const CineBadge('SHARED', variant: CineBadgeVariant.shared),
          const CineBadge('NOW', variant: CineBadgeVariant.now),
          CineBadge.count(7),
          CineBadge.count(150),
          const CineBadge('ADMIN', variant: CineBadgeVariant.admin),
          const CineBadge('YOU', variant: CineBadgeVariant.you),
          const CineBadge('DEACTIVATED', variant: CineBadgeVariant.deactivated),
        ]),
      ]);

  Widget _avatars(BuildContext context) => _sec(context, 'avatars', 'Avatars', [
        _tag(context, 'the twelve presets'),
        _wrap([for (final p in kAvatarPresets) CineAvatar(key: Key('g-avatar-${p.key}'), avatarKey: p.key, semanticName: p.name, onTap: _noop)]),
        _tag(context, 'sizes'),
        _wrap([for (final s in kAvatarSizes.take(7)) CineAvatar(avatarKey: 'lunar', size: s)]),
        _tag(context, 'selected, 18+, reading now'),
        _wrap([
          const CineAvatar(key: Key('g-avatar-selected'), avatarKey: 'ember', size: 56, selected: true, onTap: _noop),
          const CineAvatar(avatarKey: 'phantom', size: 56, adult: true),
          const CineReadingNowRing(duo: Color(0xFFC4541C), tooltip: 'Reading Omniscient Reader · CH 212', child: CineAvatar(avatarKey: 'rose')),
          const CineReadingNowRing(child: CineAvatar(avatarKey: 'cyan')),
        ]),
      ]);

  Widget _keycaps(BuildContext context) => _sec(context, 'keycaps', 'Keycaps', [
        _wrap([
          const CineKeycap(keys: [LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK]),
          const CineKeycap(keys: [LogicalKeyboardKey.control, LogicalKeyboardKey.keyK]),
          const CineKeycap(keys: [LogicalKeyboardKey.escape]),
          const CineKeycap(keys: [LogicalKeyboardKey.keyB], secondary: true),
          const CineKeycap(keys: [LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp]),
        ]),
      ]);

  Widget _masthead(BuildContext context) => _sec(context, 'masthead', 'Masthead, rules, mood grade', [
        const CineMasthead(kicker: 'No. 02 — YOUR SHELF', title: 'Library', deck: '24 series, 3 with new chapters.'),
        const CineOxfordRule(spotLead: true),
        const SizedBox(height: 24),
        const CineSectionHeader(headingId: 'g-section', heading: 'Also in this issue', folio: '03', onSeeAll: _noop),
        _tag(context, 'mood grades'),
        for (final m in const ['romantic', 'action', 'fantasy'])
          SizedBox(
            height: 96,
            child: CineMoodGrade(mood: m, child: Padding(padding: const EdgeInsets.all(12), child: CineRoleText('Mood: $m', context.cine.typeDeck))),
          ),
      ]);

  Widget _layout(BuildContext context) {
    final grid = CineGrid.of(context);
    return _sec(context, 'layout', 'Grid, measure, credits, spread', [
      CineRoleText('${grid.columns} columns · margin ${grid.left.toStringAsFixed(0)} · gutter ${grid.gutter.toStringAsFixed(0)} · column ${grid.colWidth.toStringAsFixed(1)}', context.cine.typeCaption, color: context.cine.colorInk60),
      _tag(context, 'measure 62 ch, baseline snapped'),
      CineMeasure(ch: 62, style: CineText.style(context, context.cine.typeBody), baseline: true, child: CineRoleText('A body column is capped at sixty-two characters of its own zero, so a line never runs longer than a reader can follow across a wide screen.', context.cine.typeBody)),
      _tag(context, 'credits'),
      const CineCredits(rows: [('AUTHOR', 'M. Verrill'), ('ARTIST', 'S. Okafor'), ('STATUS', 'Ongoing'), ('SOURCES', 'Harbour, Ledger')]),
      _tag(context, 'spread'),
      CineSpread(
        text: CineRoleText('Salt and Iron', context.cine.typeHeadline),
        artBuilder: (_) => const CineImage(url: 'assets/gallery/covers/01-salt-and-iron.webp'),
      ),
    ]);
  }

  Widget _grainDuotone(BuildContext context) => _sec(context, 'grain-duotone', 'Grain and duotone', [
        _tag(context, 'grain over a cover (0.06), and over mid grey'),
        Row(children: [
          const Expanded(child: SizedBox(height: 180, child: CineGrain(child: CineImage(url: 'assets/gallery/covers/07-moonlit-bakery.webp')))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 180, child: CineGrain(opacity: 0.2, child: ColoredBox(color: context.cine.colorInk60)))),
        ],),
        _tag(context, 'duotone: black to the duo colour'),
        Row(children: [
          for (final d in const [Color(0xFFB8B2A4), Color(0xFFC4541C), Color(0xFF3F8FB5)]) ...[
            Expanded(child: SizedBox(height: 140, child: CineDuotone(duo: d, child: const CineImage(url: 'assets/gallery/covers/02-ember-ledger.webp')))),
            const SizedBox(width: 8),
          ],
        ],),
      ]);

  Widget _reveals(BuildContext context) {
    final c = context.cine;
    return _sec(context, 'reveals', 'Reveals', [
      Align(
        alignment: Alignment.centerLeft,
        child: CineButton(
          key: const Key('g-reveals-replay'),
          label: 'Replay',
          variant: CineButtonVariant.quiet,
          onPressed: () {
            ref.read(seenHeadingsProvider.notifier).state = <String>{};
            setState(() => _replay++);
          },
        ),
      ),
      _tag(context, 'Letter set: per-letter fade, rise and un-blur'),
      SetHeading(
        'Transmigration of a lantern',
        id: 'gallery-reveal-1',
        style: CineText.style(context, c.typeHeadline).copyWith(color: c.colorInk100),
        cap: c.typeHeadline.cap,
        level: 2,
        trigger: SetTrigger.mount,
      ),
      const SizedBox(height: 16),
      SetHeading(
        'Library',
        id: 'gallery-reveal-2',
        style: CineText.style(context, c.typeSection).copyWith(color: c.colorInk100),
        cap: c.typeSection.cap,
        level: 2,
        linked: true,
        trigger: SetTrigger.mount,
      ),
      _tag(context, 'Type: one grapheme per 50 ms, tap to skip'),
      TypedHeadline('Twelve days and counting. One chapter keeps it alive.', style: CineText.style(context, c.typeHeadline).copyWith(color: c.colorInk100), cap: c.typeHeadline.cap, level: 2),
    ]);
  }

  Widget _timings(BuildContext context) => _sec(context, 'motion-timings', 'Motion timings', [
        CineRoleText('Turn on “Show motion timings” in Diagnostics to record every move; this panel lists the last 20.', context.cine.typeCaption, color: context.cine.colorInk60),
        const SizedBox(height: 12),
        CineButton(
          key: const Key('g-timings-toggle'),
          label: ref.watch(motionTimingsOverlayProvider) ? 'Stop recording' : 'Record',
          variant: CineButtonVariant.secondary,
          onPressed: () => ref.read(motionTimingsOverlayProvider.notifier).state = !ref.read(motionTimingsOverlayProvider),
        ),
        const SizedBox(height: 12),
        const CineMotionTimingsPanel(),
      ]);
}

void _noop() {}

/// A stand-in for the caller's local rail (the AI-unavailable state replaces the posters).
class CineRoleTextPlaceholder extends StatelessWidget {
  const CineRoleTextPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => CineRoleText('Your local shelf renders here.', context.cine.typeBodyItalic, color: context.cine.colorInk60);
}
