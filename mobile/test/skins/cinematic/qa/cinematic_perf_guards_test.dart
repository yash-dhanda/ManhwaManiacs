// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/on_screen.dart';

/// G (15.6): the performance guards that a Flutter widget test can prove. The rest are named in
/// `qa.md` with the test that already covers them (sources limiter: `test/core/network/`).
class _Loop extends StatefulWidget {
  const _Loop(this.out);
  final List<AnimationController> out;
  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  @override
  void initState() {
    super.initState();
    widget.out.add(c);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 100);
}

String _read(String p) => File(p).readAsStringSync();

void main() {
  testWidgets('G1: a loop inside OnScreen stops when scrolled away and resumes when back', (t) async {
    final out = <AnimationController>[];
    final ctl = ScrollController();
    await t.pumpWidget(MaterialApp(
      home: SingleChildScrollView(controller: ctl, child: Column(children: [
        OnScreen(builder: (context, on) => TickerMode(enabled: on, child: _Loop(out))),
        const SizedBox(height: 4000),
      ],),),
    ),);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isTrue);
    ctl.jumpTo(3000);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
    // A muted ticker schedules no frames: nothing is running off screen.
    expect(t.binding.hasScheduledFrame, isFalse);
    ctl.jumpTo(0);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isTrue);
  });

  test('G1: Drift, the grain and the streak flame gate on the screen', () {
    expect(_read('lib/skins/cinematic/screens/tonight/../../cine_grain.dart').contains('cineOnScreen'), isTrue);
    expect(_read('lib/skins/cinematic/primitives/streak_flame.dart').contains('OnScreen('), isTrue);
    expect(_read('lib/skins/cinematic/motion.dart').contains('cineOnScreen(context)'), isTrue, reason: 'Drift checks it');
  });

  test('G2: Rack focus runs on at most 12 images at once', () {
    expect(CineMotion.rackCap, 12);
    expect(_read('lib/skins/cinematic/motion.dart').contains('if (_rackRunning >= rackCap) return false;'), isTrue);
  });

  test('G3: duotone matrices are cached per colour and the same instance comes back', () {
    const c = Color(0xFF3355AA);
    expect(identical(duotoneMatrix(c), duotoneMatrix(const Color(0xFF3355AA))), isTrue);
    expect(identical(duotoneMatrix(c), duotoneMatrix(const Color(0xFFAA5533))), isFalse);
  });

  test('G4: the reader page strip has no blur, backdrop, grain, drift or duotone', () {
    for (final f in const [
      'lib/features/reader/engine/reader_engine_view.dart',
      'lib/skins/cinematic/screens/reader/manga_reader.dart',
    ]) {
      final s = _read(f);
      for (final banned in const ['BackdropFilter', 'ImageFiltered', 'ImageFilter.blur', 'CineGrain', 'CineDuotone', 'Drift']) {
        expect(s.contains(banned), isFalse, reason: '$f uses $banned');
      }
    }
  });

  test('G5: page tint samples at most every 600 ms, in compute() on a shared isolate', () {
    expect(ReaderAmbient().sampleInterval, const Duration(milliseconds: 600));
    expect(_read('lib/features/reader/engine/page_analysis.dart').contains('compute(runAnalysis, r)'), isTrue);
  });

  test('G10: rails build lazily and walls use slivers', () {
    expect(_read('lib/skins/cinematic/primitives/cine_rail.dart').contains('ListView.builder'), isTrue);
    expect(_read('lib/skins/cinematic/screens/library/shelf_wall.dart').contains(RegExp(r'SliverGrid|GridView\.builder|SliverList|ListView\.builder|SliverMasonry|SliverPadding')), isTrue);
  });
}
