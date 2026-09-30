import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_covers.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart' show GalleryCover, GalleryGround;
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_phase.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_stamp.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/phase_line.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/world_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/depth_glyph.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/chapter_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/plain_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_controller.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_strip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/assist_chips.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/back_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/stack_overview.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/state_view.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/view_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The third part of the primitives gallery (`mobile/28`): lists, swipe rows, reorder, selection, states, the 18+ gate, downloads,
/// the depth glyph and the stack overview, AI surfaces, charts and reactions.
const List<String> kGlassListsSections = ['lists', 'swipe', 'reorder', 'select', 'states', 'gate', 'download', 'depth', 'stack', 'ai', 'charts', 'reactions'];

Widget? glassListsSection(BuildContext context, String name, GalleryGround g) => switch (name) {
      'lists' => const _Lists(),
      'swipe' => const _Swipe(),
      'reorder' => const _Reorder(),
      'select' => const GlassSelectDemo(),
      'states' => const _States(),
      'gate' => const _Gate(),
      'download' => const _Downloads(),
      'depth' => const _Depth(),
      'stack' => const _StackDemo(),
      'ai' => const _Ai(),
      'charts' => const _Charts(),
      'reactions' => const _Reactions(),
      _ => null,
    };

Widget _cap(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4), child: ExcludeSemantics(child: GlassLabel(t, role: gt.typeMono, size: 10, height: 13, color: gt.colorLabel2)));

// -- lists ---------------------------------------------------------------------------------

class _Lists extends StatelessWidget {
  const _Lists();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cap('grouped list'),
        GlassGroupedList(inset: false, header: 'Reading', footer: 'Applies to this profile.', children: [
          GlassListRow(title: 'Notifications', subtitle: 'New chapters and Circle', icon: GlassGlyph28.checkCircle.regular, iconColor: gt.colorIris600, caret: true, onTap: () {}),
          GlassListRow(title: 'Downloads', value: '1.2 GB', icon: GlassGlyph28.cloudArrowDown.regular, iconColor: gt.colorSuccess, caret: true, onTap: () {}),
          GlassListRow(title: 'Wi-Fi only', trailing: GlassSwitch(value: true, onChanged: (_) {}, label: 'Wi-Fi only')),
          const GlassListRow(title: 'Disabled row', enabled: false),
          const GlassListRow(title: 'Loading', loading: true),
          const GlassListRow(title: 'With an error', error: 'Could not load'),
        ],),
        _cap('plain list'),
        GlassPlainList(children: [
          GlassListRow(title: 'Bookmark one', subtitle: 'Chapter 12', onTap: () {}),
          GlassListRow(title: 'Bookmark two', selectMode: true, selected: true, onTap: () {}),
        ],),
        _cap('chapter rows'),
        GlassPlainList(children: [
          GlassChapterRow(number: 12, title: 'The tower wakes', date: DateTime.now(), pageCount: 40, trailing: const _Dl(ChapterDownloadKind.none), onTap: () {}),
          GlassChapterRow(number: 11.5, title: 'Interlude', date: DateTime.now().subtract(const Duration(days: 3)), pageCount: 40, progress: 18, trailing: const _Dl(ChapterDownloadKind.downloading), onTap: () {}),
          GlassChapterRow(number: 11, title: 'Read chapter', date: DateTime.now().subtract(const Duration(days: 20)), pageCount: 38, read: true, trailing: const _Dl(ChapterDownloadKind.saved), onTap: () {}),
          GlassChapterRow(number: null, secondaryTitle: 'Extra', date: DateTime.now().subtract(const Duration(days: 1)), selectMode: true, selected: true, onTap: () {}),
          const GlassChapterRow(number: 9, title: 'Saved', enabled: false, disabledHint: 'Already on this device'),
          const GlassChapterRow(number: 8, title: 'Loading', loading: true),
        ],),
      ],);
}

class _Dl extends StatelessWidget {
  const _Dl(this.kind);
  final ChapterDownloadKind kind;

  @override
  Widget build(BuildContext context) => GlassDownloadControl(view: ChapterDownloadView(kind, progress: 0.45, pagesDone: 18, pagesTotal: 40), chapterLabel: 'chapter 12', onDownload: () {}, onCancel: () {}, onRemove: () {});
}

// -- swipe ---------------------------------------------------------------------------------

class _Swipe extends ConsumerWidget {
  const _Swipe();

