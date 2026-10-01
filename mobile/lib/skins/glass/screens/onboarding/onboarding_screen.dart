import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconRole;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';
import 'package:manhwamaniacs/skins/glass/screens/nav_bits.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/glass_steps.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/step_dots.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/done.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/formats.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/genre_field_step.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/look.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/seeds.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/styles.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/steps/welcome.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Onboarding at `/welcome?step=1..7` (glass 8.7, mobile S06 and S07): a takeover on the brand aurora with seven droplet dots, a
/// nav row, one lit "Continue", and a page per step, resuming from `onboarding_step`.
class GlassOnboardingScreen extends ConsumerStatefulWidget {
  const GlassOnboardingScreen({super.key, this.step});
  final int? step;

  @override
  ConsumerState<GlassOnboardingScreen> createState() => _GlassOnboardingScreenState();
}

class _GlassOnboardingScreenState extends ConsumerState<GlassOnboardingScreen> with TickerProviderStateMixin {
  PageController? _pages;
  int? _step;
  bool _lookShown = true;
  bool _edgeBlock = false;
  bool _leaving = false;
  final GlobalKey _dotsKey = GlobalKey();
  late final AnimationController _merge;

  @override
  void initState() {
    super.initState();
    _merge = AnimationController(vsync: this); // eager: a lazy controller built inside dispose() reads a deactivated ancestor
  }

  @override
  void dispose() {
    _pages?.dispose();
    _merge.dispose();
    super.dispose();
  }

  List<int> get _shown => shownGlassSteps(lookShown: _lookShown);

