
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_covers.dart';
import 'package:manhwamaniacs/skins/glass/dev/lists_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/overlay_sections.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/collection_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/continue_stack.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/history_tile.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/notification_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/result_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/series_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_row_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/stat_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/world_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/goal_ring.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/split_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_area.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/primitives/wave.dart';

enum GalleryGround { black, ambient, white }

const _hover = GlassWidgetStates(hovered: true);
const _pressed = GlassWidgetStates(pressed: true);
const _focused = GlassWidgetStates(focused: true);

/// A painted demo cover (from `mobile/25`'s calibration covers).
class GalleryCover extends StatelessWidget {
  const GalleryCover(this.index, {super.key});
  final int index;

  CalibrationCover get cover => kCalibrationCovers[index % kCalibrationCovers.length];

  @override
  Widget build(BuildContext context) => SizedBox.expand(child: CustomPaint(painter: CalibrationCoverPainter(cover)));
}

/// One section of the primitives gallery over three grounds.
class GlassGallerySection extends StatelessWidget {
  const GlassGallerySection({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 10),
            child: Semantics(header: true, child: GlassLabel(name.toUpperCase(), role: gt.typeCaption1, color: gt.colorLabel2)),
          ),
          _Grounds(builder: _content),
        ],
      );

  Widget _content(BuildContext context, GalleryGround g) => switch (name) {
        'buttons' => _buttons(context, g),
        'hold' => _hold(context, g),
        'icon-buttons' => _iconButtons(context, g),
        'inputs' => _inputs(context, g),
        'search' => _search(context, g),
        'chips' => _chips(context, g),
        'segmented' => _segmented(context, g),
        'cards' => _cards(context, g),
        'posters' => _posters(context, g),
        'rails' => _rails(context, g),
        'skeletons' => _skeletons(context, g),
        'progress' => _progress(context, g),
        'badges' => _badges(context, g),
        'avatars' => _avatars(context, g),
        'tooltips' => _tooltips(context, g),
        'reveals' => _reveals(context, g),
        _ => glassOverlaySection(context, name, g) ?? glassListsSection(context, name, g) ?? GlassLabel('Unknown section $name', role: gt.typeBody),
      };
}

/// Three grounds: black, the ambient field and a white panel; side by side on tablet, stacked on phones.
class _Grounds extends StatelessWidget {
  const _Grounds({required this.builder});
  final Widget Function(BuildContext context, GalleryGround ground) builder;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final panels = [
      for (final g in GalleryGround.values) _Ground(ground: g, child: builder(context, g)),
    ];
    if (!wide) {
      return Column(children: [for (final p in panels) Padding(padding: const EdgeInsets.only(bottom: 12), child: p)]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final p in panels) Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: p))]);
  }
}

class _Ground extends StatelessWidget {
  const _Ground({required this.ground, required this.child});
  final GalleryGround ground;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: ground == GalleryGround.ambient ? const _AuroraPainter() : null,
          child: ColoredBox(
            color: switch (ground) {
              GalleryGround.black => const Color(0xFF000000),
              GalleryGround.ambient => const Color(0x00000000),
              GalleryGround.white => const Color(0xFFFFFFFF),
            },
            child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: _Cap.scope(ground, child))),
          ),
        ),
      );
}

/// A backup aurora for the ambient ground when there is no Glass root behind the gallery.
class _AuroraPainter extends CustomPainter {
  const _AuroraPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF000000));
    void blob(Offset c, double r, Color col) => canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.42), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    blob(Offset(size.width * 0.18, size.height * 0.1), size.shortestSide * 0.9, GlassColors.aurora1);
    blob(Offset(size.width * 0.8, size.height * 0.2), size.shortestSide * 0.9, GlassColors.aurora2);
    blob(Offset(size.width * 0.46, size.height * 0.6), size.shortestSide * 0.9, GlassColors.aurora3);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => false;
}

/// Captions that stay legible on every ground.
class _Cap extends InheritedWidget {
  const _Cap({required this.ground, required super.child});
  final GalleryGround ground;

  static Widget scope(GalleryGround g, Widget child) => _Cap(ground: g, child: child);
  static GalleryGround of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_Cap>()?.ground ?? GalleryGround.black;

  @override
  bool updateShouldNotify(_Cap old) => old.ground != ground;
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: GlassLabel(label, role: gt.typeMono, size: 10, height: 13, color: _Cap.of(context) == GalleryGround.white ? const Color(0xFF3C3C46) : gt.colorLabel2)),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );
}

Widget _wrap(List<Widget> cells) => Wrap(children: cells);

Widget _title(BuildContext context, String t) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: ExcludeSemantics(child: GlassLabel(t, role: gt.typeFootnote, wght: 600, color: _Cap.of(context) == GalleryGround.white ? const Color(0xFF111111) : gt.colorLabel1)),
    );

