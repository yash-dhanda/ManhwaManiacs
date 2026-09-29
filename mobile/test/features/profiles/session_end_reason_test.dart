import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profile_scope.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements ProfilesRepository {}

void main() {
  testWidgets('a profile-scope rejection sets profileGone; other errors leave it alone', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late WidgetRef captured;
    late ProviderContainer container;
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), profilesRepositoryProvider.overrideWithValue(_Repo())],
      child: Consumer(builder: (context, ref, _) {
        captured = ref;
        container = ProviderScope.containerOf(context);
        return const SizedBox();
      },),
    ),);
    expect(recoverFromProfileScopeError(captured, const TimeoutError()), isFalse);
    expect(container.read(sessionEndReasonProvider), isNull);
    expect(
      recoverFromProfileScopeError(captured, const ApiError(statusCode: 404, code: 'profile_not_found', message: 'x')),
      isTrue,
    );
    expect(container.read(sessionEndReasonProvider), SessionEndReason.profileGone);
  });
}
