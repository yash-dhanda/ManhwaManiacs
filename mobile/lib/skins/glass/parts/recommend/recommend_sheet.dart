import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/recommend_targets.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/orb_flight.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart' show GlassMenuEntry;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_area.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart' show glassNavigatorsProvider;
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// "Sent to Aarav", "Sent to Aarav and Mira", "Sent to Aarav, Mira and Kai".
String sentToToast(List<String> names) => switch (names.length) {
      0 => 'Sent',
      1 => 'Sent to ${names[0]}',
      _ => 'Sent to ${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
    };

const int kNoteMax = 140;

/// Registers `?sheet=recommend` and `?sheet=letter-note` (glass 8.0.3, 7.10): `medium`, the 560 px window on the desktop frame.
void registerRecommendSheets() {
  registerGlobalSheet('recommend', const GlassSheetSpec(title: 'Recommend', builder: _recommend, detents: [GlassDetent.medium, GlassDetent.large], opening: GlassDetent.medium));
}

Widget _recommend(BuildContext context) => const RecommendSheetBody();

/// The current location's query (the sheet params travel there).
Map<String, String> currentQuery(WidgetRef ref) {
  try {
    return ref.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.queryParameters;
  } catch (_) {
    return const {};
  }
}

/// Opens the recommend sheet: `?sheet=recommend&series={sourceId}:{seriesKey}` (plus `&to=` to preselect) on the current
/// location; with no series it opens on the pick step. On a sheet route (the friend sheet) it is pushed directly on the root
/// navigator, because sheet routes do not host `?sheet=`.
void openRecommendSheet(WidgetRef ref, {String? sourceId, String? seriesKey, String? title, int? toProfileId}) {
  final router = ref.read(skinRouterProvider);
  final uri = router.routerDelegate.currentConfiguration.uri;
  final params = <String, String>{
    'sheet': 'recommend',
    if (sourceId != null && seriesKey != null) 'series': '$sourceId:$seriesKey',
    if (title != null) 'title': title,
    if (toProfileId != null) 'to': '$toProfileId',
  };
  if (uri.path.startsWith('/circle/')) {
    final nav = ref.read(glassNavigatorsProvider)?.root.currentState;
    if (nav == null) return;
    final page = GlassSheetPage<void>(
      title: 'Recommend',
      builder: (_) => RecommendSheetBody(series: params['series'], title: title, to: toProfileId),
    );
    unawaited(nav.push(page.createRoute(nav.context)));
    return;
  }
  router.go(uri.replace(queryParameters: {...uri.queryParameters, ...params}).toString());
}

/// "Recommend to…" for a series' menus (glass 9.3.4, E6): once the Circle has loaded with nobody taking recommendations it reads
/// "Recommend to… (no one is taking recommendations yet)" and is disabled. Null while the `recommend` sheet is not registered.
GlassMenuEntry? recommendMenuEntry(WidgetRef ref, {required String sourceId, required String seriesKey, String? title, SingleActivator? keyHint, VoidCallback? onSelected}) {
  if (!glassSheetRegistered('recommend')) return null;
  final ms = ref.read(circleMembersProvider).valueOrNull;
  final none = ms != null && !ms.any((m) => m.shares.recommendations);
  return GlassMenuEntry(
    label: none ? 'Recommend to… (no one is taking recommendations yet)' : 'Recommend to…',
    enabled: !none,
    keyHint: keyHint,
    onSelected: onSelected ?? () => openRecommendSheet(ref, sourceId: sourceId, seriesKey: seriesKey, title: title),
  );
}

({String sourceId, String seriesKey})? parseSeries(String? s) {
  if (s == null) return null;
  final i = s.indexOf(':');
  if (i <= 0 || i == s.length - 1) return null;
  return (sourceId: s.substring(0, i), seriesKey: s.substring(i + 1));
}

/// Recommend *{title}* (glass 9.3.4, the menu path): Circle orbs as multi-select toggles (`recommendTargets`: the disabled show
/// "{name} isn't taking recommendations", the ineligible are absent), the note (140 characters), and "Send". On success the
/// selected orbs fly out along their Beziers, the sheet closes and "Sent to …" shows. Without a series: the pick step first.
class RecommendSheetBody extends ConsumerStatefulWidget {
  const RecommendSheetBody({super.key, this.series, this.title, this.to});
  final String? series;
  final String? title;
  final int? to;

  @override
  ConsumerState<RecommendSheetBody> createState() => _RecommendSheetBodyState();
}

