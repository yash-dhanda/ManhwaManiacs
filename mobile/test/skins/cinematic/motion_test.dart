import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  setUp(() => MotionRecorder.instance
    ..recording = true
    ..clear(),);
  tearDown(() => MotionRecorder.instance.recording = false);

  testWidgets('play sets the token duration, records planned and ends', (t) async {
    await t.pumpWidget(const MaterialApp(home: _Host()));
    final c = t.state<_HostState>(find.byType(_Host)).c;
    final f = CineMotion.play(MotionName.set, c);
    expect(c.duration, CineDur.column);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await f;
    expect(c.value, 1);
    final e = MotionRecorder.instance.entries.single;
    expect((e.label, e.plannedMs, e.interrupted), ('SET', 320, false));
  });

  testWidgets('calling play again retargets from where it is and records the first as interrupted', (t) async {
    await t.pumpWidget(const MaterialApp(home: _Host()));
    final c = t.state<_HostState>(find.byType(_Host)).c;
    unawaited(CineMotion.play(MotionName.ruleDraw, c));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final mid = c.value;
    expect(mid, inExclusiveRange(0, 1));
    unawaited(CineMotion.play(MotionName.ruleDraw, c, target: 0));
    await t.pump();
    expect(c.value, closeTo(mid, 0.1));
    await t.pump(const Duration(milliseconds: 600));
    expect(c.value, 0);
    expect(MotionRecorder.instance.entries.map((e) => e.interrupted), [true, false]);
  });

  testWidgets('reduced() reads the OS switch', (t) async {
    late bool os, on;
    await t.pumpWidget(MaterialApp(
      builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: a!),
      home: Builder(builder: (c) {
        os = CineMotion.reduced(c);
        return const SizedBox();
      },),
    ),);
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      on = CineMotion.reduced(c);
      return const SizedBox();
    },),),);
    expect((os, on), (true, false));
  });
}
