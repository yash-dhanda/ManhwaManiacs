import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/notification_list.dart';

class _FailingLibrary implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      i.memberName == #patchSeries ? Future<Result<FollowedSeries>>.value(const Err(TimeoutError())) : super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed notify toggle says so', () async {
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(_FailingLibrary())]);
    addTearDown(c.dispose);
    final ok = await c.read(glassUpdatesNotifyProvider)(1, false, confirm: 'Notifications off');
    expect(ok, isFalse);
    expect(c.read(glassToastProvider).single.spec.kind, GlassToastKind.error);
  });
}