// -- A: buttons ------------------------------------------------------------------

Widget _buttons(BuildContext context, GalleryGround g) {
  Widget b(GlassButtonVariant v, String label, {String cell = 'default', GlassWidgetStates f = GlassWidgetStates.none, bool disabled = false, bool loading = false, bool selected = false, bool error = false, GlassButtonSize size = GlassButtonSize.medium}) => _Cell(
        cell,
        GlassButton(
          label: label,
          variant: v,
          size: size,
          forceStates: f,
          onPressed: disabled ? null : () {},
          loading: loading,
          selected: selected,
          errorText: error ? "Couldn't save" : null,
          errorTrigger: error ? 0 : 0,
          disabledReason: disabled ? 'Nothing to save' : null,
          overMedia: g != GalleryGround.black,
          icon: selected ? GlassButtonIcon.glyph(GlassGlyph.check) : null,
          debugLabel: 'gallery',
        ),
      );
  final variants = [
    (GlassButtonVariant.primary, 'Continue'),
    (GlassButtonVariant.secondary, 'In library'),
    (GlassButtonVariant.plain, 'Not now'),
    (GlassButtonVariant.destructive, 'Delete'),
    (GlassButtonVariant.destructiveConfirm, 'Delete'),
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (v, label) in variants) ...[
        _title(context, v.name),
        _wrap([
          b(v, label),
          b(v, label, cell: 'hover', f: _hover),
          b(v, label, cell: 'pressed', f: _pressed),
          b(v, label, cell: 'focused', f: _focused),
          b(v, label, cell: 'disabled', disabled: true),
          b(v, label, cell: 'loading', loading: true),
          if (v == GlassButtonVariant.secondary) b(v, label, cell: 'selected', selected: true),
          if (v != GlassButtonVariant.destructiveConfirm) b(v, label, cell: 'error', f: const GlassWidgetStates(error: true), error: true),
        ]),
      ],
      _title(context, 'sizes'),
      _wrap([
        b(GlassButtonVariant.secondary, 'Large', cell: 'L 50', size: GlassButtonSize.large),
        b(GlassButtonVariant.secondary, 'Medium', cell: 'M 44'),
        b(GlassButtonVariant.secondary, 'Small', cell: 'S 34', size: GlassButtonSize.small),
      ]),
      _title(context, 'split'),
      _wrap([
        _Cell('default', GlassSplitButton(label: 'Continue', semanticsLabel: 'Continue, chapter 143', onPressed: () {}, onMore: (_) {})),
        _Cell('pressed', GlassSplitButton(label: 'Continue', semanticsLabel: 'Continue, chapter 143', onPressed: () {}, onMore: (_) {}, forcePressed: 0)),
      ]),
      _title(context, 'progress'),
      _wrap([
        _Cell('idle', GlassProgressButton(state: GlassDownloadState.idle, onPressed: () {})),
        _Cell('queued', GlassProgressButton(state: GlassDownloadState.queued, onPressed: () {})),
        _Cell('saving', GlassProgressButton(state: GlassDownloadState.saving, done: 12, total: 40, onPressed: () {})),
        _Cell('complete', GlassProgressButton(state: GlassDownloadState.complete, onPressed: () {})),
        _Cell('failed', GlassProgressButton(state: GlassDownloadState.failed, onPressed: () {})),
      ]),
    ],
  );
}

// -- B: hold -----------------------------------------------------------------------

Widget _hold(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'standalone'),
        _wrap([
          _Cell('default', HoldToConfirm(label: 'Hold to delete', icon: GlassButtonIcon.glyph(GlassGlyph.trash), onConfirm: () {}, onRequestConfirm: () {})),
          _Cell('aborted', HoldToConfirm(label: 'Hold to delete', icon: GlassButtonIcon.glyph(GlassGlyph.trash), onConfirm: () {}, onRequestConfirm: () {}, forceHelper: 'Keep holding, or tap once to confirm')),
          _Cell('pressed', HoldToConfirm(label: 'Hold to delete', icon: GlassButtonIcon.glyph(GlassGlyph.trash), onConfirm: () {}, onRequestConfirm: () {}, forceStates: _pressed)),
          _Cell('focused', HoldToConfirm(label: 'Hold to delete', onConfirm: () {}, onRequestConfirm: () {}, forceStates: _focused)),
        ]),
        _title(context, 'in an alert'),
        _wrap([
          _Cell('default', HoldToConfirm(label: 'Hold to turn on 18+', mode: HoldMode.inAlert, fallbackLabel: 'Turn on 18+', onConfirm: () {})),
        ]),
      ],
    );

// -- C: icon buttons ----------------------------------------------------------------

