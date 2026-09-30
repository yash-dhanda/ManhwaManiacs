import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/auto_download.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/back_order.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/stop_the_press.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/annual_entry_points.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_mood_grade.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// What Android back does on a shell route (cinematic 8.0.5): from a Library hub tab other than
/// SHELF to SHELF, from any other branch root to Tonight, and from Tonight the system takes over.
enum CineBranchBack { system, toShelf, toTonight }

CineBranchBack cineBranchBack(NavInfo info) {
  if (info.branch == null || info.branch == 0) return CineBranchBack.system;
  if (info.branch == 1 && info.hubTab != null && info.hubTab != 0) return CineBranchBack.toShelf;
  return CineBranchBack.toTonight;
}

int? _folioNumber(String? folio) => folio == null ? null : int.tryParse(folio);

/// The `StatefulShellRoute.indexedStack` builder: the branch navigator above the thumb index on a
/// `#000` ground, the mood grade behind the top of Tonight, Library, Discover and Index only, and
/// the section folio the next masthead rolls from. A section change fires `nav.change` and cue
/// `tick`, is a **Cut**, and the new branch's lists run Set (`cineSectionEpochProvider`).
class CineShell extends ConsumerStatefulWidget {
  const CineShell({super.key, required this.navigationShell, required this.location});
  final StatefulNavigationShell navigationShell;
  final String location;

  @override
  ConsumerState<CineShell> createState() => _CineShellState();
}

class _CineShellState extends ConsumerState<CineShell> with WidgetsBindingObserver {
  int _taps = 0;
  bool _whatsNewChecked = false, _arrivalChecked = false;
  int? _previousFolio;
  String? _lastFolio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeWhatsNew()));
    // The edition arrival toast waits for the splash (cinematic 8.30.3).
    ref.listenManual<bool>(splashDoneProvider, (_, done) {
      if (done) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _arrival() : null);
    }, fireImmediately: true,);
  }

  /// After a switch from Glass, once: "Now in the Cinematic edition." with `Undo` for 10 s. A
  /// boot-time mismatch restart and the debug row never write `mm.skin.from`, so they show none.
  void _arrival() {
    if (_arrivalChecked) return;
    _arrivalChecked = true;
    final from = takeSkinArrival(ref.read(sharedPrefsProvider));
    if (from != SkinId.glass.name) return;
    ref.read(cineToastsProvider.notifier).undo(
      'Now in the Cinematic edition.',
      hold: CineDur.holdToastUndo,
      onUndo: () {
        if (!mounted) return;
        cineFeedback(context, HapticEvent.undo);
        unawaited(switchSkinFrom(context, ref, to: SkinId.glass, undoable: false, outgoing: () => StopThePress.outgoing(context)));
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(CineShell old) {
    super.didUpdateWidget(old);
    if (!_whatsNewChecked) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeWhatsNew()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Pending chapter removals must not wait on a timer the OS may never wake.
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(ref.read(pendingRemovalsProvider).flushAll());
      case AppLifecycleState.resumed:
        // Returning after installing a new APK: re-read the package and the version check.
        ref
          ..invalidate(packageInfoProvider)
          ..invalidate(appUpdateProvider);
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// What's new opens by itself once per new build: after the active profile loads, only while a
  /// shell branch route is current (never over a reader, a takeover or a sheet).
  Future<void> _maybeWhatsNew() async {
    if (_whatsNewChecked || !mounted) return;
    if (ref.read(activeProfileProvider) == null) return;
    if (navInfoFor(widget.location).branch == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _whatsNewChecked = true;
    final due = await whatsNewDue(ref);
    if (!due || !mounted) return;
    if (navInfoFor(widget.location).branch == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    await showWhatsNewSheet(context, ref);
  }

  void _select(int i) {
    final shell = widget.navigationShell;
    final reduced = CineMotion.reduced(context);
    if (i != shell.currentIndex) {
      _taps = 0;
      cineFeedback(context, HapticEvent.navChange, sound: SoundEvent.navChange);
      ref.read(cineSectionEpochProvider.notifier).state++;
      shell.goBranch(i);
      return;
    }
    _taps++;
    if (_taps == 1) {
      ref.read(cineScrollRegistryProvider).scrollToTop(i, reduced: reduced);
    } else if (_taps == 2) {
      shell.goBranch(i, initialLocation: true);
    } else if (i == 2) {
      ref.read(focusSearchSignalProvider.notifier).state++;
    }
  }

  void _longPress(int i) {
    cineFeedback(context, HapticEvent.longpressOpen);
    final router = GoRouter.of(context);
    switch (i) {
      case 1:
        router.go(Routes.updates());
      case 3:
        router.go(Routes.downloads({'view': 'queue'}));
      case 4:
        router.push<void>(Routes.profiles(), extra: <String, String>{'mode': 'switch'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = navInfoFor(widget.location);
    final shell = widget.navigationShell;
    if (_lastFolio != info.folio) {
      _previousFolio = _folioNumber(_lastFolio);
      _lastFolio = info.folio;
    }
    final mood = ref.watch(activeProfileProvider.select((p) => p?.mood.wire));
    final grade = const {0, 1, 2, 4}.contains(shell.currentIndex) ? cineMoodColor(mood) : null;
    final unread = ref.watch(unreadNotificationCountProvider);
    final downloads = ref.watch(activeDownloadCountProvider);
    final back = cineBranchBack(info);

    ref.listen(activeProfileProvider, (_, p) {
      if (p != null) unawaited(_maybeWhatsNew());
    });

    final mq = MediaQuery.of(context);
    final body = Stack(children: [
      if (grade != null)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: mq.size.height * 0.3,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [grade, const Color(0xFF000000)]),
              ),
            ),
          ),
        ),
      Positioned.fill(
        child: MediaQuery.removePadding(context: context, removeBottom: true, child: shell),
      ),
    ],);

    return AutoDownloadTrigger(
      onQueued: (n) => ref.read(cineToastsProvider.notifier).info(queuedNewChaptersLine(n)),
      child: AnnualDecemberToastHost(
        child: PopScope(
      canPop: back == CineBranchBack.system,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // A modal state (select mode, the full player, ...) takes the back press first (8.0.5).
        if (ref.read(cineBackOrderProvider.notifier).handleBack()) return;
        final router = GoRouter.of(context);
        router.go(back == CineBranchBack.toShelf ? Routes.library() : Routes.tonight());
      },
      child: Material(
        color: const Color(0xFF000000),
        child: CineSectionFolio(
          previous: _previousFolio,
          current: _folioNumber(info.folio),
          child: Column(children: [
            Expanded(child: body),
            CineThumbIndex(
              active: shell.currentIndex,
              badges: [0, unread, 0, downloads, 0],
              onSelect: _select,
              onLongPress: _longPress,
            ),
          ],),
        ),
      ),
      ),
      ),
    );
  }
}