class _RecommendSheetBodyState extends ConsumerState<RecommendSheetBody> with TickerProviderStateMixin {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final Map<int, GlobalKey> _orbKeys = {};
  late final Map<String, String> _q = currentQuery(ref);
  ({String sourceId, String seriesKey})? _series;
  String? _title;
  final Set<int> _selected = {};
  bool _sending = false;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _series = parseSeries(widget.series ?? _q['series']);
    _title = widget.title ?? _q['title'];
    final to = widget.to ?? int.tryParse(_q['to'] ?? '');
    if (to != null) _selected.add(to);
  }

  @override
  void dispose() {
    _note.dispose();
    _search.dispose();
    super.dispose();
  }

  void _pick(FollowedSeries s) {
    glassFire(ref, HapticEvent.select);
    setState(() {
      _series = (sourceId: s.sourceId, seriesKey: s.seriesKey);
      _title = s.title;
    });
  }

  void _toggle(int id) {
    final on = !_selected.contains(id);
    glassFire(ref, on ? HapticEvent.toggleOn : HapticEvent.toggleOff);
    setState(() => on ? _selected.add(id) : _selected.remove(id));
  }

  Future<void> _send(List<CircleMember> selectable) async {
    final s = _series;
    if (s == null || _selected.isEmpty) return;
    setState(() => _sending = true);
    final ids = [for (final m in selectable) if (_selected.contains(m.profileId)) m.profileId];
    final names = [for (final m in selectable) if (_selected.contains(m.profileId)) m.name];
    final err = await ref.read(circleActionsProvider).sendLetter(toProfileIds: ids, sourceId: s.sourceId, seriesKey: s.seriesKey, note: _note.text);
    if (!mounted) return;
    final toasts = ref.read(glassToastProvider.notifier);
    if (err != null) {
      setState(() => _sending = false);
      if (err is ApiError && err.code == 'recipient_unavailable') {
        final raw = err.details is Map ? (err.details! as Map)['profile_ids'] : null;
        final gone = raw is List ? [for (final x in raw) if (x is num) x.toInt()] : ids;
        glassFire(ref, HapticEvent.warning);
        for (final m in selectable.where((m) => gone.contains(m.profileId))) {
          toasts.show(GlassToastSpec("${m.name} isn't taking recommendations any more.", kind: GlassToastKind.warning));
        }
        setState(() => _selected.removeAll(gone));
        ref.invalidate(seriesMembersProvider(s));
        return;
      }
      glassFire(ref, HapticEvent.error);
      toasts.show(GlassToastSpec("Couldn't send that", kind: GlassToastKind.error, actionLabel: 'Try again', onAction: () => unawaited(_send(selectable))));
      return;
    }
    glassFire(ref, HapticEvent.recommendSend);
    glassSound(ref, SoundEvent.recommendSend);
    await _flyOut(ids);
    if (!mounted) return;
    toasts.show(GlassToastSpec(sentToToast(names), kind: GlassToastKind.success));
    unawaited(Navigator.of(context).maybePop());
  }

  /// Orbs fly out (glass 4.10): each selected orb along its quadratic Bezier to the top edge, 40 ms apart on `springZoom`,
  /// dematerialising. Reduced motion: none (the sheet's 150 ms fade carries it).
  Future<void> _flyOut(List<int> ids) async {
    if (ref.read(glassReducedProvider)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final sheet = context.findRenderObject();
    final centreX = sheet is RenderBox && sheet.hasSize ? sheet.localToGlobal(sheet.size.center(Offset.zero)).dx : MediaQuery.sizeOf(context).width / 2;
    final flights = <Future<void>>[];
    final rec = GlassMotion.recorder.begin(MotionName.orbsFlyOut.label, 558 + 40 * (ids.length - 1));
    setState(() => _flying = true);
    for (var i = 0; i < ids.length; i++) {
      final ro = _orbKeys[ids[i]]?.currentContext?.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) continue;
      final start = ro.localToGlobal(ro.size.center(Offset.zero));
      final path = orbFlightPath(start, sheetCentreX: centreX, topY: 0);
      final m = (ref.read(seriesMembersProvider(_series!)).valueOrNull ?? const <CircleMember>[]).where((x) => x.profileId == ids[i]).firstOrNull;
      final c = AnimationController.unbounded(vsync: this);
      final entry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
          animation: c,
          builder: (_, __) {
            final t = c.value.clamp(0.0, 1.0);
            final p = bezierAt(path, t);
            return Positioned(
              left: p.dx - 28,
              top: p.dy - 28,
              child: IgnorePointer(child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: Transform.scale(scale: 1 - 0.4 * t, child: GlassProfileOrb(preset: glassPresetFor(m?.avatarKey), size: 56, friend: true)))),
            );
          },
        ),
      );
      overlay.insert(entry);
      flights.add(() async {
        await Future<void>.delayed(orbFlightDelay(i));
        await c.animateWith(SpringSimulation(springOf(gt.springZoom), 0, 1, 0));
        entry.remove();
        entry.dispose();
        c.dispose();
      }());
    }
    await Future.wait(flights);
    GlassMotion.recorder.end(rec);
  }

  @override
  Widget build(BuildContext context) {
    final m = GlassFrame.screenMargin(context);
    final s = _series;
    if (s == null) return Material(type: MaterialType.transparency, child: _pickStep(m));
    final offline = ref.watch(glassOfflineProvider);
    final members = ref.watch(seriesMembersProvider(s));
    final targets = recommendTargets(members.valueOrNull ?? const []);
    final title = _title ?? _lookupTitle(s) ?? 'this series';
    // The note field is a Material text field; global sheets carry no Material of their own.
    return Material(type: MaterialType.transparency, child: ListView(
      padding: EdgeInsets.fromLTRB(m, 4, m, 24),
      children: [
        Text.rich(
          TextSpan(children: [const TextSpan(text: 'Recommend '), TextSpan(text: title, style: const TextStyle(fontStyle: FontStyle.italic))]),
          style: roleStyle(context, gt.typeTitle3).copyWith(color: gt.colorLabel1),
        ),
        const SizedBox(height: 16),
        if (offline) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassText('Recommending needs a connection', role: gt.typeFootnote, color: gt.colorLabel2)),
        if (members.isLoading && !members.hasValue)
          GlassSkeletonGroup(label: 'Loading your Circle', child: Row(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(right: 16), child: GlassSkeleton(width: 56, height: 56, circle: true, index: i))]))
        else if (targets.selectable.isEmpty && targets.disabled.isEmpty)
          GlassText('No one is taking recommendations yet.', role: gt.typeBody, color: gt.colorLabel2)
        else
          Wrap(spacing: 16, runSpacing: 16, children: [
            for (final x in targets.selectable) _orb(x, enabled: !offline && !_flying),
            for (final x in targets.disabled) _orb(x, enabled: false, reason: "${x.name} isn't taking recommendations"),
          ],),
        const SizedBox(height: 20),
        GlassTextArea(controller: _note, label: "Why they'll like it", maxLength: kNoteMax, enabled: !offline),
        const SizedBox(height: 16),
        GlassButton(
          label: 'Send',
          variant: GlassButtonVariant.primary,
          fullWidth: true,
          loading: _sending,
          disabledReason: offline ? 'Recommending needs a connection' : (_selected.isEmpty ? 'Choose who to send it to' : null),
          onPressed: offline || _selected.isEmpty || _sending ? null : () => unawaited(_send(targets.selectable)),
        ),
      ],
    ),);
  }

  String? _lookupTitle(({String sourceId, String seriesKey}) s) => (ref.read(libraryListProvider).valueOrNull?.items ?? const <FollowedSeries>[])
      .where((f) => f.sourceId == s.sourceId && f.seriesKey == s.seriesKey)
      .map((f) => f.title)
      .firstOrNull;

  Widget _orb(CircleMember x, {required bool enabled, String? reason}) {
    final on = _selected.contains(x.profileId);
    final key = _orbKeys.putIfAbsent(x.profileId, GlobalKey.new);
    return SizedBox(
      width: reason == null ? 72 : 112,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GlassPressable(
          key: key,
          shape: const GlassShape.circle(),
          material: GlassMaterial.content,
          enabled: enabled,
          toggled: on,
          semanticsLabel: x.name,
          disabledReason: reason,
          onTap: enabled ? () => _toggle(x.profileId) : null,
          builder: (_, __) => Opacity(opacity: _flying && on ? 0 : 1, child: GlassProfileOrb(preset: glassPresetFor(x.avatarKey), size: 56, friend: true, selected: on, enabled: enabled, name: x.name)),
        ),
        const SizedBox(height: 4),
        ExcludeSemantics(child: GlassText(reason ?? x.name, role: gt.typeCaption1, color: reason == null ? gt.colorLabel1 : gt.colorLabel2, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],),
    );
  }

  Widget _pickStep(double m) {
    final q = _search.text.trim().toLowerCase();
    final all = ref.watch(libraryListProvider).valueOrNull?.items ?? const <FollowedSeries>[];
    final shown = [for (final s in all) if (q.isEmpty || s.title.toLowerCase().contains(q)) s];
    return ListView(
      padding: EdgeInsets.fromLTRB(m, 4, m, 24),
      children: [
        GlassText('Pick a series', role: gt.typeTitle3),
        const SizedBox(height: 12),
        GlassSearchField(variant: GlassSearchVariant.filter, controller: _search, placeholder: 'Search your library', onQuery: (_) => setState(() {})),
        const SizedBox(height: 12),
        if (shown.isEmpty) GlassText(all.isEmpty ? 'Your library is empty.' : 'Nothing matches.', role: gt.typeBody, color: gt.colorLabel2),
        for (final s in shown.take(50))
          GlassPressable(
            material: GlassMaterial.content,
            shape: const GlassShape.superellipse(14),
            semanticsLabel: s.title,
            onTap: () => _pick(s),
            builder: (_, __) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: GlassText(s.title, role: gt.typeBody, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ),
      ],
    );
  }
}