Widget _iconButtons(BuildContext context, GalleryGround g) {
  Widget ib(GlassIconButtonKind k, GlassIconRole role, String label, {String cell = 'default', GlassWidgetStates f = GlassWidgetStates.none, bool? toggle, Color? onColor, int? badge, bool disabled = false, bool loading = false, bool error = false}) => _Cell(
        cell,
        GlassIconButton(
          icon: GlassButtonIcon(glassIcons[role]![GlassIconWeight.regular]!, fill: glassIcons[role]![GlassIconWeight.fill]),
          label: label,
          kind: k,
          toggle: toggle,
          onColor: onColor,
          badge: badge,
          forceStates: f,
          loading: loading,
          errorAction: error ? 'save' : null,
          onPressed: disabled ? null : () {},
          disabledReason: disabled ? 'Nothing to do' : null,
        ),
      );
  Widget row(GlassIconButtonKind k, String name) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(context, name),
        _wrap([
          ib(k, GlassIconRole.share, 'Share'),
          ib(k, GlassIconRole.share, 'Share', cell: 'hover', f: _hover),
          ib(k, GlassIconRole.share, 'Share', cell: 'pressed', f: _pressed),
          ib(k, GlassIconRole.share, 'Share', cell: 'focused', f: _focused),
          ib(k, GlassIconRole.share, 'Share', cell: 'disabled', disabled: true),
          ib(k, GlassIconRole.share, 'Share', cell: 'loading', loading: true),
          ib(k, GlassIconRole.share, 'Share', cell: 'error', f: const GlassWidgetStates(error: true), error: true),
        ]),
      ],);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      row(GlassIconButtonKind.nav, 'nav'),
      row(GlassIconButtonKind.plain, 'plain'),
      row(GlassIconButtonKind.row, 'row'),
      _title(context, 'toggles'),
      _wrap([
        ib(GlassIconButtonKind.plain, GlassIconRole.pin, 'Pin source', cell: 'pin off', toggle: false),
        ib(GlassIconButtonKind.plain, GlassIconRole.pin, 'Pin source', cell: 'pin on', toggle: true, onColor: gt.colorIris400),
        ib(GlassIconButtonKind.plain, GlassIconRole.favourite, 'Favourite', cell: 'favourite', toggle: true, onColor: gt.colorStreakCore),
        ib(GlassIconButtonKind.plain, GlassIconRole.downloaded, 'Downloaded', cell: 'downloaded', toggle: true, onColor: gt.colorSuccess),
        ib(GlassIconButtonKind.nav, GlassIconRole.notify, 'Notify me', cell: 'notify', toggle: true, onColor: gt.colorIris400),
      ]),
      _title(context, 'badged'),
      _wrap([
        ib(GlassIconButtonKind.nav, GlassIconRole.updates, 'Updates', cell: '3', badge: 3),
        ib(GlassIconButtonKind.plain, GlassIconRole.updates, 'Updates', cell: '12', badge: 12),
      ]),
      _title(context, 'group'),
      _wrap([
        _Cell('default', GlassGroup(items: [
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.export, fill: PhosphorFill.export), label: 'Share', onPressed: () {}),
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.bookmarkSimple, fill: PhosphorFill.bookmarkSimple), label: 'Bookmark', onPressed: () {}, toggle: false),
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.dotsThree, fill: PhosphorFill.dotsThree), label: 'More', onPressed: () {}),
        ],),),
        _Cell('pressed', GlassGroup(forcePressed: 1, items: [
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.export, fill: PhosphorFill.export), label: 'Share', onPressed: () {}),
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.bookmarkSimple, fill: PhosphorFill.bookmarkSimple), label: 'Bookmark', onPressed: () {}, toggle: false),
          GlassGroupItem(icon: const GlassButtonIcon(PhosphorRegular.dotsThree, fill: PhosphorFill.dotsThree), label: 'More', onPressed: () {}),
        ],),),
      ]),
    ],
  );
}

// -- D: inputs -----------------------------------------------------------------------

