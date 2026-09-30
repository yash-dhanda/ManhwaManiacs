import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/known_accounts_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart' show CoverPalette;
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconRole;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/lens_split_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/nav_bits.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/delete_profile_alert.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/handoff_timeline.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/orb_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profile_form.dart' show glassProfileHopProvider;
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_targets.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The profile picker "Who's reading?" (glass 8.5, mobile S05): orbs drifting on the mood field, Step into the light, the colour
/// pour, the flight into the dock or sidebar, and the skin-mismatch restart inside the hand-off.
class GlassProfilePicker extends ConsumerStatefulWidget {
  const GlassProfilePicker({super.key});

  @override
  ConsumerState<GlassProfilePicker> createState() => _GlassProfilePickerState();
}

class _GlassProfilePickerState extends ConsumerState<GlassProfilePicker> with SingleTickerProviderStateMixin {
  final OrbFieldController _field = OrbFieldController();
  final GlobalKey _centre = GlobalKey();
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(milliseconds: Handoff.totalMs));
  late final VoidCallback _unregister;
  bool _manage = false;
  bool _arrived = false;
  int? _focusedId;
  int? _chosenId;
  List<HandoffEvent> _plan = const [];
  int _prevMs = -1;
  Profile? _chosen;
  CoverPalette? _pour;
  Mood _pourMood = Mood.neutral;
  bool _busy = false;
  String _destination = '/';

  @override
  void initState() {
    super.initState();
    _unregister = registerSplashTarget(GlassSplashTarget.picker, _centre);
    _clock.addListener(_onClock);
  }

  @override
  void dispose() {
    _unregister();
    _clock.dispose();
    super.dispose();
  }

  // ---- the pick ---------------------------------------------------------------------------------------------------

  Future<void> _pick(Profile p, {bool animate = true}) async {
    if (_busy && _chosenId != null && !Handoff.canInterrupt((_clock.value * Handoff.totalMs).round())) return;
    if (_busy && _chosenId == p.id) return;
    final reduced = glassReduced(ref);
    if (_busy) {
      // A tap on another orb before 450 ms changes the choice: the repelled orbs come back, the field re-pours.
      _clock.stop();
      _field.reset();
    }
    _busy = true;
    _chosenId = p.id;
    _chosen = p;
    glassFire(ref, HapticEvent.tapPrimary);
    final r = await ref.read(glassProfileSwitchProvider).prepare(p);
    if (!mounted || _chosenId != p.id) return;
    final pending = glassDestinationFor(ref, p);
    _destination = pending;
    if (reduced || !animate) {
      await _reducedFinish(p, r.restartTo);
      return;
    }
    _plan = Handoff.plan(mismatch: r.restartTo != null, onboarding: pending != Routes.tonight());
    _prevMs = -1;
    _pourMood = p.mood;
    _pour = _paletteFor(p);
    _field.choose(p.id);
    _restartTo = r.restartTo;
    setState(() {});
    unawaited(_clock.forward(from: 0));
    // The first events (t = 0) are handled by the listener on the first tick; force them now.
    _onClock();
  }

  SkinId? _restartTo;

  CoverPalette _paletteFor(Profile p) {
    final preset = glassPresetFor(p.avatarKey);
    final (from, to, _) = preset.colours;
    return CoverPalette(a: [moodColour(p.mood), from, to], l: 0.7, lMax: 0.85);
  }

  Future<void> _reducedFinish(Profile p, SkinId? restartTo) async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (restartTo != null) {
      await playMelt(ref);
      if (mounted) await restartIntoSkin(context, ref, restartTo);
      return;
    }
    ref.read(glassProfileSwitchProvider).commit(_destination);
  }

  void _onClock() {
    final now = (_clock.value * Handoff.totalMs).round();
    for (final e in dueEvents(_plan, _prevMs, now)) {
      _handle(e);
    }
    _prevMs = now;
    if (mounted) setState(() {});
  }

  void _handle(HandoffEvent e) {
    final p = _chosen;
    if (p == null) return;
    switch (e.kind) {
      case HandoffEventKind.inflate || HandoffEventKind.repel || HandoffEventKind.titleFade || HandoffEventKind.pour:
        break;
      case HandoffEventKind.flight:
        unawaited(_flight(p));
      case HandoffEventKind.melt:
        unawaited(playMelt(ref));
      case HandoffEventKind.landHaptic:
        glassFire(ref, HapticEvent.profileSelect);
      case HandoffEventKind.dematerialiseOrb:
        if (_chosen != null) _field.hide(_chosen!.id, hidden: true);
      case HandoffEventKind.restart:
        final to = _restartTo;
        if (to != null) unawaited(restartIntoSkin(context, ref, to));
      case HandoffEventKind.commit:
        _commit();
    }
  }

  Future<void> _flight(Profile p) async {
    final rect = _field.rectOf(p.id);
    if (rect == null) return;
    final target = glassFlightTarget(context);
    _field.hide(p.id, hidden: true);
    final orb = SizedBox.square(dimension: rect.width, child: GlassProfileOrb(preset: glassPresetFor(p.avatarKey), size: rect.width, mood: moodColour(p.mood)));
    await ref.read(glassEffectsProvider).flyOrb(from: rect, to: target, orb: orb, tail: true);
  }

  void _commit() {
    final p = _chosen;
    if (p == null) return;
    final target = glassFlightTarget(context);
    if (_destination == Routes.tonight()) {
      ref.read(glassArrivalProvider.notifier).state = GlassArrival(kind: GlassArrivalKind.profile, point: target.center);
    }
    ref.read(glassProfileSwitchProvider).commit(_destination);
  }

  // ---- actions -----------------------------------------------------------------------------------------------------

  void _openForm(String location, Rect? origin) => unawaited(context.push<void>(location, extra: GlassNavExtra(originRect: origin)));

  void _edit(Profile p, [Rect? origin]) => _openForm(Routes.profileEdit(p.id), origin ?? _field.rectOf(p.id));

  void _add() => _openForm(Routes.profileNew(), _field.rectOf(-1));

  Future<void> _useWithoutAnimation(Profile p) async {
    final r = await ref.read(glassProfileSwitchProvider).prepare(p);
    if (!mounted) return;
    if (r.restartTo != null) {
      await playMelt(ref);
      if (mounted) await restartIntoSkin(context, ref, r.restartTo!);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) ref.read(glassProfileSwitchProvider).commit(glassDestinationFor(ref, p));
  }

  Future<void> _delete(Profile p, Rect origin) async {
    final ok = await showDeleteProfileAlert(context, ref, profile: p, sourceRect: origin);
    if (ok && mounted) setState(() {});
  }

  void _contextMenu(List<Profile> profiles, OrbEntry e, Rect rect) {
    final p = profiles.where((x) => x.id == e.id).firstOrNull;
    if (p == null) return;
    glassFire(ref, HapticEvent.longpressOpen);
    unawaited(
      showGlassContextMenu(
        context,
        sourceRect: rect,
        kind: GlassPreviewKind.poster,
        title: p.name,
        preview: GlassProfileOrb(preset: glassPresetFor(p.avatarKey), size: rect.width, mood: moodColour(p.mood)),
        entries: [
          GlassMenuEntry(label: 'Edit', onSelected: () => _edit(p, rect)),
          GlassMenuEntry(label: 'Use without animation', onSelected: () => unawaited(_useWithoutAnimation(p))),
          GlassMenuEntry(label: 'Delete', destructive: true, separatorBefore: true, onSelected: () => unawaited(_delete(p, rect))),
        ],
      ),
    );
  }

  Future<void> _switchAccount() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(Routes.login());
  }

  // ---- build -------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(glassProfileHopProvider, (_, id) {
      if (id == null) return;
      ref.read(glassProfileHopProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _field.hop(id));
    });
    final async = ref.watch(profilesProvider);
    final active = ref.watch(activeProfileProvider);
    final switchMode = ref.watch(profileSessionReadyProvider);
    final known = ref.watch(knownAccountsProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.shortestSide >= 600;
    final margin = GlassFrame.screenMargin(context);
    final profiles = async.valueOrNull;
    final split = ref.watch(glassLensSplitProvider);

    Widget content;
    final List<Profile> list = profiles ?? const [];
    if (async.isLoading && profiles == null) {
      content = _skeleton(wide);
    } else if (profiles == null) {
      content = _errorState(async.error, active);
    } else if (profiles.isEmpty) {
      content = _empty();
    } else {
      content = _orbs(list, wide);
      if (!_arrived) {
        _arrived = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s = ref.read(glassLensSplitProvider);
          if (s != null) {
            ref.read(glassLensSplitProvider.notifier).state = null;
            _field.arriveFrom(s.centre);
          } else {
            _field.arriveWave();
          }
        });
      }
    }
    if (split != null && (profiles == null || profiles.isEmpty) && !async.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(glassLensSplitProvider.notifier).state = null;
      });
    }

    final focusMood = _focusedMood(list, active);
    final spec = _pour != null && _chosenId != null ? GlassAmbientSpec.palette(_pour!, opacity: 0.30, fallbackMood: _pourMood) : GlassAmbientSpec.mood(focusMood, opacity: 0.30);
    final titleFade = _chosenId == null ? 1.0 : (1 - (_clock.value * Handoff.totalMs / Handoff.titleFadeMs)).clamp(0.0, 1.0);
    final unreachable = _isUnreachable(async, active);

    Widget body = Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(margin, 72, margin, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: titleFade,
                    child: Column(
                      children: [
                        LetterReveal("Who's reading?", role: gt.typeLargeTitle, screenId: 'profiles', revealKey: 'title', headingLevel: 1, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        GlassText('Your library, progress and mood follow the profile you pick.', role: gt.typeCallout, color: gt.colorLabel2, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  KeyedSubtree(
                    key: _centre,
                    child: const SizedBox(width: 0, height: 0),
                  ),
                  content,
                  if (profiles != null && profiles.length >= kMaxProfiles) ...[
                    const SizedBox(height: 24),
                    GlassText('Up to 5 profiles', role: gt.typeFootnote, color: gt.colorLabel2),
                  ],
                  if (unreachable && active != null) ...[
                    const SizedBox(height: 16),
                    GlassButton(label: 'Try again', variant: GlassButtonVariant.plain, onPressed: () => unawaited(ref.read(profilesProvider.notifier).refresh())),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(top: MediaQuery.paddingOf(context).top + 8, left: margin, right: margin, height: glassBarHeight(context), child: _navRow(known.length > 1, switchMode, profiles?.isNotEmpty ?? false)),
      ],
    );
    body = GlassAmbientScope(spec: spec, child: body);
    body = RegisteredShortcuts(
      group: 'Profiles',
      entries: [
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyE), description: 'Edit the focused profile', singleKey: true, keys: const ['E'], onInvoke: () => _editFocused(list)),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyN), description: 'Add a profile', singleKey: true, keys: const ['N'], onInvoke: () {
          if (list.length < kMaxProfiles) _add();
        },),
        ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Return to the app', keys: const ['Esc'], onInvoke: () {
          if (switchMode) _back();
        },),
      ],
      child: body,
    );
    return PopScope(
      canPop: switchMode,
      onPopInvokedWithResult: (didPop, _) {},
      child: Material(type: MaterialType.transparency, child: body),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.tonight());
    }
  }

  void _editFocused(List<Profile> list) {
    final id = _focusedId;
    final p = list.where((x) => x.id == id).firstOrNull;
    if (p != null) _edit(p);
  }

  bool _isUnreachable(AsyncValue<List<Profile>> async, ActiveProfile? active) => async.hasError && !async.isLoading && async.valueOrNull == null && active != null && (async.error is NetworkError || async.error is TimeoutError);

  Mood _focusedMood(List<Profile> list, ActiveProfile? active) {
    Profile? byId(int? id) => id == null ? null : list.where((p) => p.id == id).firstOrNull;
    final p = byId(_focusedId) ?? byId(active?.id) ?? (list.isEmpty ? null : list.first);
    return p?.mood ?? active?.mood ?? Mood.neutral;
  }

  Widget _orbs(List<Profile> list, bool wide) {
    final entries = [
      for (final p in list) OrbEntry.profile(id: p.id, name: p.name, preset: glassPresetFor(p.avatarKey), mood: p.mood),
      if (list.length < kMaxProfiles) const OrbEntry.add(),
    ];
    return OrbField(
      entries: entries,
      controller: _field,
      orbSize: wide ? 128 : 96,
      spacing: wide ? 40 : 24,
      manage: _manage,
      enabled: !_busy,
      onFocusChanged: (id) => setState(() => _focusedId = id),
      onPick: (e) {
        final p = list.where((x) => x.id == e.id).firstOrNull;
        if (p != null) unawaited(_pick(p));
      },
      onAdd: _add,
      onEdit: (e) {
        final p = list.where((x) => x.id == e.id).firstOrNull;
        if (p != null) _edit(p);
      },
      onContext: (e, r) => _contextMenu(list, e, r),
    );
  }

  Widget _skeleton(bool wide) {
    final s = wide ? 128.0 : 96.0;
    return GlassSkeletonGroup(
      label: 'Loading profiles',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: wide ? 40 : 24,
        runSpacing: 24,
        children: [for (var i = 0; i < 5; i++) GlassSkeleton(width: s, height: s, circle: true, index: i)],
      ),
    );
  }

  Widget _empty() => GlassObjectLens(
        situation: LensSituation.noProfile,
        title: 'Create your first profile',
        description: 'Profiles keep progress, follows and mood separate for each reader on this account.',
        placement: GlassLensPlacement.inline,
        primary: LensAction('Add profile', _add),
      );

  Widget _errorState(Object? error, ActiveProfile? active) {
    if (active != null && (error is NetworkError || error is TimeoutError)) {
      return Column(
        children: [
          GlassText("The server isn't answering.", role: gt.typeCallout, color: gt.colorLabel2, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OrbField(
            entries: [OrbEntry.profile(id: active.id, name: active.name, preset: glassPresetFor(active.avatarKey), mood: active.mood)],
            controller: _field,
            orbSize: 96,
            spacing: 24,
            singleLabel: 'Continue as ${active.name}',
            onFocusChanged: (_) {},
            onPick: (e) => unawaited(_continueOffline(active)),
            onAdd: () {},
            onEdit: (_) {},
            onContext: (_, __) {},
          ),
        ],
      );
    }
    final msg = error is AppError ? error.userMessage : 'Try again in a moment.';
    return GlassObjectLens(
      situation: LensSituation.loadError,
      title: 'Profiles are unavailable',
      description: msg,
      tone: GlassLensTone.error,
      placement: GlassLensPlacement.inline,
      primary: LensAction('Try again', () => unawaited(ref.read(profilesProvider.notifier).refresh())),
    );
  }

  Future<void> _continueOffline(ActiveProfile a) async {
    ref.read(profileSessionReadyProvider.notifier).enter();
    if (mounted) ref.read(glassProfileSwitchProvider).commit(Routes.tonight());
  }

  Widget _navRow(bool canSwitchAccount, bool switchMode, bool hasProfiles) {
    final shapes = <SkinGlassShape>[];
    final aligns = <Alignment>[];
    if (switchMode) {
      shapes.add(SkinGlassShape(size: Size.square(glassBarHeight(context)), shape: const GlassShape.circle(), child: GlassBarIcon(icon: roleIcon(GlassIconRole.back), label: 'Back', onPressed: _back)));
      aligns.add(Alignment.centerLeft);
    }
    if (canSwitchAccount && !_manage) {
      shapes.add(glassTextShape(context, 'Switch account', () => unawaited(_switchAccount())));
      aligns.add(Alignment.centerRight);
    }
    if (hasProfiles) {
      shapes.add(glassTextShape(context, _manage ? 'Done' : 'Edit', () => setState(() => _manage = !_manage)));
      aligns.add(Alignment.centerRight);
    }
    if (shapes.isEmpty) return const SizedBox.shrink();
    return SkinGlassGroup(shapes: shapes, aligns: aligns, height: glassBarHeight(context), debugLabel: 'picker-nav');
  }
}
