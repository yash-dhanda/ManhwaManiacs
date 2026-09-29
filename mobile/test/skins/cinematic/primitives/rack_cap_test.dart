import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

void main() {
  testWidgets('20 images decode at once: 12 rack, 8 develop', (t) async {
    MotionRecorder.instance
      ..recording = true
      ..clear();
    addTearDown(() => MotionRecorder.instance.recording = false);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      home: Scaffold(
        body: Wrap(children: [for (var i = 0; i < 20; i++) const CineRackImage(child: SizedBox(width: 10, height: 10))]),
      ),
    ),);
    await t.pump();
    expect(CineMotion.rackRunning, 12);
    await t.pump(const Duration(milliseconds: 700));
    final labels = MotionRecorder.instance.entries.map((e) => e.label).toList();
    expect(labels.where((l) => l == 'RACK FOCUS'), hasLength(12));
    expect(labels.where((l) => l == 'DEVELOP'), hasLength(8));
    expect(CineMotion.rackRunning, 0);
  });
}