Widget _inputs(BuildContext context, GalleryGround g) {
  Widget field(String cell, {GlassFieldKind kind = GlassFieldKind.text, GlassWidgetStates f = GlassWidgetStates.none, bool enabled = true, bool loading = false, String? error, String? label = 'Display name'}) => _Cell(
        cell,
        SizedBox(
          width: kind == GlassFieldKind.number ? 96 : 250,
          child: GlassTextField(
            kind: kind,
            label: kind == GlassFieldKind.number ? null : label,
            hint: kind == GlassFieldKind.url ? 'https://…' : (kind == GlassFieldKind.number ? '1' : 'Type here'),
            helper: error == null ? 'Shown on your profile' : null,
            forceStates: f,
            enabled: enabled,
            loading: loading,
            error: error,
            semanticsLabel: '$cell ${kind.name}',
          ),
        ),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(context, 'text'),
      _wrap([
        field('default'),
        field('hover', f: _hover),
        field('focused', f: _focused),
        field('disabled', enabled: false),
        field('loading', loading: true),
        field('error', error: 'Names need at least two letters'),
      ]),
      _title(context, 'password'),
      _wrap([field('default', kind: GlassFieldKind.password, label: 'Password'), field('error', kind: GlassFieldKind.password, label: 'Password', error: 'That password is too short')]),
      _title(context, 'url'),
      _wrap([field('default', kind: GlassFieldKind.url, label: 'Server address'), field('focused', kind: GlassFieldKind.url, label: 'Server address', f: _focused)]),
      _title(context, 'number'),
      _wrap([field('default', kind: GlassFieldKind.number), field('focused', kind: GlassFieldKind.number, f: _focused), field('disabled', kind: GlassFieldKind.number, enabled: false)]),
      _title(context, 'text area'),
      _wrap([
        const _Cell('default', SizedBox(width: 250, child: GlassTextArea(label: 'Ask about a series', hint: 'What should I read next?', helper: 'Enter sends, Shift+Enter adds a line', submitOnEnter: true))),
        const _Cell('error', SizedBox(width: 250, child: GlassTextArea(label: 'Notes', error: 'Notes are too long', maxLength: 200))),
      ]),
    ],
  );
}

// -- E: search --------------------------------------------------------------------------

Widget _search(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'bottom'),
        const _Cell('idle', GlassSearchField(variant: GlassSearchVariant.bottom, ridesKeyboard: false)),
        _title(context, 'page'),
        const _Cell('idle', GlassSearchField()),
        const _Cell('searching', GlassSearchField(status: GlassSearchStatus.searching)),
        const _Cell('offline', GlassSearchField(status: GlassSearchStatus.offline)),
        _title(context, 'filter'),
        const _Cell('idle', GlassSearchField(variant: GlassSearchVariant.filter, placeholder: 'Filter this list')),
        const _Cell('error', GlassSearchField(variant: GlassSearchVariant.filter, placeholder: 'Filter this list', status: GlassSearchStatus.error)),
        _title(context, 'sidebar'),
        _Cell('idle', SizedBox(width: 220, child: GlassSearchField(variant: GlassSearchVariant.sidebar, onOpenPalette: () {}))),
      ],
    );

// -- F: chips -----------------------------------------------------------------------------

Widget _chips(BuildContext context, GalleryGround g) {
  Widget c(String cell, {GlassChipKind kind = GlassChipKind.filter, bool selected = false, GlassWidgetStates f = GlassWidgetStates.none, int? count, bool enabled = true, bool loading = false, String? error, String label = 'Romance'}) => _Cell(
        cell,
        GlassChip(label: label, kind: kind, selected: selected, forceStates: f, count: count, enabled: enabled, loading: loading, error: error, onPressed: () {}, onRemove: () {}, leading: kind == GlassChipKind.assist ? GlassGlyph.sparkle.regular : null),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(context, 'filter'),
      _wrap([
        c('default'),
        c('hover', f: _hover),
        c('pressed', f: _pressed),
        c('focused', f: _focused),
        c('selected', selected: true),
        c('disabled', enabled: false),
        c('error', error: 'Genre filters are offline'),
      ]),
      _title(context, 'count'),
      _wrap([c('default', kind: GlassChipKind.count, count: 4, label: 'Pinned'), c('loading', kind: GlassChipKind.count, count: 4, label: 'Pinned', loading: true)]),
      _title(context, 'input'),
      _wrap([c('default', kind: GlassChipKind.input, label: 'Action'), c('focused', kind: GlassChipKind.input, label: 'Action', f: _focused)]),
      _title(context, 'assist'),
      _wrap([c('default', kind: GlassChipKind.assist, label: 'Next 10'), c('pressed', kind: GlassChipKind.assist, label: 'Next 10', f: _pressed)]),
      _title(context, 'tag'),
      _wrap([c('default', kind: GlassChipKind.tag, label: 'Manhwa'), c('link', kind: GlassChipKind.tag, label: 'Ongoing')]),
      _title(context, 'choice'),
      const _ChoiceDemo(),
      _title(context, 'row'),
      GlassChipRow(padding: const EdgeInsets.symmetric(vertical: 8), children: [
        for (final l in ['All', 'Reading', 'Completed', 'On hold', 'Dropped', 'Plan to read']) GlassChip(label: l, selected: l == 'Reading', onPressed: () {}),
      ],),
    ],
  );
}

class _ChoiceDemo extends StatefulWidget {
  const _ChoiceDemo();
  @override
  State<_ChoiceDemo> createState() => _ChoiceDemoState();
}

class _ChoiceDemoState extends State<_ChoiceDemo> {
  String _sel = 'Newest';
  @override
  Widget build(BuildContext context) => GlassChoiceChips<String>(options: const ['Newest', 'Popular', 'A-Z'], selected: _sel, onSelected: (v) => setState(() => _sel = v), labelOf: (s) => s);
}

