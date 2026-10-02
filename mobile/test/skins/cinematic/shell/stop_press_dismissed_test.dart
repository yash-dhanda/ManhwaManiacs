import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';

class _Switchable extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  void switchTo(int id) => state = ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

void main() {
  test('a stop-press dismissal belongs to the profile that dismissed it', () {
    final c = ProviderContainer(overrides: [activeProfileProvider.overrideWith(_Switchable.new)]);
    addTearDown(c.dispose);
    final sub = c.listen(stopPressDismissedProvider, (_, __) {});
    addTearDown(sub.close);
    c.read(stopPressDismissedProvider.notifier).state = 900;
    (c.read(activeProfileProvider.notifier) as _Switchable).switchTo(2);
    expect(c.read(stopPressDismissedProvider), 0);
  });
}
