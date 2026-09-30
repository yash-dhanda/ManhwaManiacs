import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/stocks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Where a control is saved, as the caption under it (cinematic 8.15.5).
abstract final class NovelScope {
  static const book = 'Saved for this book';
  static const profile = 'Saved for this profile';
  static const session = 'For this reading only';
}

/// What a row of the Type sheet reads and writes.
class NovelTypeCtx {
  const NovelTypeCtx({
    required this.context,
    required this.ref,
    required this.prefsKey,
    required this.prefs,
    required this.type,
    required this.settings,
    required this.tablet,
    required this.stockId,
    this.ambient,
  });

  final BuildContext context;
  final WidgetRef ref;

  /// `source:series`, the K25 key.
  final String prefsKey;
  final NovelPreferences prefs;

  /// The resolved body type (what the page shows).
  final NovelType type;
  final JsonRecord settings;
  final bool tablet;
  final String stockId;

  /// This book's `ambient` colours, for the Issue swatch; null hides it.
  final AmbientRoles? ambient;

  NovelPreferencesController get book => ref.read(novelPreferencesControllerProvider(prefsKey).notifier);
  NovelSettingsNotifier get profile => ref.read(novelSettingsProvider.notifier);
  bool get paged => settings.novelLayout == 'paged';
}

typedef NovelTypeRow = Widget Function(NovelTypeCtx c);

/// The ordered rows of the sheet. `mobile/23` appends its `AMBIENT` group to this list; nothing
/// else changes.
final List<NovelTypeRow> kNovelTypeRows = [
  faceRow,
  (c) => _decimalStepper(c, 'type-size', 'Size', c.type.fontSize, 14, 40, 1, (v) => unawaited(c.book.setSize(v)), unit: 'PX', scope: NovelScope.book, decimals: 0),
  (c) => _decimalStepper(c, 'type-leading', 'Line spacing', c.type.lineHeight, 1.30, 2.10, 0.05, (v) => unawaited(c.book.setLeading(v)), scope: NovelScope.book, decimals: 2),
  (c) => _decimalStepper(c, 'type-measure', 'Measure', c.type.measure, 48, 88, 2, (v) => unawaited(c.book.setCineMeasure(v)), unit: 'CH', scope: NovelScope.book, decimals: 0),
  (c) => c.tablet
      ? const SizedBox.shrink()
      : segmentedRow('type-margins', 'Margins', const ['NARROW', 'STANDARD', 'WIDE'], const ['narrow', 'standard', 'wide'].indexOf(c.settings.novelMargins),
          (i) => unawaited(c.profile.put({'margins': const ['narrow', 'standard', 'wide'][i]})),
          description: NovelScope.profile,),
  (c) => _decimalStepper(c, 'type-paragraph', 'Paragraph spacing', c.type.paragraphSpacing, 0, 1.2, 0.1, (v) => unawaited(c.book.setParagraphSpacing(v)), unit: 'EM', scope: NovelScope.book, decimals: 1),
  (c) => _decimalStepper(c, 'type-letter', 'Character spacing', c.type.letterSpacing, -0.02, 0.08, 0.01, (v) => unawaited(c.book.setLetterSpacing(v)), unit: 'EM', scope: NovelScope.book, decimals: 2),
  (c) => switchRow('type-bold', 'Bold text', c.settings.novelBold, (v) => c.profile.put({'bold': v}), description: NovelScope.profile),
  (c) => switchRow('type-justify', 'Justify and hyphenate', c.settings.novelJustify, (v) => c.profile.put({'justify': v}), description: '${NovelScope.profile}. Justifies without hyphens.'),
  (c) => segmentedRow('type-layout', 'Layout', const ['SCROLL', 'PAGED'], c.paged ? 1 : 0, (i) => unawaited(c.profile.put({'layout': i == 0 ? 'scroll' : 'paged'})), description: NovelScope.profile),
  (c) => segmentedRow('type-turn', 'Page turn', const ['CUT', 'SLIDE', 'FADE'], const ['cut', 'slide', 'fade'].indexOf(c.settings.novelPageTurn),
      (i) => unawaited(c.profile.put({'pageTurn': const ['cut', 'slide', 'fade'][i]})),
      description: c.paged ? NovelScope.profile : 'The paged layout only. ${NovelScope.profile}.', disabled: !c.paged,),
  (c) => segmentedRow('type-taps', 'Tap zones', const ['STANDARD', 'BOTH MARGINS ADVANCE', 'ONE HAND'], const ['standard', 'bothMargins', 'oneHand'].indexOf(c.settings.novelTapZones),
      (i) => unawaited(c.profile.put({'tapZones': const ['standard', 'bothMargins', 'oneHand'][i]})),
      description: c.paged ? NovelScope.profile : 'The paged layout only. ${NovelScope.profile}.', disabled: !c.paged,),
  (c) => switchRow('type-swipe', 'Swipe sideways to change chapter', c.settings.novelSwipeChapter, (v) => c.profile.put({'swipeChapter': v}),
      description: c.paged ? 'The scroll layout only. ${NovelScope.profile}.' : NovelScope.profile, disabled: c.paged,),
  stockRow,
];

