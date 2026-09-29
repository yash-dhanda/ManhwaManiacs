import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart' show cineIsPending;
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart' show kProfileGoneToast;
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_logic.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart' show splashDoneProvider;
import 'package:manhwamaniacs/skins/cinematic/splash/cine_wordmark.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Whether Onboarding has left the `PENDING` set (mobile/20).
final onboardingBuiltProvider = Provider<bool>((ref) => !cineIsPending(ScreenId.onboarding), name: 'onboardingBuilt');

/// One avatar cell's data: a server profile, or the cached snapshot when the server is silent.
class _Face {
  const _Face({required this.id, required this.name, required this.avatarKey, required this.adult, required this.credit});
  final int id;
  final String name;
  final String? avatarKey;
  final bool adult;
  final String credit;
}

/// "Who's reading tonight?" (mobile S05, cinematic 8.5): a takeover on `#000`, never auto-skipped.
/// [switchMode] is the pushed Switch-profile variant (a back arrow pops; the previous profile
/// stays active until another is picked).
class ProfilePickerScreen extends ConsumerStatefulWidget {
  const ProfilePickerScreen({super.key, this.switchMode = false, this.clock});
  final bool switchMode;

  /// The local clock (tests).
  final DateTime Function()? clock;

  @override
  ConsumerState<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends ConsumerState<ProfilePickerScreen> with SingleTickerProviderStateMixin {
  final Map<int, FocusNode> _nodes = {};
  final Map<int, GlobalKey> _avatarKeys = {};
  final GlobalKey _menuKey = GlobalKey();
  late final AnimationController _ring;
  bool _manage = false;
  int? _choosing;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: CineDur.column);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(sessionEndReasonProvider) == SessionEndReason.profileGone) {
        ref.read(sessionEndReasonProvider.notifier).state = null;
        ref.read(cineToastsProvider.notifier).info(kProfileGoneToast);
      }
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _node(int id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'profile-$id'));
  GlobalKey _key(int id) => _avatarKeys.putIfAbsent(id, GlobalKey.new);

  Future<void> _choose(Profile p, {double size = 112}) async {
    if (_choosing != null) return;
    if (_manage) {
      unawaited(context.push(Routes.profileEdit(p.id)));
      return;
    }
    final box = _key(p.id).currentContext?.findRenderObject() as RenderBox?;
    final center = box != null && box.hasSize ? box.localToGlobal(box.size.center(Offset.zero)) : MediaQuery.sizeOf(context).center(Offset.zero);
    final shutter = CineShutter.maybeOf(context);
    final reduced = CineMotion.reduced(context);
    setState(() => _choosing = p.id);
    if (!reduced) await _ring.forward(from: 0);
    if (!mounted) return;
    await shutter?.irisClose(center, size / 2);
    if (!mounted) return;
    cineFeedback(context, HapticEvent.profileSelect);
    final outcome = decidePickerOutcome(
      profile: p,
      runningSkin: ref.read(skinIdProvider).name,
      glassAvailable: Flags.glassAvailable,
      onboardingBuilt: ref.read(onboardingBuiltProvider),
    );
    await ref.read(activeProfileProvider.notifier).select(p);
    ref.read(profileSessionReadyProvider.notifier).enter();
    if (!mounted) return;
    // ponytail: the Glass restart branch has no path until `Flags.glassAvailable` flips (release/00);
    // it lands on Tonight like `home` until mobile/01's restart is wired to the flag.
    context.go(outcome.kind == PickerOutcomeKind.onboarding ? outcome.route : Routes.tonight());
    unawaited(shutter?.irisOut(center));
  }

  Future<void> _continueOffline() async {
    ref.read(profileSessionReadyProvider.notifier).enter();
    context.go(Routes.tonight());
  }

  Future<void> _switchAccount() async {
    final ok = await showCineConfirm(
      context,
      title: 'Switch account?',
      body: "You'll be signed out on this device; saved chapters stay.",
      confirmLabel: 'Switch account',
      destructive: true,
    );
    if (ok && mounted) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _overflow() async {
    final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final o = box.localToGlobal(Offset.zero);
    await showCineMenu<void>(
      context,
      anchor: o & box.size,
      entries: [CineMenuEntry<void>(label: 'Switch account…', onSelected: _switchAccount)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final profiles = ref.watch(profilesProvider);
    final active = ref.watch(activeProfileProvider);
    final list = profiles.valueOrNull;
    final atLimit = (list?.length ?? 0) >= kMaxProfiles;
    List<Profile> ordered() => list ?? const [];

    void move(int delta) {
      final l = ordered();
      if (l.isEmpty) return;
      final i = l.indexWhere((p) => _node(p.id).hasFocus);
      final next = i < 0 ? 0 : (i + delta).clamp(0, l.length - 1);
      _node(l[next].id).requestFocus();
    }

    Profile? focused() {
      for (final p in ordered()) {
        if (_node(p.id).hasFocus) return p;
      }
      return null;
    }

    final entries = <ShortcutEntry>[
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.arrowLeft), description: 'Previous profile', onInvoke: () => move(-1), keys: const ['←']),
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.arrowRight), description: 'Next profile', onInvoke: () => move(1), keys: const ['→']),
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Read as this profile', onInvoke: () {
        final f = focused() ?? (ordered().length == 1 ? ordered().first : null);
        if (f != null) unawaited(_choose(f));
      }, keys: const ['Enter'],),
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyE), description: 'Edit profile', singleKey: true, onInvoke: () {
        final f = focused();
        if (f != null) unawaited(context.push(Routes.profileEdit(f.id)));
      },),
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyN), description: 'New profile', singleKey: true, onInvoke: () {
        if (!atLimit) unawaited(context.push(Routes.profileNew()));
      },),
      ShortcutEntry(group: 'Profiles', activator: const SingleActivator(LogicalKeyboardKey.keyM), description: 'Manage profiles', singleKey: true, onInvoke: () => setState(() => _manage = !_manage)),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final Widget body;
    if (profiles.isLoading && list == null) {
      body = _grid(context, width, [for (var i = 0; i < 5; i++) null], loading: true);
    } else if (profiles.hasError && list == null) {
      body = active != null
          ? _Unreachable(name: active.name, avatarKey: active.avatarKey, onContinue: _continueOffline, onRetry: () => ref.invalidate(profilesProvider))
          : Padding(
              padding: EdgeInsets.all(c.space4),
              child: CineNotice(
                tone: CineNoticeTone.error,
                kicker: 'Correction',
                headline: "We couldn't load the profiles.",
                deck: "The server isn't answering.",
                primary: CineNoticeAction('Retry', () => ref.invalidate(profilesProvider)),
              ),
            );
    } else if (list != null && list.isEmpty) {
      body = Padding(
        padding: EdgeInsets.all(c.space4),
        child: CineNotice(
          tone: CineNoticeTone.empty,
          kicker: 'Empty house',
          headline: 'Create your first profile.',
          deck: kEmptyHouseDeck,
          primary: CineNoticeAction('New profile', () => context.push(Routes.profileNew())),
        ),
      );
    } else {
      body = _grid(context, width, [
        for (final p in list!)
          _Face(id: p.id, name: p.name, avatarKey: p.avatarKey, adult: p.matureContentEnabled, credit: pickerCredit(p)),
      ], sizes: list.length,);
    }

    final question = pickerQuestion((widget.clock ?? DateTime.now)());
    return RegisteredShortcuts(
      group: 'Profiles',
      entries: entries,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: cineHitMin(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: c.space2),
                child: Row(children: [
                  if (widget.switchMode) CineIconButton(label: 'Back', role: CineIconRole.back, onPressed: () => context.pop()),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: widget.switchMode ? 0 : c.space2),
                      child: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: CineWordmark.line(size: 20, withRule: false)),
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: atLimit ? kLimitLine : '',
                    child: CineButton(
                      label: _manage ? 'Done' : 'Manage',
                      variant: CineButtonVariant.quiet,
                      size: CineButtonSize.sm,
                      onPressed: () => setState(() => _manage = !_manage),
                    ),
                  ),
                  KeyedSubtree(key: _menuKey, child: CineIconButton(label: 'More', role: CineIconRole.overflow, onPressed: _overflow)),
                ],),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _Question(question),
                    SizedBox(height: c.space8),
                    body,
                  ],),
                ),
              ),
            ),
          ],),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, double width, List<_Face?> faces, {bool loading = false, int? sizes}) {
    final c = context.cine;
    final count = faces.length;
    final atLimit = !loading && count >= kMaxProfiles;
    final cells = count + (loading || atLimit ? 0 : 1);
    final g = pickerGridFor(width, cells);
    final gap = width >= 900 ? 48.0 : 32.0;
    final cellW = g.size + 16;
    final maxW = g.perRow * cellW + (g.perRow - 1) * gap;
    final reduced = CineMotion.reduced(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: gap,
        runSpacing: 32,
        children: [
          for (var i = 0; i < faces.length; i++)
            if (faces[i] == null)
              SizedBox(
                width: cellW,
                child: CineFlicker(index: i, child: Center(child: Container(width: g.size, height: g.size, decoration: BoxDecoration(shape: BoxShape.circle, color: c.colorPaper2)))),
              )
            else
              _cell(context, faces[i]!, g.size, cellW, reduced),
          if (!loading && !atLimit)
            SizedBox(
              width: cellW,
              child: Semantics(
                button: true,
                label: 'New profile',
                excludeSemantics: true,
                child: CinePressable(
                  round: true,
                  onTap: () => context.push(Routes.profileNew()),
                  builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: g.size,
                      height: g.size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.colorInk45)),
                      child: const CineIcon(CineIconRole.follow, size: 32),
                    ),
                    SizedBox(height: c.space2),
                    CineRoleText('New profile', c.typeSubhead, color: c.colorInk60, textAlign: TextAlign.center),
                  ],),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, _Face f, double size, double cellW, bool reduced) {
    final c = context.cine;
    final dimmed = _choosing != null && _choosing != f.id;
    final mine = _choosing == f.id;
    final Widget avatar = KeyedSubtree(
      key: _key(f.id),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          CineAvatar(avatarKey: f.avatarKey, size: size, adult: f.adult),
          if (_manage)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x80000000)),
                  child: const CineIcon(CineIconRole.edit),
                ),
              ),
            ),
          if (mine)
            Positioned(
              left: -5,
              top: -5,
              right: -5,
              bottom: -5,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (_, __) => CustomPaint(painter: _RingPainter(CineCurves.easeSet.transform(_ring.value), c.colorSpot)),
              ),
            ),
        ],),
      ),
    );
    final child = Semantics(
      button: true,
      label: _manage ? 'Edit ${f.name}' : 'Read as ${f.name}',
      excludeSemantics: true,
      child: CinePressable(
        round: true,
        focusNode: _node(f.id),
        onTap: () => _choose(_profileFor(f.id), size: size),
        onLongPress: () {
          cineFeedback(context, HapticEvent.longpressOpen);
          context.push(Routes.profileEdit(f.id));
        },
        builder: (_, __) => SizedBox(
          width: cellW,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            avatar,
            SizedBox(height: c.space3),
            CineRoleText(f.name, c.typeSubhead, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            CineRoleText(f.credit.isEmpty ? ' ' : f.credit, c.typeCaption, color: c.colorInk45, textAlign: TextAlign.center),
          ],),
        ),
      ),
    );
    if (!dimmed) return child;
    final blur = reduced ? null : ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    return AnimatedOpacity(
      opacity: 0.2,
      duration: reduced ? Duration.zero : CineDur.column,
      child: blur == null ? child : ImageFiltered(imageFilter: blur, child: child),
    );
  }

  Profile _profileFor(int id) => ref.read(profilesProvider).requireValue.firstWhere((p) => p.id == id);
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawArc(Offset.zero & size, -math.pi / 2, 2 * math.pi * t, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t || o.color != color;
}