// -- G: segmented ----------------------------------------------------------------------------

class _SegDemo extends StatefulWidget {
  const _SegDemo({this.n = 3, this.enabled = true, this.loading = false, this.dragging = false, this.vertical = false, this.tabs = false});
  final int n;
  final bool enabled;
  final bool loading;
  final bool dragging;
  final bool vertical;
  final bool tabs;
  @override
  State<_SegDemo> createState() => _SegDemoState();
}

class _SegDemoState extends State<_SegDemo> {
  int _sel = 0;
  static const labels = ['Library', 'Sources', 'Circle', 'Stats', 'Notes'];
  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.vertical ? 220 : 280,
        child: GlassSegmented<int>(
          segments: [for (var i = 0; i < widget.n; i++) GlassSegment(value: i, label: labels[i])],
          selected: _sel,
          onSelected: (v) => setState(() => _sel = v),
          enabled: widget.enabled,
          loadingValue: widget.loading ? 1 : null,
          forceDragging: widget.dragging,
          axis: widget.vertical ? Axis.vertical : Axis.horizontal,
          asTabs: widget.tabs,
        ),
      );
}

Widget _segmented(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'horizontal'),
        _wrap([
          const _Cell('default', _SegDemo()),
          const _Cell('four', _SegDemo(n: 4)),
          const _Cell('tabs', _SegDemo(tabs: true)),
          const _Cell('disabled', _SegDemo(enabled: false)),
          const _Cell('loading', _SegDemo(loading: true)),
          const _Cell('dragging', _SegDemo(dragging: true)),
        ]),
        _title(context, 'vertical'),
        const _Cell('scopes', _SegDemo(n: 4, vertical: true)),
      ],
    );

// -- H: cards -----------------------------------------------------------------------------------

/// Card widths that fit the narrow tablet grounds.
double _cardW(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= 720 ? (w - 48 - 16) / 3 - 24 : 300;
}

Widget _cards(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'series'),
        _wrap([
          _Cell('default', GlassSeriesCard(poster: GlassPoster(cover: const GalleryCover(0), title: 'Salt and Iron', width: 110, meta: const GlassPosterMeta(status: GlassStatus.reading, newCount: 3), onTap: () {}), title: 'Salt and Iron', meta: 'Ch 142 · 3 new', width: 110)),
          const _Cell('loading', GlassSeriesCard.loading(width: 110)),
        ]),
        _title(context, 'continue'),
        _wrap([
          _Cell('default', GlassContinueStack(cover: const GalleryCover(1), nextThumb: const GalleryCover(2), title: 'Ember Ledger', chapter: 142, page: 18, pageCount: 40, onOpen: () {}, onContinue: () {}, onMore: () {}, onPreviouslyOn: () {})),
          _Cell('unopened', GlassContinueStack(cover: const GalleryCover(3), title: 'The Ninth Regression', chapter: 143, page: 0, pageCount: 0, onOpen: () {}, onContinue: () {}, onMore: () {})),
        ]),
        _title(context, 'world'),
        _wrap([
          _Cell('available', GlassWorldCard.available(cover: const GalleryCover(6), title: 'Moonlit Bakery', kind: 'Manhwa · Ongoing', stats: '120 ch · ★ 8.4', why: 'Because you read Solo Leveling', source: 'MangaSource', extraSources: 2, tags: const ['Fantasy', 'Action'], onOpen: () {}, ai: true)),
          _Cell('info only', GlassWorldCard.infoOnly(cover: const GalleryCover(7), title: 'Glass Tide', kind: 'Manhwa · Ongoing', stats: '88 ch · ★ 8.1', why: 'Matches your taste', site: 'Webtoon', siteUrl: 'https://example.com', tags: const ['Drama'], onSearchMySources: () {})),
        ]),
        _title(context, 'result, stat, history'),
        _wrap([
          _Cell('result', GlassResultCard(cover: const GalleryCover(8), title: 'Frost Archive', onTap: () {}, sourceBadge: const GlassSourceMonogram(name: 'Shelf', sourceId: 'shelf', size: 16))),
          _Cell('stat', SizedBox(width: 150, child: GlassStatCard(icon: GlassGlyph.flame.regular, value: '12', label: 'Day streak', spark: const [1, 3, 2, 5, 4, 6, 7], onTap: () {}))),
          _Cell('history', GlassHistoryTile(cover: const GalleryCover(9), title: 'Blue Hour Duel', when: 'Ch 12 · 3 h ago', position: 'p. 18', progress: 0.45, width: 110, onOpen: () {}, onResume: () {})),
        ]),
        _title(context, 'collection'),
        _Cell('default', GlassCollectionCard(name: 'Weekend reads', count: 12, covers: const [GalleryCover(0), GalleryCover(6), GalleryCover(12), GalleryCover(16)], width: _cardW(context), onTap: () {})),
        _title(context, 'notification'),
        _Cell('default', SizedBox(width: _cardW(context), child: GlassNotificationCard(cover: const GalleryCover(4), title: 'Dune Courier', summary: '3 new · Ch 141–143', time: '2 h', chapters: const [141, 142, 143], onOpenSeries: () {}, onOpenChapter: (_) {}))),
        _title(context, 'source rows'),
        _Cell('working', SizedBox(width: _cardW(context), child: GlassSourceRowCard(sourceId: 'shelf', name: 'Shelf', description: 'Community scans, English', health: GlassSourceHealth.ok, pinned: true, onTap: () {}, onPin: () {}))),
        _Cell('trouble, demoted', SizedBox(width: _cardW(context), child: GlassSourceRowCard(sourceId: 'lantern', name: 'Lantern', description: 'Sometimes slow', health: GlassSourceHealth.failing, demoted: true, mature: true, onTap: () {}, onPin: () {}))),
        _Cell('dead', SizedBox(width: _cardW(context), child: GlassSourceRowCard(sourceId: 'gone', name: 'Gone', description: 'Not answering', health: GlassSourceHealth.dead, enabled: false, disabledReason: 'This source is not working', onTap: () {}, onPin: () {}))),
      ],
    );

