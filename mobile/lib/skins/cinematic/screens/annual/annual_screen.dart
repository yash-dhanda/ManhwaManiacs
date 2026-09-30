import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_story.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_error_screen.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Annual (ScreenId `annual`, `/library/statistics/annual/:year`; cinematic
/// 9.2.4): a takeover on the root navigator, entered and left by Dip. The Annual
/// is mode-agnostic: it never reads the reading mode.
class AnnualScreen extends ConsumerWidget {
  const AnnualScreen({super.key, required this.yearParam});

  /// The raw `:year` path segment.
  final String yearParam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() =>
        context.canPop() ? context.pop() : context.go(Routes.numbers());
    final year = int.tryParse(yearParam);
    Widget body;
    if (year == null) {
      body = CineErrorScreen.notFound(location: Routes.annual(yearParam));
    } else {
      final async = ref.watch(annualProvider(year));
      body = async.when(
        loading: () => const AnnualLoading(),
        error: (e, _) => e is NetworkError
            ? AnnualOffline(onClose: close)
            : AnnualError(
                onRetry: () => ref.invalidate(annualProvider(year)),
                onClose: close,),
        data: (load) {
          final a = load.data;
          if (a.recordedDays < 7) {
            return AnnualNotEnough(
                recordedDays: a.recordedDays, onClose: close,);
          }
          return AnnualStory(
            key: ValueKey('annual-$year'),
            annual: a,
            profileName: ref.watch(activeProfileProvider)?.name ?? '',
            onClose: close,
            onReadNumbers: () => context.go(Routes.numbers()),
          );
        },
      );
    }
    return Scaffold(backgroundColor: const Color(0xFF000000), body: body);
  }
}
