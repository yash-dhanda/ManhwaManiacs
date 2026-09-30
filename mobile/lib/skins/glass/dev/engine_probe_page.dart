import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/dev/long_strip_fixture.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';

/// `/dev/glass/reader-engine`: `ReaderEngineView` with plain slots and no chrome, and a readout of the five
/// engine fields and the last seam, neighbour and cruise events. `?fixture=long-strip` opens the 120-page
/// fixture; `?source=&series=&chapter=` opens a real chapter; `&mode=continuous|single`.
class EngineProbePage extends ConsumerStatefulWidget {
  const EngineProbePage({super.key, this.params = const {}});
  final Map<String, String> params;

  @override
  ConsumerState<EngineProbePage> createState() => _EngineProbePageState();
}

class _EngineProbePageState extends ConsumerState<EngineProbePage> {
  final ReaderEngine _engine = ReaderEngine();
  ReaderFeed? _feed;
  Object? _error;
  String _events = '';
  final List<StreamSubscription<Object>> _subs = [];

  ReaderChapterMode get _mode => widget.params['mode'] == 'single' ? ReaderChapterMode.single : ReaderChapterMode.continuous;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_engine.seamEvents.listen((e) => _log('seam $e')))
      ..add(_engine.neighbourEvents.listen((e) => _log('neighbour $e')))
      ..add(_engine.cruiseEngagedEvents.listen((e) => _log('cruise ${e.multiplier}x')));
    unawaited(_load());
  }

  void _log(String s) => setState(() => _events = s);

  Future<void> _load() async {
    try {
      if (widget.params['fixture'] == 'long-strip') {
        final feed = await buildLongStripFeed();
        if (mounted) setState(() => _feed = feed);
        return;
      }
      final key = (
        sourceId: widget.params['source'] ?? '',
        seriesKey: widget.params['series'] ?? '',
        chapterKey: widget.params['chapter'] ?? '',
      );
      final r = await ref.read(resolvedReaderChapterProvider(key).future);
      if (mounted) setState(() => _feed = ReaderFeed.of([r.chapter]));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<ReaderChapter?> _neighbour(NeighbourDirection d) async {
    if (widget.params['fixture'] == 'long-strip') return buildLongStripNeighbour(d == NeighbourDirection.next ? 'next' : 'prev');
    final cur = _feed?.chapters.first;
    final id = d == NeighbourDirection.next ? cur?.nextChapterId : cur?.previousChapterId;
    if (id == null) return null;
    final r = await ref.read(resolvedReaderChapterProvider((
      sourceId: widget.params['source'] ?? '',
      seriesKey: widget.params['series'] ?? '',
      chapterKey: id,
    ),).future,);
    return r.chapter;
  }

  /// Drives the strip to its end at 6,000 px/s inside a recorder entry named `STRIP SCROLL 120`.
  Future<void> _run() async {
    final size = MediaQuery.sizeOf(context);
    final feed = _feed!;
    // Every page is 4x as tall as the column is wide on the fixture; other chapters use their length in pages.
    final distance = feed.length * (size.width < 768 ? size.width : 768) * 4;
    final ms = (distance / 6000 * 1000).round();
    final rec = GlassMotionRecorder.instance..attach();
    final entry = rec.begin('STRIP SCROLL 120', ms);
    // scrollByViewport clamps at the end of the strip.
    _engine.scrollByViewport(distance / size.height, duration: Duration(milliseconds: ms), curve: Curves.linear);
    await Future<void>.delayed(Duration(milliseconds: ms + 100));
    rec.end(entry);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    if (feed == null) {
      return ColoredBox(color: Colors.black, child: Center(child: Text(_error == null ? 'Loading' : 'Failed: $_error', style: const TextStyle(color: Colors.white70))));
    }
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: ReaderEngineView(
              controller: _engine,
              slots: const ReaderSurfaceSlots(chapterSeam: _seam, brokenPage: _broken, pagedCornerRadius: 0),
              autoHideAfter: const Duration(hours: 1),
              chromeBuilder: (context, state) => const SizedBox.shrink(),
              feed: feed,
              scrollStorageKey: 'glass-engine-probe',
              onBack: () => Navigator.of(context).maybePop(),
              onOpenSeries: () {},
              chapterMode: _mode,
              loadNeighbour: _neighbour,
              onReplaceChapter: (c) => _log('replace ${c.chapterKey}'),
            ),
          ),
          _Readout(engine: _engine, events: _events, onRun: _run),
        ],
      ),
    );
  }
}

Widget _seam(BuildContext c, ReaderChapter ch, Axis a) => const SizedBox(height: 96, child: ColoredBox(color: Color(0xFF333333)));
Widget _broken(BuildContext c, VoidCallback retry) => const ColoredBox(color: Color(0xFF552222));

class _Readout extends StatelessWidget {
  const _Readout({required this.engine, required this.events, required this.onRun});
  final ReaderEngine engine;
  final String events;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 11, height: 16 / 11, color: Colors.white);
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<ReaderEngineState>(
                valueListenable: engine,
                builder: (context, s, _) => Text(
                  'sample ${s.currentPageSample == null ? '-' : '${s.currentPageSample!.source.name} pTop ${s.currentPageSample!.pTop.toStringAsFixed(2)}'}\n'
                  'velocity(state) ${s.scrollVelocity.toStringAsFixed(0)}  seam(state) ${s.seamProgress?.toStringAsFixed(2) ?? '-'}  overscroll(state) ${s.overscrollExtent.toStringAsFixed(1)}\n'
                  'panelBoxes ${s.panelBoxes?.length ?? '-'}  page ${s.page}/${s.pageCount}',
                  style: mono,
                ),
              ),
              ListenableBuilder(
                listenable: Listenable.merge([engine.live.scrollVelocity, engine.live.seamProgress, engine.live.overscrollExtent]),
                builder: (context, _) => Text(
                  'live v ${engine.live.scrollVelocity.value.toStringAsFixed(0)}  seam ${engine.live.seamProgress.value?.toStringAsFixed(2) ?? '-'}  over ${engine.live.overscrollExtent.value.toStringAsFixed(1)}',
                  style: mono,
                ),
              ),
              Text('last event: $events', style: mono),
              Row(children: [
                DevButton(label: 'Run 120-page scroll', onTap: onRun),
                const SizedBox(width: 8),
                DevButton(
                  label: 'Copy log',
                  onTap: () => Clipboard.setData(ClipboardData(text: GlassMotionRecorder.instance.toJsonLog())),
                ),
              ],),
            ],
          ),
        ),
      ),
    );
  }
}