  SwipeAction act(String id, String label, IconData glyph, SwipeTone tone, {bool destructive = false}) =>
      SwipeAction(id: id, label: label, glyph: glyph, tone: tone, destructive: destructive, run: () async {}, undo: () async {});

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassSwipeGroup(
        child: Column(children: [
          for (final n in const ['Solo Leveling', 'Tower of God', 'Omniscient Reader'])
            GlassSwipeRow(
              name: n,
              leading: [act('markRead', 'Mark read', GlassGlyph28.checkCircle.regular, SwipeTone.success)],
              trailing: [act('remove', 'Remove', GlassGlyph28.trashSimple.regular, SwipeTone.danger, destructive: true), act('download', 'Download', GlassGlyph28.cloudArrowDown.regular, SwipeTone.iris)],
              child: GlassListRow(title: n, subtitle: 'Chapter 142', onTap: () {}),
            ),
          const SizedBox(height: 4),
          GlassText('Swipe a row, or use its more button.', role: gt.typeFootnote, color: gt.colorLabel2),
        ],),
      );
}

// -- reorder -------------------------------------------------------------------------------

class _Reorder extends StatefulWidget {
  const _Reorder();

  @override
  State<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<_Reorder> {
  final List<String> _items = ['Solo Leveling', 'Tower of God', 'Omniscient Reader', 'Lookism', 'The Beginning After The End', 'Nano Machine', 'Eleceed', 'Wind Breaker'];
  final GlassReorderController _c = GlassReorderController();

  @override
  Widget build(BuildContext context) => GlassReorderList<String>(
        items: _items,
        controller: _c,
        nameOf: (s) => s,
        onReorder: (a, b) => setState(() => _items.insert(b, _items.removeAt(a))),
        itemBuilder: (context, item, i, info) => GlassListRow(title: item, subtitle: 'Position ${i + 1}', trailing: info.handle(), onTap: () {}),
      );
}

// -- select --------------------------------------------------------------------------------

/// A live select-mode grid of 24 demo posters with the bulk toolbar (a fake action that succeeds on 11 and fails on 1).
class GlassSelectDemo extends ConsumerStatefulWidget {
  const GlassSelectDemo({super.key, this.count = 24, this.startActive = false});
  final int count;
  final bool startActive;

  @override
  ConsumerState<GlassSelectDemo> createState() => _GlassSelectDemoState();
}

class _GlassSelectDemoState extends ConsumerState<GlassSelectDemo> {
  final GlassSelectModeController<int> _c = GlassSelectModeController<int>();

  @override
  void initState() {
    super.initState();
    if (widget.startActive) _c.enter(2);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = [for (var i = 0; i < widget.count; i++) i];
    final actions = [
      BulkAction<int>(
        id: 'markRead',
        label: 'Mark read',
        glyph: BulkGlyphs.markRead,
        verb: 'marked read',
        run: (sel, cancel) async {
          await Future<void>.delayed(const Duration(milliseconds: 900));
          final list = sel.toList();
          return BulkResult(ok: list.length > 1 ? list.length - 1 : list.length, failed: list.length > 1 ? ['${list.last}'] : const []);
        },
      ),
      BulkAction<int>(id: 'favourite', label: 'Favourite', glyph: BulkGlyphs.favourite, run: (sel, cancel) async => BulkResult(ok: sel.length)),
      BulkAction<int>(id: 'remove', label: 'Remove', glyph: BulkGlyphs.remove, destructive: true, verb: 'removed', run: (sel, cancel) async => BulkResult(ok: sel.length), undo: (sel) async {}),
    ];
    return SizedBox(
      height: 620,
      child: Stack(children: [
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _c,
            builder: (context, _) => GlassSelectableGroup<int>(
              controller: _c,
              ids: ids,
              label: 'Select series',
              child: ListView(padding: const EdgeInsets.only(bottom: 170), children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    if (!_c.active) GlassButton(label: 'Select', size: GlassButtonSize.small, onPressed: _c.enter) else Expanded(child: GlassSelectAssistChips<int>(controller: _c, visible: ids)),
                  ],),
                ),
                Wrap(spacing: 8, runSpacing: 12, children: [
                  for (final i in ids)
                    SizedBox(
                      width: 96,
                      child: GlassSelectableItem<int>(
                        id: i,
                        child: GlassPoster(cover: GalleryCover(i), lMax: kCalibrationCovers[i % kCalibrationCovers.length].lMax, title: kCalibrationCovers[i % kCalibrationCovers.length].title, width: 96, selectMode: _c.active, selected: _c.isSelected(i), onTap: () {}),
                      ),
                    ),
                ],),
              ],),
            ),
          ),
        ),
        GlassBulkToolbar<int>(controller: _c, actions: actions),
      ],),
    );
  }
}

