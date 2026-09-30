// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/features/admin/repositories/admin_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/members_page.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

class _Admin implements AdminRepository {
  final log = <String>[];
  @override
  Future<Result<List<Account>>> listAccounts() async => const Ok([]);
  @override
  Future<Result<Account>> setActive({required int id, required bool active}) async {
    log.add('active $id $active');
    return Ok(Account(id: id, username: 'raghav', isAdmin: false, isActive: active, createdAt: null, lastLoginAt: null, sessionCount: 0));
  }

  @override
  Future<Result<void>> deleteAccount(int id) async {
    log.add('delete $id');
    return const Ok(null);
  }
}

Future<_Admin> pump(WidgetTester t, {SettingsRig? rig, Size size = const Size(390, 844)}) async {
  final repo = _Admin();
  await pumpPage(t, const MembersPage(), rig: rig, size: size, more: [adminRepositoryProvider.overrideWithValue(repo)]);
  return repo;
}

Future<void> tapBtn(WidgetTester t, String label, {int index = 0}) async {
  final b = find.widgetWithText(CineButton, label).at(index);
  Scrollable.ensureVisible(t.element(b), alignment: 0.5, duration: Duration.zero);
  await t.pump();
  await t.tap(b);
  await settle(t, ms: 400);
}

void main() {
  testWidgets('phones: a block per member, the own block first with its actions off and the caption', (t) async {
    await pump(t);
    expect(find.text(kMembersExplainer), findsOneWidget);
    expect(find.byKey(const Key('member-1')), findsOneWidget);
    expect(find.byKey(const Key('member-3')), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('2 sessions'), findsOneWidget);
    expect(find.text('1 session'), findsOneWidget);
    expect(find.text(kOwnAccountLine), findsOneWidget);
    final own = find.descendant(of: find.byKey(const Key('member-1')), matching: find.byType(CineButton));
    for (final b in t.widgetList<CineButton>(own)) {
      expect(b.onPressed, isNull);
    }
    expect(find.text('1 other accounts.'), findsOneWidget);
    expect(t.getTopLeft(find.byKey(const Key('member-1'))).dy, lessThan(t.getTopLeft(find.byKey(const Key('member-3'))).dy));
  });

  testWidgets('tablets: the table sits in its own horizontal scroller, at least 640 wide', (t) async {
    await pump(t, size: const Size(834, 1194));
    final scroller = find.ancestor(of: find.byKey(const Key('member-3')), matching: find.byType(SingleChildScrollView)).first;
    expect(t.widget<SingleChildScrollView>(scroller).scrollDirection, Axis.horizontal);
    expect(t.getSize(find.byKey(const Key('member-3'))).width, greaterThanOrEqualTo(640));
  });

  testWidgets('Deactivate goes straight through; the table refreshes', (t) async {
    final repo = await pump(t);
    await tapBtn(t, 'Deactivate', index: 1);
    expect(repo.log, ['active 3 false']);
  });

  testWidgets('Delete needs the typed username and the arm', (t) async {
    final repo = await pump(t);
    await tapBtn(t, 'Delete', index: 1);
    await settle(t, ms: 500);
    expect(find.text('Delete @raghav?'), findsOneWidget);
    expect(find.textContaining("This can't be undone."), findsOneWidget);
    await t.tap(find.text('Delete account'), warnIfMissed: false);
    await settle(t, ms: 300);
    expect(repo.log, isEmpty);
    await t.enterText(find.byType(EditableText).last, 'raghav');
    await settle(t, ms: 1200);
    await t.tap(find.text('Delete account'));
    await settle(t, ms: 600);
    expect(repo.log, ['delete 3']);
  });

  testWidgets('only your account so far', (t) async {
    await pump(t, rig: SettingsRig(members: [Account(id: 1, username: 'tester', isAdmin: true, isActive: true, createdAt: DateTime.utc(2026), lastLoginAt: null, sessionCount: 1)]));
    expect(find.text('Only your account so far.'), findsOneWidget);
  });

  test('session counts', () {
    expect((sessionsLabel(0), sessionsLabel(1), sessionsLabel(4)), ('No sessions', '1 session', '4 sessions'));
  });

  test('the server line is passed through', () {
    expect(const ApiError(statusCode: 400, code: 'x', message: 'm').userMessage, 'm');
  });
}
