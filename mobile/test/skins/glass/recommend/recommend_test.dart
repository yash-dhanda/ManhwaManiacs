import 'dart:ui' show Tristate;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart' show pendingLettersProvider;
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart' show librarySeriesPickerProvider;
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/letter_schedule.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_orbs.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/circle/fakes.dart';
import '../primitives/support.dart';

const _on = CircleShares(activity: true, reactions: true, shelves: true, recommendations: true);
const _off = CircleShares(activity: true, reactions: true, shelves: true);

List<CircleMember> _members() => const [
      CircleMember(profileId: 2, name: 'Aarav', shares: _on, canReceive: true),
      CircleMember(profileId: 3, name: 'Mira', shares: _off, canReceive: false),
      CircleMember(profileId: 4, name: 'Kai', shares: _on, canReceive: false),
    ];

Future<(FakeCircleRepository, ProviderContainer)> pumpSheet(WidgetTester t, {int? to, AppError? fail, bool offline = false, TargetPlatform platform = TargetPlatform.iOS}) async {
  final repo = FakeCircleRepository(membersList: _members())..failSend = fail;
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(primHost(
    Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => RecommendSheetBody(series: 's:solo', title: 'Solo Leveling', to: to))),
    align: false,
    platform: platform,
    overrides: [circleRepositoryProvider.overrideWithValue(repo), glassOfflineProvider.overrideWithValue(offline)],
  ),);
  await pumpFor(t, 300);
  return (repo, ProviderScope.containerOf(t.element(find.byType(RecommendSheetBody))));
}