// -- states --------------------------------------------------------------------------------

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cap('lens: empty, error, offline (inline twins)'),
        const GlassObjectLens(situation: LensSituation.library, title: 'Nothing here yet', description: 'Series you follow appear here.', placement: GlassLensPlacement.inline),
        const GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't load this", description: 'Try again in a moment.', placement: GlassLensPlacement.inline),
        GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: "You're offline", description: 'This loads again by itself.', placement: GlassLensPlacement.inline, onRetry: () async => true),
        _cap('lens: offline, full (live T2 over the field)'),
        SizedBox(height: 380, child: GlassObjectLens(situation: LensSituation.serverUnreachable, tone: GlassLensTone.offline, title: "Can't reach the server", description: 'Check your connection.', primary: LensAction('Try again', () {}), onRetry: () async => true)),
        _cap('state view'),
        const SizedBox(height: 360, child: GlassStateView(state: GlassViewState.empty, emptyTitle: 'No bookmarks', emptyDescription: 'Bookmark a page while reading.', emptySituation: LensSituation.bookmarks, placement: GlassLensPlacement.inline, child: SizedBox())),
        _cap('error copy (8.0.10)'),
        for (final code in const ['profile_limit_reached', 'follow_limit_reached', 'rate_limited', 'db_busy', 'forbidden'])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GlassText('$code  ->  ${errorEntry(ApiError(statusCode: 429, code: code, message: '', retryAfter: const Duration(seconds: 12))).copy}', role: gt.typeFootnote, color: gt.colorLabel2),
          ),
      ],);
}

// -- gate ----------------------------------------------------------------------------------

class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  bool _on = false;
  int _err = 0;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cap('off -> confirming -> on (form mode)'),
        GlassGroupedList(inset: false, children: [GlassMatureGate(mode: MatureGateMode.form, value: _on, onChanged: (v) => setState(() => _on = v))]),
        _cap('pending, error, blocked'),
        GlassGroupedList(inset: false, children: [
          GlassListRow(title: 'Pending (saving)', trailing: GlassSwitch(value: true, loading: true, label: 'Pending', onChanged: (_) {})),
          GlassListRow(title: 'Error (springs back, shakes)', trailing: GlassSwitch(value: false, errorTrigger: _err, label: 'Error', onChanged: (_) => setState(() => _err++))),
          const GlassMatureGate(),
        ],),
      ],);
}

// -- download ------------------------------------------------------------------------------

class _Downloads extends StatefulWidget {
  const _Downloads();

  @override
  State<_Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<_Downloads> {
  Timer? _t;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _page = (_page + 1) % 41);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ChapterDownloadView v(ChapterDownloadKind k, {DownloadPauseReason? pause}) => ChapterDownloadView(k, progress: 0.45, pagesDone: 18, pagesTotal: 40, pauseReason: pause);
    final run = chapterDownloadView(ChapterDownloadFacts(row: _page >= 40 ? DownloadChapterState.complete : DownloadChapterState.downloading, pagesDone: _page, pagesTotal: 40));
    Widget cell(String label, ChapterDownloadView view) => Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [GlassDownloadControl(view: view, chapterLabel: 'chapter 12', onDownload: () {}, onCancel: () {}, onRemove: () {}, onExtractText: () {}), ExcludeSemantics(child: GlassLabel(label, role: gt.typeMono, size: 10, height: 13, color: gt.colorLabel2))]),
        );
    return Wrap(children: [
      cell('none', v(ChapterDownloadKind.none)),
      cell('queued', v(ChapterDownloadKind.queued)),
      cell('downloading', v(ChapterDownloadKind.downloading)),
      cell('saved', v(ChapterDownloadKind.saved)),
      cell('incomplete', v(ChapterDownloadKind.incomplete)),
      cell('paused', v(ChapterDownloadKind.paused, pause: DownloadPauseReason.freeSpaceFloor)),
      cell('stale', v(ChapterDownloadKind.stale)),
      cell('failed', v(ChapterDownloadKind.failed)),
      cell('progress run', run),
    ],);
  }
}

