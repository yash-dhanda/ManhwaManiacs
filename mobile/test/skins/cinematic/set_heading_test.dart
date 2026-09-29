import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const _style = TextStyle(fontSize: 40, color: Color(0xFFF3F0E8));

Widget _host(ProviderContainer c, Widget child, {bool reduced = false, double scale = 1.0}) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: ThemeData(extensions: const [cinematicTokens]),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
          child: app!,
        ),
        home: Scaffold(body: child),
      ),
    );

SetHeading _h({String text = 'Library', SetTrigger trigger = SetTrigger.inView, int? level = 2, int startDelayMs = 120, bool linked = false}) =>
    SetHeading(text, id: 'h-$text', style: _style, cap: 1.3, level: level, trigger: trigger, startDelayMs: startDelayMs, linked: linked);

List<double> _letters(WidgetTester t) => [
      for (final o in t.widgetList<Opacity>(find.descendant(of: find.byType(SetHeading), matching: find.byType(Opacity)))) o.opacity,
    ];

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  testWidgets('reveals per letter and records the id when it finishes', (t) async {
    await t.pumpWidget(_host(c, ListView(children: [_h()])));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    var o = _letters(t);
    expect(o.length, 7);
    expect(o.first, inExclusiveRange(0, 1));
    expect(o.last, 0);
    expect(c.read(seenHeadingsProvider), isEmpty);
    await t.pump(const Duration(milliseconds: 1100));
    o = _letters(t);
    expect(o.every((v) => v == 1), isTrue);
    expect(c.read(seenHeadingsProvider), contains('h-Library'));

    await t.pumpWidget(_host(c, const SizedBox()));
    await t.pumpWidget(_host(c, ListView(children: [_h()])));
    await t.pump();
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('a heading 3,000 px down starts only when half in view', (t) async {
    final ctl = ScrollController();
    await t.pumpWidget(_host(c, SingleChildScrollView(controller: ctl, child: Column(children: [const SizedBox(height: 3000), _h(), const SizedBox(height: 3000)]))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(_letters(t).every((v) => v == 0), isTrue);
    ctl.jumpTo(2800);
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(_letters(t).first, inExclusiveRange(0, 1));
  });

  testWidgets('a signal heading waits for the push to complete and never writes the seen set', (t) async {
    await t.pumpWidget(_host(c, Builder(builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(body: _h(trigger: SetTrigger.signal)))),
          child: const Text('go'),
        ),),),);
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(_letters(t).every((v) => v == 0), isTrue);
    await t.pump(const Duration(milliseconds: 300)); // push completes
    await t.pump(const Duration(milliseconds: 400));
    expect(_letters(t).first, greaterThan(0));
    await t.pump(const Duration(seconds: 2));
    expect(c.read(seenHeadingsProvider), isEmpty);
  });

  testWidgets('heading semantics in the animating, reduced and seen branches', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(c, ListView(children: [_h()])));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.getSemantics(find.byType(SetHeading)), isSemantics(isHeader: true, label: 'Library'));

    await t.pumpWidget(_host(ProviderContainer(), ListView(children: [_h()]), reduced: true));
    await t.pump();
    expect(t.getSemantics(find.byType(SetHeading)), isSemantics(isHeader: true, label: 'Library'));

    c.read(seenHeadingsProvider.notifier).state = {'h-Library'};
    await t.pumpWidget(_host(c, const SizedBox()));
    await t.pumpWidget(_host(c, ListView(children: [_h()])));
    await t.pump();
    expect(t.getSemantics(find.byType(SetHeading)), isSemantics(isHeader: true, label: 'Library'));
    h.dispose();
  });

  testWidgets('a long word at text scale 2.0 in a 358 px column throws nothing', (t) async {
    await t.pumpWidget(_host(
      c,
      Center(child: SizedBox(width: 358, child: Builder(builder: (context) {
        final cine = context.cine;
        return SetHeading('Transmigration', id: 'tm', style: CineType.style(context, cine.typeCover), cap: cine.typeCover.cap, level: 1, trigger: SetTrigger.mount);
      },),),),
      scale: 2.0,
    ),);
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(t.takeException(), isNull);
  });

  testWidgets('a word that fits no column renders the plain string, no Wrap', (t) async {
    await t.pumpWidget(_host(
      c,
      Center(child: SizedBox(width: 160, child: Builder(builder: (context) {
        final cine = context.cine;
        return SetHeading('Transmigration', id: 'tm', style: CineType.style(context, cine.typeCover), cap: cine.typeCover.cap, level: 1, trigger: SetTrigger.mount);
      },),),),
    ),);
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(find.descendant(of: find.byType(SetHeading), matching: find.byType(Wrap)), findsNothing);
    expect(find.text('Transmigration'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('startDelayMs 0 starts the first letter at once', (t) async {
    await t.pumpWidget(_host(c, ListView(children: [_h(trigger: SetTrigger.mount, startDelayMs: 0)])));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(_letters(t).first, greaterThan(0));
    await t.pumpWidget(_host(ProviderContainer(), ListView(children: [_h(text: 'Another', trigger: SetTrigger.mount)])));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(_letters(t).first, 0);
  });

  testWidgets('level null is not a header', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(c, ListView(children: [_h(level: null)])));
    await t.pump();
    final s = t.getSemantics(find.byType(SetHeading));
    expect(s, isSemantics(label: 'Library'));
    expect(s, isNot(isSemantics(isHeader: true)));
    h.dispose();
  });

  testWidgets('a roman range sets the seed title upright inside an italic head, per letter and at rest', (t) async {
    const text = 'Because you read Sword';
    Widget heading() => SetHeading(text, id: 'h-roman', style: _style.copyWith(fontStyle: FontStyle.italic), cap: 1.3, level: 2, trigger: SetTrigger.mount, roman: (start: 17, end: 22));
    await t.pumpWidget(_host(c, heading()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    List<FontStyle?> styles() => [
          for (final w in t.widgetList<Text>(find.descendant(of: find.byType(SetHeading), matching: find.byType(Text)))) w.style?.fontStyle,
        ];
    final st = styles();
    // 'Because' 'you' 'read' 'Sword' = 7 + 3 + 4 + 5 letters, plus the two spaces between words.
    expect(st.where((f) => f == FontStyle.normal).length, 5);
    await t.pump(const Duration(milliseconds: 1500));
    // At rest (already seen): one Text.rich, the last word upright.
    await t.pumpWidget(_host(c, const SizedBox()));
    await t.pumpWidget(_host(c, heading()));
    await t.pump();
    final rich = t.widget<Text>(find.descendant(of: find.byType(SetHeading), matching: find.byType(Text)).first);
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.map((s) => s.text), ['Because you read ', 'Sword', '']);
    expect(spans[1].style?.fontStyle, FontStyle.normal);
    expect(t.getSemantics(find.byType(SetHeading)).label, text);
  });
}