// -- I: posters -------------------------------------------------------------------------------------

Widget _posters(BuildContext context, GalleryGround g) {
  Widget p(String cell, int i, {GlassPosterMeta meta = const GlassPosterMeta(), GlassWidgetStates f = GlassWidgetStates.none, bool loading = false, bool error = false, bool select = false, bool selected = false, bool enabled = true, bool corners = false}) => _Cell(
        cell,
        GlassPoster(
          cover: GalleryCover(i),
          lMax: kCalibrationCovers[i % kCalibrationCovers.length].lMax,
          title: kCalibrationCovers[i % kCalibrationCovers.length].title,
          width: 96,
          meta: meta,
          forceStates: f,
          loading: loading,
          error: error,
          selectMode: select,
          selected: selected,
          enabled: enabled,
          disabledReason: enabled ? null : 'Not on your sources',
          forceHoverButtons: corners,
          onTap: () {},
          onContextPreview: () {},
          onFavourite: () {},
          onFollow: () {},
        ),
      );
  return _wrap([
    p('default', 0, meta: const GlassPosterMeta(status: GlassStatus.reading, newCount: 3, downloaded: true, progress: 0.4)),
    p('hover', 22, f: _hover, corners: true, meta: const GlassPosterMeta(status: GlassStatus.completed, mature: true)),
    p('pressed', 6, f: _pressed),
    p('focused', 10, f: _focused),
    p('disabled', 14, enabled: false),
    p('loading', 2, loading: true),
    p('selected', 16, select: true, selected: true, meta: const GlassPosterMeta(newCount: 5)),
    p('unselected', 17, select: true),
    p('error', 3, error: true),
    p('white cover', 22, meta: const GlassPosterMeta(status: GlassStatus.onHold, newCount: 12, favourite: true, downloaded: true)),
  ]);
}

// -- J: rails -----------------------------------------------------------------------------------------

Widget _rails(BuildContext context, GalleryGround g) {
  Widget poster(int i) => GlassSeriesCard(poster: GlassPoster(cover: GalleryCover(i), lMax: kCalibrationCovers[i].lMax, title: kCalibrationCovers[i].title, width: 110, onTap: () {}, onContextPreview: () {}), title: kCalibrationCovers[i].title, meta: 'Ch ${100 + i}', width: 110);
  Widget rail(String cell, GlassRailState state, {String title = 'Because you read Solo Leveling', Widget? unavailable}) => _Cell(
        cell,
        SizedBox(
          width: 340,
          child: GlassRail(
            title: title,
            subtitle: state == GlassRailState.ready ? 'From your library' : null,
            revealKey: 'gallery-$cell',
            screenId: 'gallery',
            itemCount: 10,
            itemWidth: 110,
            itemHeight: 110 * 1.5 + 8 + 34 + 34,
            itemBuilder: (context, i) => poster(i),
            state: state,
            onSeeAll: () {},
            onRetry: () {},
            unavailable: unavailable,
            forceArrows: cell == 'arrows',
          ),
        ),
      );
  return GlassRailGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rail('ready', GlassRailState.ready),
        rail('arrows', GlassRailState.ready, title: 'Continue reading'),
        rail('loading', GlassRailState.loading, title: 'Fresh chapters'),
        rail('partial', GlassRailState.partial, title: 'From your sources'),
        rail('error', GlassRailState.error, title: 'Trending now'),
        rail('empty', GlassRailState.empty, unavailable: GlassLabel('AI picks are unavailable right now', role: gt.typeFootnote, color: gt.colorLabel2)),
      ],
    ),
  );
}