// -- depth ---------------------------------------------------------------------------------

class _Depth extends StatelessWidget {
  const _Depth();

  @override
  Widget build(BuildContext context) {
    final tints = [gt.colorIris400, gt.colorBloom, gt.colorMachine, gt.colorAurora1];
    return Wrap(spacing: 24, runSpacing: 12, children: [
      for (var d = 1; d <= 4; d++)
        Column(mainAxisSize: MainAxisSize.min, children: [
          DepthGlyph(depth: d, tints: tints.take(d).toList(), size: 44),
          ExcludeSemantics(child: GlassLabel('depth $d', role: gt.typeMono, size: 10, height: 13, color: gt.colorLabel2)),
          ExcludeSemantics(child: GlassLabel(depthLabel('Library', d), role: gt.typeCaption2, color: gt.colorLabel3)),
        ],),
    ],);
  }
}

// -- stack ---------------------------------------------------------------------------------

class _StackDemo extends ConsumerStatefulWidget {
  const _StackDemo();

  @override
  ConsumerState<_StackDemo> createState() => _StackDemoState();
}

class _StackDemoState extends ConsumerState<_StackDemo> {
  List<GlassRouteSnapshot> _levels = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final out = <GlassRouteSnapshot>[];
    for (var i = 0; i < 3; i++) {
      final cover = kCalibrationCovers[i * 5 % kCalibrationCovers.length];
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      const size = Size(195, 422);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), cover.palette, const [0, 0.5, 1]),
      );
      final img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
      out.add(GlassRouteSnapshot(routeKey: 'demo$i', title: ['Home', 'Solo Leveling', 'Chapter 142'][i], depth: i, tab: GlassTab.home, rimTint: cover.palette[1], image: img));
    }
    if (mounted) setState(() => _levels = out);
  }

  @override
  void dispose() {
    for (final l in _levels) {
      l.image?.dispose();
    }
    super.dispose();
  }

  Rect _rect(BuildContext c) {
    final b = c.findRenderObject()! as RenderBox;
    return b.localToGlobal(Offset.zero) & b.size;
  }

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        Builder(builder: (c) => GlassButton(label: 'Stack overview', onPressed: () => unawaited(openGlassStackOverview(c, ref, levels: _levels, backButtonRect: _rect(c), tabName: 'Home', onPick: (_) {})))),
        Builder(builder: (c) => GlassButton(label: 'Flat back menu', onPressed: () => unawaited(showGlassBackMenu(c, anchor: _rect(c), levels: _levels, tabName: 'Home', onPick: (_) {})))),
        for (final l in _levels) SizedBox(width: 72, height: 150, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: RawImage(image: l.image, fit: BoxFit.cover))),
      ],);
}

// -- ai ------------------------------------------------------------------------------------

class _Ai extends StatefulWidget {
  const _Ai();

  @override
  State<_Ai> createState() => _AiState();
}

class _AiState extends State<_Ai> {
  late final AiPhaseClock _clock = AiPhaseClock(active: true, kind: AiPhaseKind.picks);

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cap('thinking: 28 px inline, 64 px with the phase line'),
        Row(children: [const ThinkingOrbit(), const SizedBox(width: 16), Expanded(child: PhaseLine(clock: _clock, onRetry: () => _clock.start()))]),
        _cap('machine badge, stale stamp, partial'),
        Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const MachineBadge(streaming: true),
          const MachineBadge(),
          const MachineBadge(alone: true),
          AiStamp(generatedAt: DateTime.now().subtract(const Duration(days: 3))),
          GlassText(glassAiPartialLine, role: gt.typeFootnote, color: gt.colorLabel2),
        ],),
        _cap('AI world card (machine rim)'),
        GlassWorldCard.available(cover: const GalleryCover(6), title: 'Moonlit Bakery', kind: 'Manhwa · Ongoing', stats: '120 ch · ★ 8.4', why: 'Because you read Solo Leveling', source: 'MangaSource', tags: const ['Fantasy'], ai: true, friendName: 'Aiko', onOpen: () {}),
        _cap('unavailable: every reason'),
        for (final r in glassAiReasons.keys) Padding(padding: const EdgeInsets.only(bottom: 8), child: AiNotice(reason: r, long: r != 'offline', retrySeconds: 9, admin: true)),
      ],);
}

// -- charts --------------------------------------------------------------------------------

class _Charts extends StatelessWidget {
  const _Charts();

