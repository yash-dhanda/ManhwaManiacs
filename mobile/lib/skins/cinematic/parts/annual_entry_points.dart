import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/toast.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

// The entry points of cinematic 9.2.6 that live on screens other steps build.
// They are built and tested here so those steps only mount them.
// TODO(mobile/06): mount `AnnualDecemberToastHost` in the Cinematic shell.
// TODO(mobile/08): Tonight's `This week in numbers` mounts `AnnualOutLink` in December.
// TODO(mobile/17): the Index row `The Annual ...... 2026` uses `Routes.annual(year)`.

/// True in December, once per profile per year: the value stored under
/// `mm.annual.toast.u{user}p{profile}` is the year it last showed.
bool shouldShowAnnualToast(DateTime now, String? storedYear) => now.month == 12 && storedYear != '${now.year}';

/// The per-profile key of the once-a-year toast.
final annualToastKeyProvider = Provider<String>((ref) => 'mm.annual.toast.${numbersScopeOf(ref)}');

/// A one-time toast on the first authenticated app open in December,
/// "The Annual 2026 is out." with `Open` (8000 ms `durHoldToastAction`), once per
/// profile per year. Raised from the Cinematic shell.
class AnnualDecemberToastHost extends ConsumerStatefulWidget {
  const AnnualDecemberToastHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AnnualDecemberToastHost> createState() => _AnnualDecemberToastHostState();
}

class _AnnualDecemberToastHostState extends ConsumerState<AnnualDecemberToastHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeToast());
  }

  Future<void> _maybeToast() async {
    if (!mounted) return;
    final now = ref.read(numbersNowProvider)();
    final prefs = ref.read(sharedPrefsProvider);
    final key = ref.read(annualToastKeyProvider);
    if (!shouldShowAnnualToast(now, prefs.getString(key))) return;
    await prefs.setString(key, '${now.year}');
    if (!mounted) return;
    showCineToast(
      context,
      'The Annual ${now.year} is out.',
      duration: CineDur.holdToastAction,
      actionLabel: 'Open',
      onAction: () => context.push(Routes.annual(now.year)),
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
    final now = ref.watch(numbersNowProvider)();
    if (now.month != 12) return const SizedBox.shrink();
    return CineButton('The Annual is out →', small: true, kind: CineButtonKind.quiet, onPressed: () => context.push(Routes.annual(now.year)));
  }
}

/// The Index row's trailing folio: `12-DAY STREAK`, or the year.
String indexNumbersFolio(int streakDays) => streakDays > 0 ? '$streakDays-DAY STREAK' : '';