// -- K: skeletons -------------------------------------------------------------------------------------------

Widget _skeletons(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'wet glass'),
        GlassSkeletonGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    GlassSkeleton(width: 44, height: 66, radius: 10, index: i, delayed: false),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GlassSkeleton(width: 160, height: 14, radius: 7, index: i, delayed: false),
                      const SizedBox(height: 8),
                      GlassSkeleton(width: 100, height: 10, radius: 5, index: i, delayed: false),
                    ],),
                  ],),
                ),
            ],
          ),
        ),
        _title(context, 'AI (slow sheen)'),
        const GlassSkeletonGroup(ai: true, child: GlassSkeleton(width: 240, height: 72, radius: 20, delayed: false)),
        _title(context, 'entrance wave'),
        GlassWave(cause: Offset.zero, layout: (items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: items), children: [
          for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: GlassLabel('Wave item ${i + 1}', role: gt.typeBody, color: _Cap.of(context) == GalleryGround.white ? const Color(0xFF111111) : gt.colorLabel1)),
        ],),
      ],
    );

// -- L: progress ------------------------------------------------------------------------------------------------

Widget _progress(BuildContext context, GalleryGround g) {
  Widget lin(String cell, GlassProgressStatus s, {double? v = 0.6}) => _Cell(cell, SizedBox(width: 220, child: GlassLinearProgress(value: v, status: s, label: 'Download $cell', valueLabel: '12 of 40 pages saved')));
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(context, 'linear'),
      _wrap([
        lin('default', GlassProgressStatus.normal),
        lin('indeterminate', GlassProgressStatus.normal, v: null),
        lin('complete', GlassProgressStatus.complete, v: 1),
        lin('paused', GlassProgressStatus.paused),
        lin('error', GlassProgressStatus.error),
        lin('disabled', GlassProgressStatus.disabled),
      ]),
      _title(context, 'hairline, ring, spinner, dots'),
      _wrap([
        const _Cell('hairline', SizedBox(width: 220, child: GlassHairlineProgress(value: 0.4))),
        const _Cell('ring 24', GlassRingProgress(value: 0.65)),
        const _Cell('ring 32', GlassRingProgress(value: 0.3, size: 32)),
        const _Cell('spinner 16', GlassSpinner()),
        const _Cell('spinner 24', GlassSpinner(size: 24)),
        const _Cell('dots', GlassDots()),
      ]),
      _title(context, 'liquid'),
      _wrap([
        const _Cell('60 %', SizedBox(width: 220, height: 28, child: ClipRRectCap(child: LiquidProgress(value: 0.6, height: 28)))),
        const _Cell('90 %', SizedBox(width: 220, height: 28, child: ClipRRectCap(child: LiquidProgress(value: 0.9, height: 28)))),
      ]),
      _title(context, 'segmented'),
      _Cell('storage', SizedBox(width: 220, child: GlassSegmentedBar(segments: [(weight: 6, color: gt.colorIris500), (weight: 3, color: gt.colorInfo), (weight: 1, color: gt.colorWarning)], label: 'Storage breakdown'))),
    ],
  );
}

/// A capsule clip for the gallery's liquid demos.
class ClipRRectCap extends StatelessWidget {
  const ClipRRectCap({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(14)),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
      );
}

// -- M: badges ---------------------------------------------------------------------------------------------------

Widget _badges(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'counts'),
        _wrap([
          const _Cell('3', GlassBadge.count(3)),
          const _Cell('9+', GlassBadge.count(12)),
          const _Cell('99+', GlassBadge.count(140, max: 99)),
          const _Cell('loading', GlassBadge.count(0, loading: true)),
          const _Cell('error', GlassBadge.count(0, error: true)),
          const _Cell('dot', GlassBadge.dot()),
          const _Cell('new', GlassBadge.newChapters(3)),
        ]),
        _title(context, 'status'),
        _wrap([for (final s in GlassStatus.values) _Cell(s.name, GlassBadge.status(s))]),
        _title(context, 'status on a cover'),
        _wrap([for (final s in GlassStatus.values) _Cell(s.name, GlassBadge.status(s, onCover: true))]),
        _title(context, 'others'),
        _wrap([
          const _Cell('mature', GlassBadge.mature()),
          const _Cell('mature cover', GlassBadge.mature(onCover: true)),
          const _Cell('age gate', GlassBadge.ageGate()),
          const _Cell('source', GlassBadge.source('MangaSource', icon: GlassSourceMonogram(name: 'MangaSource', sourceId: 'ms', size: 12))),
          const _Cell('downloaded', GlassBadge.downloaded()),
          const _Cell('on cover', GlassBadge.downloaded(onCover: true)),
          const _Cell('offline', GlassBadge.offline('Saved copy · 2 h')),
          const _Cell('role', GlassBadge.role('Admin')),
          const _Cell('friend', GlassFriendBadge(GlassAvatarPreset.roseHeart, name: 'Mira')),
        ]),
      ],
    );

