@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_covers.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/dev/lists_sections.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_phase.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/phase_line.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_strip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/back_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/stack_overview.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// The mobile/28 proof captures (glass 15.8): one per new gallery section at phone and tablet, again with Solid glass and Increase
/// contrast, plus the named mid-motion frames. Written only when `MM_PROOF_DIR` is set.

class _Fixed extends GlassInAppPrefsController {
  _Fixed(this.value);
  final GlassInAppPrefs value;

  @override
  GlassInAppPrefs build() => value;
}

final Override noSensor = glassAccelerometerProvider.overrideWithValue(() => const Stream.empty());
Override prefs(GlassInAppPrefs p) => glassInAppPrefsProvider.overrideWith(() => _Fixed(p));

Widget page(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      builder: (context, home) => GlassRoot(child: home!),
      home: Material(type: MaterialType.transparency, child: child),
    );

Future<void> settleFor(WidgetTester tester, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left < 16 ? left : 16;
    await tester.pump(Duration(milliseconds: step));
    left -= step;
  }
}

Widget screen(Widget child) => ColoredBox(color: Colors.black, child: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: child)));

SwipeAction _act(String id, String label, IconData g, SwipeTone t, {bool destructive = false}) => SwipeAction(id: id, label: label, glyph: g, tone: t, destructive: destructive, run: () async {}, undo: () async {});

Widget _swipeList() => screen(
      GlassSwipeGroup(
        child: Column(children: [
          for (final n in const ['Solo Leveling', 'Tower of God', 'Omniscient Reader'])
            GlassSwipeRow(
              name: n,
              leading: [_act('markRead', 'Mark read', const IconData(0xE184, fontFamily: 'PhosphorRegular'), SwipeTone.success)],
              trailing: [_act('remove', 'Remove', const IconData(0xE4A6, fontFamily: 'PhosphorRegular'), SwipeTone.danger, destructive: true), _act('download', 'Download', const IconData(0xE1AC, fontFamily: 'PhosphorRegular'), SwipeTone.iris)],
              child: GlassListRow(title: n, subtitle: 'Chapter 142', onTap: () {}),
            ),
        ],),
      ),
    );