void main() {
  testWidgets('the sheet: disabled members say why, gated members are absent, Send posts once and says who', (t) async {
    final (repo, c) = await pumpSheet(t);
    expect(find.text("Mira isn't taking recommendations"), findsOneWidget);
    expect(find.text('Kai'), findsNothing);
    expect(find.textContaining('Kai'), findsNothing);
    await t.tap(find.bySemanticsLabel('Aarav'));
    await pumpFor(t, 200);
    await t.tap(find.text('Send'));
    await pumpFor(t, 1200);
    expect(repo.sent, hasLength(1));
    expect(repo.sent.single.to, [2]);
    expect(c.read(glassToastProvider).map((e) => e.spec.message), contains('Sent to Aarav'));
  });

  testWidgets('409 recipient_unavailable deselects that orb with the toast', (t) async {
    final h = t.ensureSemantics();
    final (_, c) = await pumpSheet(t, to: 2, fail: const ApiError(statusCode: 409, code: 'recipient_unavailable', message: 'x', details: {'profile_ids': [2]}));
    await t.tap(find.text('Send'));
    await pumpFor(t, 600);
    expect(c.read(glassToastProvider).map((e) => e.spec.message), contains("Aarav isn't taking recommendations any more."));
    final orb = t.getSemantics(find.bySemanticsLabel('Aarav'));
    expect(orb.getSemanticsData().flagsCollection.isToggled, Tristate.isFalse);
    h.dispose();
  });

  testWidgets('the pick step searches the whole library, past its first page', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    FollowedSeries f(int i) => FollowedSeries(id: i, sourceId: 's', seriesKey: 'k$i', title: 'Series $i', coverUrl: '', isFavorite: false, readingStatus: 'unread', notify: false, sortOrder: 0, contentRating: 'safe', rating: 'safe', chapterCount: 1, createdAt: DateTime(2024), updatedAt: DateTime(2024));
    await t.pumpWidget(primHost(
      Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const RecommendSheetBody(to: 2))),
      align: false,
      overrides: [
        circleRepositoryProvider.overrideWithValue(FakeCircleRepository(membersList: _members())),
        librarySeriesPickerProvider.overrideWith((ref) async => [for (var i = 0; i < 30; i++) f(i)]),
      ],
    ),);
    await pumpFor(t, 300);
    await t.enterText(find.byType(EditableText), 'series 27');
    await pumpFor(t, 300);
    expect(find.text('Series 27'), findsWidgets);
  });

  testWidgets('to= preselects the friend (the pick step from the friend sheet)', (t) async {
    final h = t.ensureSemantics();
    await pumpSheet(t, to: 2);
    expect(t.getSemantics(find.bySemanticsLabel('Aarav')).getSemanticsData().flagsCollection.isToggled, Tristate.isTrue);
    h.dispose();
  });

  testWidgets('hit targets on the recommend sheet at 390 x 844', (t) async {
    final h = t.ensureSemantics();
    await pumpSheet(t, to: 2);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await pumpSheet(t, to: 2, platform: TargetPlatform.android);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    h.dispose();
  });

  testWidgets('offline: Recommending needs a connection, Send disabled', (t) async {
    final (repo, _) = await pumpSheet(t, to: 2, offline: true);
    expect(find.text('Recommending needs a connection'), findsOneWidget);
    await t.tap(find.text('Send'), warnIfMissed: false);
    await pumpFor(t, 300);
    expect(repo.sent, isEmpty);
  });

  group('drag path', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer make(FakeCircleRepository repo) {
      final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo), sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      return c;
    }

    test('the letter posts once when the 10 s Undo window ends', () => fakeAsync((a) {
          final repo = FakeCircleRepository();
          final c = make(repo);
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'k');
          a.elapse(const Duration(milliseconds: 9900));
          expect(repo.sent, isEmpty);
          a.elapse(const Duration(milliseconds: 200));
          a.flushMicrotasks();
          expect(repo.sent, hasLength(1));
          a.elapse(const Duration(seconds: 30));
          expect(repo.sent, hasLength(1));
        }),);

    test('Undo sends none', () => fakeAsync((a) {
          final repo = FakeCircleRepository();
          final c = make(repo);
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'k');
          expect(c.read(glassToastProvider.notifier).undoLast(), isTrue);
          a.elapse(const Duration(seconds: 30));
          expect(repo.sent, isEmpty);
        }),);

    test('Add a note holds the letter; Send sends it at once with the note', () => fakeAsync((a) {
          final repo = FakeCircleRepository();
          final c = make(repo);
          var opened = 0;
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'k', onAddNote: () => opened++);
          c.read(glassToastProvider).single.spec.onAction!();
          a.elapse(const Duration(seconds: 30));
          expect(repo.sent, isEmpty, reason: 'held while the note is written');
          c.read(heldLetterProvider)!.sendWithNote('The tower arc');
          a.flushMicrotasks();
          expect(opened, 1);
          expect(repo.sent.single.note, 'The tower arc');
        }),);

    test('an app pause inside the window sends it', () => fakeAsync((a) {
          final repo = FakeCircleRepository();
          final c = make(repo);
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'k');
          a.elapse(const Duration(seconds: 2));
          c.read(pendingLettersProvider.notifier).didChangeAppLifecycleState(AppLifecycleState.paused);
          a.flushMicrotasks();
          expect(repo.sent, hasLength(1));
          a.elapse(const Duration(seconds: 30));
          expect(repo.sent, hasLength(1));
        }),);

    test('the gate-close purge drops mature pending letters and mature outbox reactions', () => fakeAsync((a) {
          final repo = FakeCircleRepository();
          final box = ReactionOutbox(prefs, 'u1p1');
          final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo), sharedPrefsProvider.overrideWithValue(prefs), reactionOutboxProvider.overrideWithValue(box)]);
          addTearDown(c.dispose);
          box.enqueue(OutboxEntry(sourceId: 's', seriesKey: 'adult', chapterKey: '1', kind: ReactionKind.hype, at: DateTime.utc(2026), mature: true));
          box.enqueue(OutboxEntry(sourceId: 's', seriesKey: 'safe', chapterKey: '1', kind: ReactionKind.loved, at: DateTime.utc(2026)));
          a.flushMicrotasks();
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'adult', mature: true);
          scheduleLetter(c, toProfileId: 2, toName: 'Aarav', sourceId: 's', seriesKey: 'safe');
          c.read(_purgeProbe)();
          a.flushMicrotasks();
          expect(box.entries().map((e) => e.seriesKey), ['safe']);
          a.elapse(const Duration(seconds: 30));
          expect(repo.log.where((l) => l.startsWith('send')), hasLength(1));
        }),);
  });

  test('the magnet captures within 64 px and not at 65', () {
    final m = Magnet();
    m.step(const Offset(0, 64), const [MagnetTarget(Offset.zero, 2)]);
    expect(m.captured?.id, 2);
    final n = Magnet();
    n.step(const Offset(0, 65), const [MagnetTarget(Offset.zero, 2)]);
    expect(n.captured, isNull);
  });
}

final _purgeProbe = Provider<void Function()>((ref) => () => purgeCircleMature(ref));