  static List<ChartDatum> days(int n) {
    final start = DateTime.now().subtract(Duration(days: n - 1));
    return [
      for (var i = 0; i < n; i++)
        ChartDatum(day: DateTime(start.year, start.month, start.day + i), value: i % 6 == 0 ? 0 : ((i * 7) % 23 + 3).toDouble(), second: ((i * 3) % 6).toDouble(), partial: i == n - 1),
    ];
  }

  static String read(ChartDatum d) => d.day == null ? '${d.label} · ${d.value.round()}' : '${d.day!.day}/${d.day!.month} · ${d.value.round()} pages · ${d.second?.round() ?? 0} chapters';

  @override
  Widget build(BuildContext context) {
    final hours = [for (var h = 0; h < 24; h++) ChartDatum(label: hourLabel(h), value: h == 23 ? 42 : (h > 6 && h < 20 ? (h % 5).toDouble() : 1.0 + (h % 3)))];
    final genres = [for (final e in {'Action': 9, 'Fantasy': 14, 'Romance': 4, 'Drama': 7, 'Comedy': 5, 'Horror': 2, 'Sci-fi': 6}.entries) ChartDatum(label: e.key, value: e.value.toDouble())];
    final statuses = [for (final e in {'reading': 12, 'completed': 30, 'on hold': 4, 'plan to read': 18, 'dropped': 3, 'unread': 9}.entries) ChartDatum(label: e.key, value: e.value.toDouble())];
    Widget chart(String id, GlassChartKind k, List<ChartDatum> d, String summary, {String Function(ChartDatum)? readout}) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GlassChart(kind: k, data: d, chartId: id, title: id, summary: summary, readout: readout ?? read, secondHeader: k == GlassChartKind.bars ? 'Chapters' : null, onLabel: (_) {}, emptyText: 'Nothing read in the last 7 days'),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      chart('bars', GlassChartKind.bars, days(30), 'You read 412 pages over 30 days, most on weekdays.'),
      chart('heatmap', GlassChartKind.heatmap, days(90), 'You read on 66 of the last 90 days.'),
      chart('radar', GlassChartKind.radar, genres, 'Fantasy is your top genre, then Action.'),
      chart('clock', GlassChartKind.clock, hours, 'Your reading peaks late in the evening.'),
      chart('sparkline', GlassChartKind.sparkline, days(7), 'Up 12 % on last week.'),
      chart('status', GlassChartKind.statusBars, statuses, '76 series across six statuses.'),
      chart('empty', GlassChartKind.bars, const [], 'No reading in this range.'),
    ],);
  }
}

// -- reactions -----------------------------------------------------------------------------

class _Reactions extends ConsumerStatefulWidget {
  const _Reactions();

  @override
  ConsumerState<_Reactions> createState() => _ReactionsState();
}

class _ReactionsState extends ConsumerState<_Reactions> {
  ReactionKind? _mine;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cap('button: tap sends Love, hold for the six'),
        GlassReactionButton(mine: _mine, onSend: (k) => setState(() => _mine = k), onClear: () => setState(() => _mine = null)),
        _cap('strip: one guarded, one unsealed'),
        GlassReactionStrip(
          reactors: [
            const StripReactor(kind: ReactionKind.hype, name: 'Aiko', preset: GlassAvatarPreset.roseHeart, sealed: false),
            const StripReactor(kind: ReactionKind.tears, name: 'Ren', preset: GlassAvatarPreset.cyanRocket, sealed: false),
            if (_mine != null) StripReactor(kind: _mine!, name: 'You', preset: GlassAvatarPreset.violetSpark, isOwn: true),
          ],
          onSend: (k) => setState(() => _mine = k),
          sourceId: 'demo',
          seriesKey: 'series',
          chapterKey: '211',
          chapterLabel: 'Ch 211',
          mine: _mine,
          completedLocally: true,
        ),
        const SizedBox(height: 12),
        GlassReactionStrip(
          reactors: const [StripReactor(kind: ReactionKind.shook, name: 'Mika', preset: GlassAvatarPreset.amberCoffee, sealed: true)],
          onSend: (_) {},
          sourceId: 'demo',
          seriesKey: 'series',
          chapterKey: '212',
          chapterLabel: 'Ch 212',
          sharingOff: true,
        ),
        GlassText('Snapshots: ${ref.watch(glassSnapshotStoreProvider).length}', role: gt.typeCaption2, color: gt.colorLabel3),
      ],);
}