Widget _decimalStepper(NovelTypeCtx c, String id, String label, double value, double min, double max, double step, ValueChanged<double> onChanged,
    {required String scope, required int decimals, String? unit,}) {
  return JumpRow(
    id: id,
    child: CineSettingsRow(
      label: label,
      description: scope,
      control: NovelValueStepper(label: label, value: value, min: min, max: max, step: step, decimals: decimals, unit: unit, onChanged: onChanged),
    ),
  );
}

/// `−` value `+` for a decimal value: the ruled 36 px buttons (44 / 48 hit) of [CineStepper]
/// around a folio value that rolls. Press and hold repeats every 120 ms after 400 ms; `select` per
/// step; the bounds disable their button.
class NovelValueStepper extends StatefulWidget {
  const NovelValueStepper({super.key, required this.label, required this.value, required this.min, required this.max, required this.step, required this.decimals, required this.onChanged, this.unit});

  final String label;
  final double value, min, max, step;
  final int decimals;
  final String? unit;
  final ValueChanged<double> onChanged;

  @override
  State<NovelValueStepper> createState() => _NovelValueStepperState();
}

class _NovelValueStepperState extends State<NovelValueStepper> {
  Timer? _delay, _repeat;
  late double _v = widget.value;

  @override
  void didUpdateWidget(NovelValueStepper old) {
    super.didUpdateWidget(old);
    _v = widget.value;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
  }

  bool _can(int dir) => dir < 0 ? _v - widget.step >= widget.min - 1e-9 : _v + widget.step <= widget.max + 1e-9;

  String _text(double v) => '${v.toStringAsFixed(widget.decimals)}${widget.unit == null ? '' : ' ${widget.unit}'}';

  void _step(int dir) {
    if (!_can(dir)) {
      _stop();
      return;
    }
    final next = double.parse((_v + dir * widget.step).clamp(widget.min, widget.max).toStringAsFixed(3));
    _v = next;
    cineFeedback(context, HapticEvent.select);
    widget.onChanged(next);
    setState(() {});
  }

  void _down(int dir) {
    _step(dir);
    _stop();
    _delay = Timer(const Duration(milliseconds: 400), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 120), (_) => _step(dir));
    });
  }

  Widget _btn(BuildContext context, int dir) {
    final c = context.cine;
    final on = _can(dir);
    final hit = cineHitMin(context);
    return Semantics(
      button: true,
      enabled: on,
      label: dir < 0 ? 'Smaller ${widget.label.toLowerCase()}' : 'Larger ${widget.label.toLowerCase()}',
      excludeSemantics: true,
      onTap: on ? () => _step(dir) : null,
      child: Listener(
        onPointerDown: on ? (_) => _down(dir) : null,
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: CineFocusRing(
          canRequestFocus: on,
          onActivate: on ? () => _step(dir) : null,
          hit: hit,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(border: Border.all(color: on ? c.colorInk45 : c.colorRule1)),
            child: Center(child: CineGlyphIcon(dir < 0 ? CineGlyph.minus : CineGlyph.plus, color: on ? c.colorInk100 : c.colorInk30)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      label: widget.label,
      value: _text(_v),
      increasedValue: _can(1) ? _text(_v + widget.step) : null,
      decreasedValue: _can(-1) ? _text(_v - widget.step) : null,
      onIncrease: _can(1) ? () => _step(1) : null,
      onDecrease: _can(-1) ? () => _step(-1) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn(context, -1),
        SizedBox(width: c.space2),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 96),
          child: Center(
            child: ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: c.durTick,
                transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
                child: CineRoleText(_text(_v), c.typeFolioLg, key: ValueKey(_text(_v))),
              ),
            ),
          ),
        ),
        SizedBox(width: c.space2),
        _btn(context, 1),
      ],),
    );
  }
}