/// The question, typed once the splash hand-off has begun, at 40 px on two lines.
class _Question extends ConsumerWidget {
  const _Question(this.text);
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final style = CineText.style(context, c.typeMasthead).copyWith(fontSize: 40, height: 1.05);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: ref.watch(splashDoneProvider)
          ? TypedHeadline(text, style: style, cap: c.typeMasthead.cap, level: 1)
          : Opacity(opacity: 0, child: ExcludeSemantics(child: Text(text, style: style))),
    );
  }
}

/// The server is silent but a profile was cached: the headline, a single avatar that continues
/// offline, and Retry.
class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.name, required this.avatarKey, required this.onContinue, required this.onRetry});
  final String name;
  final String? avatarKey;
  final VoidCallback onContinue, onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      CineRoleText("We couldn't load the profiles.", c.typeTitle, textAlign: TextAlign.center),
      SizedBox(height: c.space2),
      CineRoleText("The server isn't answering. Continue as $name, or retry.", c.typeDeck, color: c.colorInk60, textAlign: TextAlign.center),
      SizedBox(height: c.space6),
      Semantics(
        button: true,
        label: 'Read as $name',
        excludeSemantics: true,
        child: CinePressable(
          round: true,
          onTap: onContinue,
          builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
            CineAvatar(avatarKey: avatarKey, size: 112),
            SizedBox(height: c.space3),
            CineRoleText(name, c.typeSubhead),
          ],),
        ),
      ),
      SizedBox(height: c.space6),
      CineButton(label: 'Retry', variant: CineButtonVariant.quiet, onPressed: onRetry),
    ],);
  }
}