// -- N: avatars -----------------------------------------------------------------------------------------------------

Widget _avatars(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'presets'),
        _wrap([for (final p in GlassAvatarPreset.values) _Cell(p.label, GlassProfileOrb(preset: p, onPressed: () {}, mood: gt.colorMoodFantasy))]),
        _title(context, 'sizes'),
        _wrap([for (final s in [18.0, 24.0, 32.0, 56.0, 72.0, 96.0]) _Cell('${s.toInt()}', GlassProfileOrb(preset: GlassAvatarPreset.cyanRocket, size: s, mood: gt.colorMoodAction))]),
        _title(context, 'states'),
        _wrap([
          _Cell('default', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, onPressed: () {})),
          _Cell('hover', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, onPressed: () {}, forceStates: _hover)),
          _Cell('pressed', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, onPressed: () {}, forceStates: _pressed)),
          _Cell('focused', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, onPressed: () {}, forceStates: _focused)),
          _Cell('disabled', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, enabled: false, onPressed: () {})),
          _Cell('loading', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, loading: true, onPressed: () {})),
          _Cell('selected', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, selected: true, onPressed: () {})),
          _Cell('error', GlassProfileOrb(preset: GlassAvatarPreset.lunarMoon, size: 56, error: true, onPressed: () {})),
          _Cell('drift', GlassProfileOrb(preset: GlassAvatarPreset.starlight, size: 96, drift: true, onPressed: () {})),
          const _Cell('friend', GlassProfileOrb(preset: GlassAvatarPreset.roseHeart, size: 56, friend: true, name: 'Mira')),
        ]),
        _title(context, 'goal ring'),
        _wrap([
          const _Cell('8 of 10', GlassGoalRing(orbSize: 44, minutes: 8, goal: 10, child: GlassProfileOrb(preset: GlassAvatarPreset.emberFlame))),
          const _Cell('met', GlassGoalRing(orbSize: 44, minutes: 12, goal: 10, child: GlassProfileOrb(preset: GlassAvatarPreset.emberFlame))),
          const _Cell('on disc', GlassGoalRing(orbSize: 44, minutes: 4, goal: 10, onDisc: true, child: GlassProfileOrb(preset: GlassAvatarPreset.emberFlame))),
        ]),
      ],
    );

// -- O: tooltips ----------------------------------------------------------------------------------------------------------

Widget _tooltips(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'tooltip'),
        SizedBox(
          height: 90,
          child: Center(
            child: GlassTooltip(
              message: 'Add to library',
              forceVisible: true,
              above: false,
              child: GlassIconButton(icon: GlassButtonIcon.glyph(GlassGlyph.plus), label: 'Add to library', onPressed: () {}, kind: GlassIconButtonKind.nav),
            ),
          ),
        ),
        _title(context, 'keycaps'),
        _wrap([
          _Cell('mod K', GlassKeycaps.shortcut(context, const SingleActivator(LogicalKeyboardKey.keyK, meta: true))),
          _Cell('shift F10', GlassKeycaps.shortcut(context, const SingleActivator(LogicalKeyboardKey.f10, shift: true))),
          const _Cell('single', GlassKeycap('Esc')),
        ]),
      ],
    );

// -- P, Q: reveals -----------------------------------------------------------------------------------------------------------

Widget _reveals(BuildContext context, GalleryGround g) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'typing'),
        TypedHeadline('Good evening, Yash', role: gt.typeLargeTitle, placement: 'gallery:greeting:${g.name}', headingLevel: 1, color: g == GalleryGround.white ? const Color(0xFF111111) : null),
        _title(context, 'letter reveal'),
        LetterReveal('Continue reading', role: gt.typeTitle2, revealKey: 'gallery-a-${g.name}', screenId: 'gallery', color: g == GalleryGround.white ? const Color(0xFF111111) : null),
        _title(context, '70 graphemes (per word)'),
        LetterReveal('The extraordinarily long-winded chronicle of a courier who delivers lanterns', role: gt.typeTitle3, revealKey: 'gallery-long-${g.name}', screenId: 'gallery', color: g == GalleryGround.white ? const Color(0xFF111111) : null),
        const SizedBox(height: 900),
        _title(context, 'rails far below the fold'),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: LetterReveal(['Because you read Solo Leveling', 'Fresh from your sources', 'Quiet picks for tonight'][i], role: gt.typeTitle2, revealKey: 'gallery-rail-$i-${g.name}', screenId: 'gallery', color: g == GalleryGround.white ? const Color(0xFF111111) : null),
          ),
      ],
    );