/// The five face tiles, each label set in its own face; a caption under Atkinson; the chosen tile
/// framed 2 px `spot` (cinematic 8.15.5).
Widget faceRow(NovelTypeCtx c) => Builder(
      builder: (context) {
        final t = context.cine;
        return SettingsBlock(
          id: 'type-face',
          label: 'Face',
          description: NovelScope.book,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in NovelFace.values)
                _FaceTile(
                  face: f,
                  selected: c.type.face == f,
                  caption: f == NovelFace.atkinson ? 'Designed for low vision' : null,
                  onTap: () {
                    cineFeedback(context, HapticEvent.select);
                    unawaited(c.book.setFace(f));
                  },
                  tokens: t,
                ),
            ],
          ),
        );
      },
    );

class _FaceTile extends StatelessWidget {
  const _FaceTile({required this.face, required this.selected, required this.onTap, required this.tokens, this.caption});
  final NovelFace face;
  final bool selected;
  final String? caption;
  final VoidCallback onTap;
  final CineTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final style = NovelType(face: face).style(t.colorInk100, size: 18);
    final hit = cineHitMin(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: face.label,
      hint: caption,
      excludeSemantics: true,
      onTap: onTap,
      child: CineFocusRing(
        onActivate: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: hit < 56 ? 56 : hit, minWidth: 148),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: selected ? t.colorSpot : t.colorRule2, width: selected ? 2 : 1)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(face.label, style: style, textScaler: TextScaler.noScaling),
                if (caption != null) CineRoleText(caption!, t.typeCaption, color: t.colorInk60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seven 48 x 48 swatches, each "Aa" in its own ink on its own page; the chosen one framed 2 px
/// `spot`. Issue is drawn in this book's `ambient` colours and hidden when the series has none.
Widget stockRow(NovelTypeCtx c) => Builder(
      builder: (context) {
        final t = context.cine;
        final ids = [for (final id in kNovelStockLabels.keys) if (id != 'issue' || c.ambient != null) id];
        return SettingsBlock(
          id: 'type-stock',
          label: 'Stock',
          description: NovelScope.profile,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in ids)
                Builder(builder: (context) {
                  final colors = stockColorsFor(id, ambient: c.ambient);
                  final on = c.stockId == id;
                  void pick() {
                    cineFeedback(context, HapticEvent.select);
                    unawaited(c.profile.put({'stock': id}));
                  }

                  return Semantics(
                    inMutuallyExclusiveGroup: true,
                    checked: on,
                    button: true,
                    label: kNovelStockLabels[id],
                    excludeSemantics: true,
                    onTap: pick,
                    child: CineFocusRing(
                      onActivate: pick,
                      hit: 48,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: pick,
                        child: Container(
                          key: Key('stock-swatch-$id'),
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: colors.page, border: Border.all(color: on ? t.colorSpot : colors.muted.withValues(alpha: 0.5), width: on ? 2 : 1)),
                          child: Text('Aa', style: TextStyle(fontFamily: 'Newsreader', fontSize: 18, color: colors.ink), textScaler: TextScaler.noScaling),
                        ),
                      ),
                    ),
                  );
                },),
            ],
          ),
        );
      },
    );

/// The per-profile keys `Reset text and page` clears.
const kNovelProfileTypeKeys = ['margins', 'bold', 'justify', 'layout', 'pageTurn', 'tapZones', 'swipeChapter', 'stock'];
