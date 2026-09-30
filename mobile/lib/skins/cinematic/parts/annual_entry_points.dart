import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

// The entry points of cinematic 9.2.6 that live on screens other steps built: the shell mounts the
// toast host, Tonight's teaser the December link, Index its row.

/// True in December, once per profile per year: the value stored under
/// `mm.annual.toast.u{user}p{profile}` is the year it last showed.
bool shouldShowAnnualToast(DateTime now, String? storedYear) =>
    now.month == 12 && storedYear != '${now.year}';

/// The per-profile key of the once-a-year toast.
final annualToastKeyProvider =
    Provider<String>((ref) => 'mm.annual.toast.${numbersScopeOf(ref)}');

/// A one-time toast on the first authenticated app open in December,
/// "The Annual 2026 is out." with `Open` (8000 ms `durHoldToastAction`), once per
/// profile per year. Raised from the Cinematic shell.
class AnnualDecemberToastHost extends ConsumerStatefulWidget {
  const AnnualDecemberToastHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AnnualDecemberToastHost> createState() =>
      _AnnualDecemberToastHostState();
}

class _AnnualDecemberToastHostState
    extends ConsumerState<AnnualDecemberToastHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeToast());
  }

  Future<void> _maybeToast() async {
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    final prefs = ref.read(sharedPrefsProvider);
    final key = ref.read(annualToastKeyProvider);
    if (!shouldShowAnnualToast(now, prefs.getString(key))) return;
    await prefs.setString(key, '${now.year}');
    if (!mounted) return;
    ref.read(cineToastsProvider.notifier).action(
          'The Annual ${now.year} is out.',
          label: 'Open',
          onAction: () => context.push<void>(Routes.annual(now.year),
              extra: const <String, String>{'transition': 'dip'},),
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The second quiet link of Tonight's `This week in numbers`, in December.
class AnnualOutLink extends ConsumerWidget {
  const AnnualOutLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    if (now.month != 12) return const SizedBox.shrink();
    return CineButton(
      label: 'The Annual is out →',
      variant: CineButtonVariant.quiet,
      onPressed: () => context.push<void>(Routes.annual(now.year),
          extra: const <String, String>{'transition': 'dip'},),
    );
  }
}
