import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';

import 'cine_harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.pager = true});
  final bool pager;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final c = TabController(length: 3, vsync: this);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        CineContentsTabs(controller: c, tabs: const [
          CineTab(folio: '01', label: 'CHAPTERS', count: 201),
          CineTab(folio: '02', label: 'DETAILS'),
          CineTab(folio: '03', label: 'MORE LIKE THIS'),
        ],),
        Expanded(child: CineTabPanels(controller: c, pager: widget.pager, children: const [Center(child: Text('one')), Center(child: Text('two')), Center(child: Text('three'))])),
      ],);
}

TabController _ctl(WidgetTester t) => (t.state(find.byType(_Host)) as _HostState).c;
double _x(WidgetTester t) => t.getTopLeft(find.byKey(const Key('cine-tab-indicator'))).dx;

void main() {
  testWidgets('the indicator follows the pager while swiping', (t) async {
    await pumpCine(t, const _Host());
    await t.pump(const Duration(milliseconds: 50));
    final x0 = _x(t);
    final g = await t.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(-260, 0));
    await t.pump();
    await t.pump(const Duration(milliseconds: 20));
    expect(_x(t), greaterThan(x0));
    await g.up();
    await t.pumpAndSettle();
    expect(_ctl(t).index, 1);
  });

  testWidgets('a tap slides it and selects the tab', (t) async {
    await pumpCine(t, const _Host());
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.textContaining('DETAILS'));
    await t.pumpAndSettle();
    expect(_ctl(t).index, 1);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('pager: false blocks swipes', (t) async {
    await pumpCine(t, const _Host(pager: false));
    await t.pump(const Duration(milliseconds: 50));
    await t.drag(find.text('one'), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(_ctl(t).index, 0);
  });

  testWidgets('the count is spoken through the label', (t) async {
    await pumpCine(t, const _Host());
    expect(find.bySemanticsLabel(RegExp('Chapters, 201')), findsOneWidget);
  });
}