Future<List<GlassRouteSnapshot>> _levels(WidgetTester tester) async {
  final out = <GlassRouteSnapshot>[];
  await tester.runAsync(() async {
    for (var i = 0; i < 3; i++) {
      final cover = kCalibrationCovers[i * 5 % kCalibrationCovers.length];
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      const size = Size(195, 422);
      canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), cover.palette, const [0, 0.5, 1]));
      final img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
      out.add(GlassRouteSnapshot(routeKey: 'demo$i', title: ['Home', 'Solo Leveling', 'Chapter 142'][i], depth: i, tab: GlassTab.home, rimTint: cover.palette[1], image: img));
    }
  });
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final phone = kSkinShotSizes.firstWhere((s) => s.name == 'phone');
  final tablet = kSkinShotSizes.firstWhere((s) => s.name == 'tablet');

  for (final section in kGlassListsSections) {
    for (final size in [phone, tablet]) {
      testWidgets('$section ${size.name}', (tester) async {
        await captureSkinWidget(tester, name: section, size: size, child: page(GlassGallery(section: section)), overrides: [noSensor], settle: (t) => settleFor(t, 1500));
      });
    }
    testWidgets('$section solid', (tester) async {
      await captureSkinWidget(tester, name: '$section-solid', size: phone, child: page(GlassGallery(section: section)), overrides: [noSensor, prefs(const GlassInAppPrefs(solidGlass: true))], settle: (t) => settleFor(t, 1500));
    });
    testWidgets('$section contrast', (tester) async {
      await captureSkinWidget(tester, name: '$section-contrast', size: phone, child: page(GlassGallery(section: section)), overrides: [noSensor, prefs(const GlassInAppPrefs(increaseContrast: true))], settle: (t) => settleFor(t, 1500));
    });
  }

  testWidgets('swipe tray open', (tester) async {
    await captureSkinWidget(tester, name: 'swipe-tray-open', size: phone, child: page(_swipeList()), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 400);
      await t.drag(find.text('Tower of God'), const Offset(-150, 0));
      await settleFor(t, 700);
    },);
  });

  testWidgets('swipe full commit, mid-flight', (tester) async {
    await captureSkinWidget(tester, name: 'swipe-full-commit', size: phone, child: page(_swipeList()), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 400);
      final g = await t.startGesture(t.getCenter(find.text('Tower of God')));
      await g.moveBy(const Offset(-120, 0));
      await settleFor(t, 32);
      await g.moveBy(const Offset(-170, 0));
      await settleFor(t, 200);
      await g.up();
      await settleFor(t, 60);
    },);
  });

  testWidgets('reorder lift', (tester) async {
    final order = ['Solo Leveling', 'Tower of God', 'Omniscient Reader', 'Lookism', 'Nano Machine', 'Eleceed'];
    await captureSkinWidget(
      tester,
      name: 'reorder-lift',
      size: phone,
      child: page(screen(StatefulBuilder(builder: (context, set) => GlassReorderList<String>(items: order, nameOf: (s) => s, onReorder: (a, b) => set(() => order.insert(b, order.removeAt(a))), itemBuilder: (context, item, i, info) => GlassListRow(title: item, subtitle: 'Position ${i + 1}', trailing: info.handle(), onTap: () {}))))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 400);
        final g = await t.startGesture(t.getCenter(find.byType(GlassIconButton).at(1)));
        await settleFor(t, 100);
        await g.moveBy(const Offset(0, 110));
        await settleFor(t, 300);
        addTearDown(g.up);
      },
    );
  });

  Widget selectScreen(GlassSelectModeController<int> c) {
    final ids = [for (var i = 0; i < 24; i++) i];
    return screen(
      Stack(children: [
        GlassSelectableGroup<int>(
          controller: c,
          ids: ids,
          label: 'Select series',
          child: ListView(padding: const EdgeInsets.only(bottom: 200), children: [
            Wrap(spacing: 8, runSpacing: 12, children: [
              for (final i in ids)
                SizedBox(width: 96, child: GlassSelectableItem<int>(id: i, child: GlassPoster(cover: GalleryCover(i), lMax: kCalibrationCovers[i].lMax, title: kCalibrationCovers[i].title, width: 96, selectMode: c.active, selected: c.isSelected(i), onTap: () {}))),
            ],),
          ],),
        ),
        GlassBulkToolbar<int>(
          controller: c,
          actions: [
            BulkAction<int>(id: 'markRead', label: 'Mark read', glyph: BulkGlyphs.markRead, verb: 'marked read', run: (s, x) async {
              await Future<void>.delayed(const Duration(seconds: 2));
              return BulkResult(ok: s.length - 1, failed: ['${s.first}']);
            },),
            BulkAction<int>(id: 'fav', label: 'Favourite', glyph: BulkGlyphs.favourite, run: (s, x) async => BulkResult(ok: s.length)),
            BulkAction<int>(id: 'add', label: 'Add to collection', glyph: BulkGlyphs.addToCollection, run: (s, x) async => BulkResult(ok: s.length)),
            BulkAction<int>(id: 'rm', label: 'Remove', glyph: BulkGlyphs.remove, destructive: true, run: (s, x) async => BulkResult(ok: s.length)),
          ],
        ),
      ],),
    );
  }

  for (final size in [phone, tablet]) {
    testWidgets('select toolbar ${size.name}', (tester) async {
      final c = GlassSelectModeController<int>()..enter(2);
      c.toggle(3);
      c.toggle(4);
      addTearDown(c.dispose);
      await captureSkinWidget(tester, name: 'select-toolbar', size: size, child: page(selectScreen(c)), overrides: [noSensor], settle: (t) => settleFor(t, 900));
    });
  }

  testWidgets('select running tablet', (tester) async {
    final c = GlassSelectModeController<int>()..enter(2);
    c.toggle(3);
    addTearDown(c.dispose);
    await captureSkinWidget(tester, name: 'select-running', size: tablet, child: page(selectScreen(c)), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 700);
      await t.tap(find.text('Mark read'));
      await settleFor(t, 900);
    },);
  });

  testWidgets('lens offline full', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'lens-offline-full',
      size: phone,
      child: page(GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: "You're offline", description: 'Check your connection. This loads again by itself when you are back.', primary: LensAction('Try again', () {}), onRetry: () async => true)),
      overrides: [noSensor],
      settle: (t) => settleFor(t, 1200),
    );
  });

  Widget gateLauncher() => Builder(builder: (context) => Center(child: TextButton(onPressed: () => unawaited(showMatureGateAlert(context)), child: const Text('open'))));

  testWidgets('gate alert', (tester) async {
    await captureSkinWidget(tester, name: 'gate-alert', size: phone, child: page(gateLauncher()), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 300);
      await t.tap(find.text('open'));
      await settleFor(t, 900);
    },);
  });

  testWidgets('gate alert holding at 700 ms', (tester) async {
    await captureSkinWidget(tester, name: 'gate-alert-holding', size: phone, child: page(gateLauncher()), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 300);
      await t.tap(find.text('open'));
      await settleFor(t, 900);
      final g = await t.startGesture(t.getCenter(find.text('Hold: I am 18 or older')));
      await settleFor(t, 700);
      addTearDown(g.up);
    },);
  });

  testWidgets('download states', (tester) async {
    await captureSkinWidget(tester, name: 'download-states', size: phone, child: page(screen(const GlassGallery(section: 'download'))), overrides: [noSensor], settle: (t) => settleFor(t, 1200));
  });

  testWidgets('depth 1 to 4', (tester) async {
    await captureSkinWidget(tester, name: 'depth-1-to-4', size: phone, child: page(screen(const GlassGallery(section: 'depth'))), overrides: [noSensor], settle: (t) => settleFor(t, 1200));
  });

  testWidgets('stack fan', (tester) async {
    final levels = await _levels(tester);
    await captureSkinWidget(
      tester,
      name: 'stack-fan',
      size: phone,
      child: page(Stack(children: [const ColoredBox(color: Colors.black, child: SizedBox.expand()), GlassStackOverview(levels: levels, onPick: (_) {}, onRemove: (_) {}, onClose: () {})])),
      overrides: [noSensor],
      settle: (t) => settleFor(t, 900),
    );
  });

  testWidgets('stack flat menu', (tester) async {
    final levels = await _levels(tester);
    await captureSkinWidget(
      tester,
      name: 'stack-flat',
      size: phone,
      child: page(Builder(builder: (context) => Align(alignment: Alignment.topLeft, child: Padding(padding: const EdgeInsets.only(top: 60, left: 16), child: TextButton(onPressed: () => unawaited(showGlassBackMenu(context, anchor: const Rect.fromLTWH(16, 60, 44, 44), levels: levels, tabName: 'Home', onPick: (_) {})), child: const Text('back')))))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 300);
        await t.tap(find.text('back'));
        await settleFor(t, 800);
      },
    );
  });

  testWidgets('ai thinking', (tester) async {
    final clock = AiPhaseClock(active: true, kind: AiPhaseKind.picks);
    addTearDown(clock.dispose);
    await captureSkinWidget(tester, name: 'ai-thinking', size: phone, child: page(screen(Center(child: PhaseLine(clock: clock)))), overrides: [noSensor], settle: (t) async {
      await settleFor(t, 2000);
      clock.stop();
    },);
  });

  testWidgets('ai unavailable', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'ai-unavailable',
      size: phone,
      child: page(screen(ListView(children: [for (final r in const ['not_configured', 'budget_exhausted', 'rate_limited', 'offline', 'upstream_error']) Padding(padding: const EdgeInsets.only(bottom: 8), child: AiNotice(reason: r, long: true, retrySeconds: 9, admin: true))]))),
      overrides: [noSensor],
      settle: (t) => settleFor(t, 400),
    );
  });

  testWidgets('charts', (tester) async {
    await captureSkinWidget(tester, name: 'charts', size: phone, child: page(screen(const SingleChildScrollView(child: GlassGallerySection(name: 'charts')))), overrides: [noSensor], settle: (t) => settleFor(t, 1500));
  });

  testWidgets('charts as table', (tester) async {
    final data = [for (var i = 0; i < 8; i++) ChartDatum(day: DateTime(2026, 9, 20 + i), value: i % 3 == 0 ? 0 : (i * 5).toDouble(), second: (i % 4).toDouble())];
    await captureSkinWidget(
      tester,
      name: 'charts-table',
      size: phone,
      child: page(screen(SingleChildScrollView(child: GlassChart(kind: GlassChartKind.bars, data: data, chartId: 'shot', title: 'Pages per day', summary: 'You read 105 pages this week.', readout: (d) => '${d.day!.day} Sep · ${d.value.round()} pages', secondHeader: 'Chapters')))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 900);
        await t.tap(find.text('Show as table'));
        await settleFor(t, 400);
      },
    );
  });

  testWidgets('reaction bloom', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'reaction-bloom',
      size: phone,
      child: page(screen(Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 120), child: GlassReactionButton(onSend: (_) {}, onClear: () {}))))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 400);
        final g = await t.startGesture(t.getCenter(find.byType(GlassReactionButton)));
        await settleFor(t, 900);
        addTearDown(g.up);
      },
    );
  });

  testWidgets('reaction guarded', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'reaction-guarded',
      size: phone,
      child: page(screen(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassReactionStrip(reactors: const [StripReactor(kind: ReactionKind.hype, name: 'Aiko', preset: GlassAvatarPreset.roseHeart, sealed: false), StripReactor(kind: ReactionKind.tears, name: 'Ren', preset: GlassAvatarPreset.cyanRocket, sealed: false)], onSend: (_) {}, sourceId: 's', seriesKey: 'k', chapterKey: '211', chapterLabel: 'Ch 211', completedLocally: true, mine: ReactionKind.loved),
        const SizedBox(height: 24),
        GlassReactionStrip(reactors: const [StripReactor(kind: ReactionKind.shook, name: 'Mika', preset: GlassAvatarPreset.amberCoffee, sealed: true)], onSend: (_) {}, sourceId: 's', seriesKey: 'k', chapterKey: '212', chapterLabel: 'Ch 212', sharingOff: true),
      ],),),),
      overrides: [noSensor],
      settle: (t) => settleFor(t, 700),
    );
  });
}