  void _init(Profile p) {
    if (_step != null) return;
    _lookShown = glassLookShownOf(ref);
    final pending = ref.read(onboardingStoreProvider).readPending();
    if (!needsOnboarding(p, pending)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.tonight());
      });
      _step = 1;
      _pages = PageController();
      return;
    }
    _step = entryGlassStep(widget.step, p.onboarding, lookShown: _lookShown);
    _pages = PageController(initialPage: _shown.indexOf(_step!).clamp(0, _shown.length - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(glassOnboardingFlowProvider.notifier)
        ..enter(_step!)
        ..restore();
      if (widget.step != _step) context.replace(Routes.onboarding({'step': _step}));
    });
  }

  Future<void> _go(int step, {bool save = true}) async {
    final i = _shown.indexOf(step);
    if (i < 0 || _step == step) return;
    setState(() => _step = step);
    final c = _pages!;
    if (glassReduced(ref)) {
      c.jumpToPage(i);
    } else {
      unawaited(c.animateToPage(i, duration: const Duration(milliseconds: 615), curve: Curves.easeOutCubic));
    }
    final flow = ref.read(glassOnboardingFlowProvider.notifier)..enter(step);
    if (save && step <= 7) flow.commit(step);
    if (mounted) context.replace(Routes.onboarding({'step': step}));
    if (step == 7) unawaited(_runDone());
  }

  void _next() {
    final s = _step!;
    if (s == 6) return unawaited(_finish());
    final n = nextGlassStep(s, lookShown: _lookShown);
    if (n != null) unawaited(_go(n));
  }

  void _prev() {
    final p = prevGlassStep(_step!, lookShown: _lookShown);
    if (p != null) unawaited(_go(p, save: false));
  }

  Future<void> _skipAll() async {
    if (_leaving) return;
    _leaving = true;
    final saving = ref.read(glassOnboardingFlowProvider.notifier).saveDone();
    await Future.any<Object?>([saving, Future<void>.delayed(const Duration(milliseconds: 1500))]);
    if (mounted) context.go(Routes.tonight());
  }

  Future<void> _finish() async {
    if (_leaving) return;
    unawaited(ref.read(glassOnboardingFlowProvider.notifier).saveDone());
    await _go(7, save: false);
  }

  /// Step 7: the Dots merge, the droplet's fall into Home, then Home types its greeting.
  Future<void> _runDone() async {
    if (_leaving) return;
    _leaving = true;
    final reduced = glassReduced(ref);
    await Future<void>.delayed(Duration(milliseconds: reduced ? 200 : 900));
    if (!mounted) return;
    final target = glassFlightTarget(context, tab: GlassTab.home, sidebarHome: true);
    final from = globalRectOfKey(_dotsKey);
    if (reduced || from == null) {
      ref.read(glassArrivalProvider.notifier).state = GlassArrival(kind: GlassArrivalKind.onboarding, point: target.center);
      context.go(Routes.tonight());
      return;
    }
    await GlassMotion.play(MotionName.dotsMerge, controller: _merge, target: 1);
    if (!mounted) return;
    final droplet = Rect.fromCenter(center: from.center, width: 8, height: 8);
    final land = Rect.fromCenter(center: target.center, width: 8, height: 8);
    await ref.read(glassEffectsProvider).flyOrb(
          from: droplet,
          to: land,
          orb: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris400, shape: BoxShape.circle)),
        );
    if (!mounted) return;
    ref.read(glassArrivalProvider.notifier).state = GlassArrival(kind: GlassArrivalKind.onboarding, point: target.center);
    context.go(Routes.tonight());
  }

  /// Look: Glass carries on to Formats. Cinematic queues the profile's skin (the outbox wins at boot), saves the answers with
  /// Cinematic's Formats step (Cinematic numbers 1 Edition, 2 Formats), melts and restarts into Cinematic at that step with the
  /// session carried, so the run neither signs out nor repeats the pick.
  Future<void> _chooseLook(String skin, Profile p) async {
    if (_leaving) return;
    final flow = ref.read(glassOnboardingFlowProvider.notifier)..setSkin(skin);
    if (skin == 'glass') return _next();
    _leaving = true;
    const cinematicFormats = 2;
    final outbox = ref.read(skinOutboxProvider);
    await outbox.enqueue(p.id, SkinId.cinematic);
    unawaited(outbox.flush());
    flow.commit(cinematicFormats);
    await flow.flush();
    if (!mounted) return;
    await playMelt(ref);
    // An explicit choice on this device: the icon follows only while `mm.icon.follow` is on (glass 12.2).
    await ref.read(appIconSwitcherProvider).onExplicitSkinChoice(SkinId.cinematic);
    if (mounted) await restartIntoSkin(context, ref, SkinId.cinematic, returnRoute: Routes.onboarding({'step': cinematicFormats}));
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesProvider).valueOrNull;
    final profile = profiles?.where((p) => p.id == active?.id).firstOrNull;
    if (profile == null) {
      // The profile is still loading, or there is none: the guard routes a signed-in reader without one to the picker.
      return const SizedBox.shrink();
    }
    _init(profile);
    final state = ref.watch(glassOnboardingFlowProvider);
    final flow = ref.read(glassOnboardingFlowProvider.notifier);
    ref.listen<AsyncValue<bool>>(networkOnlineChangesProvider, (prev, next) {
      if ((next.valueOrNull ?? false) && ref.read(glassOnboardingFlowProvider).dirty) unawaited(flow.flush());
    });
    final step = _step!;
    final dots = dotsFor(step, lookShown: _lookShown);
    final margin = GlassFrame.screenMargin(context);
    final mq = MediaQuery.of(context);
    final wide = mq.size.shortestSide >= 600;
    final first = prevGlassStep(step, lookShown: _lookShown) == null;
    final label = switch (step) { 1 => 'Start', 6 => 'Finish', _ => 'Continue' };
    final canContinue = step != 6 || state.picks.any((p) => !p.failed);
    final shapes = <SkinGlassShape>[];
    final aligns = <Alignment>[];
    if (!first) {
      shapes.add(SkinGlassShape(size: Size.square(glassBarHeight(context)), shape: const GlassShape.circle(), child: GlassBarIcon(icon: roleIcon(GlassIconRole.back), label: 'Previous step', onPressed: _prev)));
      aligns.add(Alignment.centerLeft);
    }
    shapes.add(glassTextShape(context, 'Skip', () => unawaited(_skipAll())));
    aligns.add(Alignment.centerRight);

    Widget page(int s) {
      final scroll = s != 4 && s != 6 && s != 7;
      final child = switch (s) {
        1 => GlassWelcomeStep(name: profile.name),
        2 => GlassLookStep(skin: state.skin, profileId: profile.id, onChoose: (v) => unawaited(_chooseLook(v, profile))),
        3 => GlassFormatsStep(selected: state.taste.formats, onToggle: flow.toggleFormat),
        4 => GlassGenreStep(weights: state.weights, onWeight: flow.setGenreWeight, visible: step == 4),
        5 => GlassStylesStep(selected: state.taste.styles, onToggle: flow.toggleStyle),
        6 => const GlassSeedsStep(),
        _ => const GlassDoneStep(),
      };
      final pad = EdgeInsets.fromLTRB(margin, mq.padding.top + 104, margin, mq.padding.bottom + 96);
      final Widget body = scroll || s == 6 ? SingleChildScrollView(padding: pad, child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 640 : double.infinity), child: child))) : Padding(padding: pad, child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity), child: child)));
      return body;
    }

    final view = Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerDown: (e) => setState(() => _edgeBlock = e.position.dx < 24),
          onPointerUp: (_) => setState(() => _edgeBlock = false),
          onPointerCancel: (_) => setState(() => _edgeBlock = false),
          child: PageView(
            controller: _pages,
            physics: _edgeBlock || step == 4 || step == 6 || step == 7 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            onPageChanged: (i) {
              final s = _shown[i];
              if (s != _step) {
                setState(() => _step = s);
                flow.enter(s);
                flow.commit(s);
                context.replace(Routes.onboarding({'step': s}));
              }
            },
            children: [for (final s in _shown) page(s)],
          ),
        ),
        Positioned(
          top: mq.padding.top + 12,
          left: 0,
          right: 0,
          child: Center(
            child: KeyedSubtree(
              key: _dotsKey,
              child: AnimatedBuilder(animation: _merge, builder: (context, _) => StepDots(index: dots.index, total: dots.total, merge: _merge.value)),
            ),
          ),
        ),
        if (step != 7) Positioned(top: mq.padding.top + 36, left: margin, right: margin, height: glassBarHeight(context), child: SkinGlassGroup(shapes: shapes, aligns: aligns, height: glassBarHeight(context), debugLabel: 'onboarding-nav')),
        if (step != 7)
          Positioned(
            left: wide ? (mq.size.width - 320) / 2 : margin,
            right: wide ? (mq.size.width - 320) / 2 : margin,
            // Wide frames keep floating controls out of the 24 px bottom band (glass 2.2, 14.4), as the floating bar does.
            bottom: mq.padding.bottom + (wide ? 24 : 16),
            child: GlassButton(label: label, variant: GlassButtonVariant.primary, size: GlassButtonSize.large, fullWidth: true, onPressed: canContinue ? _next : null),
          ),
      ],
    );

    return PopScope(
      canPop: first,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prev();
      },
      child: RegisteredShortcuts(
        group: 'Onboarding',
        entries: [
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Continue', keys: const ['Enter'], onInvoke: () {
            if (canContinue && step != 7) _next();
          },),
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Skip this step', keys: const ['Esc'], onInvoke: () {
            if (step == 6) {
              unawaited(_finish());
            } else {
              final n = nextGlassStep(step, lookShown: _lookShown);
              if (n != null) unawaited(_go(n, save: false));
            }
          },),
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.enter, control: true), description: 'Finish', keys: const ['Ctrl', 'Enter'], onInvoke: () => unawaited(_finish())),
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.enter, meta: true), description: 'Finish', keys: const ['⌘', 'Enter'], onInvoke: () => unawaited(_finish())),
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.arrowRight), description: 'Next step', keys: const ['→'], onInvoke: () {
            if (step != 6 && step != 7) _next();
          },),
          ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.arrowLeft), description: 'Previous step', keys: const ['←'], onInvoke: _prev),
        ],
        child: Material(type: MaterialType.transparency, child: GlassAmbientScope(spec: const GlassAmbientSpec.aurora(), child: view)),
      ),
    );
  }
}
