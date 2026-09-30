import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_auto_scroll.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_model.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onReady});
  final void Function(NovelAutoScroll, ScrollController) onReady;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  final ScrollController sc = ScrollController();
  late final NovelAutoScroll auto = NovelAutoScroll(scroll: sc, vsync: this, basePxPerSecond: () => novelPxPerSecond(250, 1, 30, 10));

  @override
  void initState() {
    super.initState();
    auto.controller.configure(ramp: const Duration(milliseconds: 400), curve: const Cubic(0.16, 1, 0.3, 1).transform);
    widget.onReady(auto, sc);
  }

  @override
  void dispose() {
    auto.dispose();
    sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(controller: sc, itemCount: 400, itemBuilder: (_, i) => const SizedBox(height: 100)),
      );
}

void main() {
  testWidgets('the measured pace scrolls at wpm x line height / words per line, ends stop it', (tester) async {
    late NovelAutoScroll auto;
    late ScrollController sc;
    await tester.pumpWidget(_Host(onReady: (a, s) {
      auto = a;
      sc = s;
    },),);
    // 250 wpm, 30 px lines, 10 words a line: 12.5 px/s at 1.00x.
    auto.speedX = 2.0;
    auto.start();
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final a = sc.offset;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((sc.offset - a) / 6.0, closeTo(25.0, 1.5));
    auto.controller.touchDown();
    final held = sc.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(sc.offset, held);
    auto.stop();
    expect(auto.running, isFalse);
  });
}
