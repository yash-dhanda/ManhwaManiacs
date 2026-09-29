import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

/// The headings and greetings that already played this session, per profile (glass 10.1, 10.2):
/// `"{profileId}:{screenId}:{headingKey}"` for letter reveals, `"{profileId}:{placement}"` for typing.
/// A plain mutable set, read once in `initState` and never watched: adding to it rebuilds nothing.
final revealedHeadingsProvider = Provider<Set<String>>((ref) => <String>{});

/// The active profile's id, or `anon` before one is chosen (and in tests with no profile store).
String glassProfileId(Ref ref) => _id(() => ref.read(activeProfileProvider)?.id);

/// Same, from a widget's ref.
String glassProfileIdOf(WidgetRef ref) => _id(() => ref.read(activeProfileProvider)?.id);

String _id(Object? Function() read) {
  try {
    return '${read() ?? 'anon'}';
  } catch (_) {
    return 'anon';
  }
}
