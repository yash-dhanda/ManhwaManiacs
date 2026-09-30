import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart' show GlassGlyph28;
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/shell/palette_commands.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recents per profile (glass 8.0.6): `{title, path, gateOpen}`, at most 8; the 18+ purge drops those typed with the gate open.
class PaletteRecent {
  const PaletteRecent(this.title, this.path, {required this.gateOpen});
  final String title;
  final String path;
  final bool gateOpen;
  Map<String, Object> toJson() => {'title': title, 'path': path, 'gateOpen': gateOpen};
}

String paletteRecentsKey(int? profileId) => 'mm.palette.recents.p${profileId ?? 0}';

List<PaletteRecent> readPaletteRecents(SharedPreferences prefs, int? profileId) {
  final raw = prefs.getStringList(paletteRecentsKey(profileId)) ?? const [];
  final out = <PaletteRecent>[];
  for (final s in raw) {
    final parts = s.split('\u0001');
    if (parts.length == 3) out.add(PaletteRecent(parts[0], parts[1], gateOpen: parts[2] == '1'));
  }
  return out;
}

Future<void> writePaletteRecent(SharedPreferences prefs, int? profileId, PaletteRecent r) async {
  final all = [r, for (final e in readPaletteRecents(prefs, profileId)) if (e.path != r.path) e].take(8);
  await prefs.setStringList(paletteRecentsKey(profileId), [for (final e in all) '${e.title}\u0001${e.path}\u0001${e.gateOpen ? 1 : 0}']);
}

Future<void> dropGateOpenPaletteRecents(SharedPreferences prefs, int? profileId) async {
  final kept = [for (final e in readPaletteRecents(prefs, profileId)) if (!e.gateOpen) e];
  await prefs.setStringList(paletteRecentsKey(profileId), [for (final e in kept) '${e.title}\u0001${e.path}\u0001${e.gateOpen ? 1 : 0}']);
}

/// Opens the command palette (glass 7.28): `mod+K` or a tap on the sidebar search capsule. Phones open Search instead.
Future<void> openGlassPalette(BuildContext context, WidgetRef ref) =>
    Navigator.of(context, rootNavigator: true).push<void>(_PaletteRoute(ref));

class _PaletteRoute extends PopupRoute<void> {
  _PaletteRoute(this.ref);
  final WidgetRef ref;

  @override
  Color? get barrierColor => GlassColors.dimModal;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close command palette';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 434);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => GlassCommandPalette(ref: ref, animation: animation);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

class _Result {
  const _Result(this.item, this.matches);
  final PaletteItem item;
  final List<int> matches;
}

class GlassCommandPalette extends ConsumerStatefulWidget {
  const GlassCommandPalette({super.key, required this.ref, required this.animation});
  final WidgetRef ref;
  final Animation<double> animation;

  @override
  ConsumerState<GlassCommandPalette> createState() => _GlassCommandPaletteState();
}

enum _LibState { idle, searching, done, error }

class _GlassCommandPaletteState extends ConsumerState<GlassCommandPalette> with SingleTickerProviderStateMixin {
  final TextEditingController _q = TextEditingController();
  final FocusNode _field = FocusNode(debugLabel: 'palette field');
  final FocusNode _keys = FocusNode(debugLabel: 'palette keys');
  late final AnimationController _drop = AnimationController.unbounded(vsync: this);
  Timer? _debounce;
  int _active = 0;
  _LibState _lib = _LibState.idle;
  List<FollowedSeries> _libResults = const [];
  late final List<PaletteItem> _commands = paletteCommands(widget.ref);

  @override
  void initState() {
    super.initState();
    _drop.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _field.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _field.dispose();
    _keys.dispose();
    _drop.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() => _active = 0);
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _lib = _LibState.idle;
        _libResults = const [];
      });
      return;
    }
    setState(() => _lib = _LibState.searching);
    _debounce = Timer(const Duration(milliseconds: 220), _search);
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    final r = await ref.read(libraryRepositoryProvider).search(q, perPage: 8);
    if (!mounted || _q.text.trim() != q) return;
    setState(() {
      if (r.isOk) {
        _lib = _LibState.done;
        _libResults = r.value.items;
      } else {
        _lib = _LibState.error;
      }
    });
  }

  List<_Result> _results() {
    final q = _q.text.trim();
    final out = <_Result>[];
    if (q.isEmpty) {
      final prefs = ref.read(sharedPrefsProvider);
      final id = ref.read(activeProfileProvider)?.id;
      for (final r in readPaletteRecents(prefs, id)) {
        out.add(_Result(PaletteItem(id: 'recent:${r.path}', group: 'Recent', title: r.title, subtitle: r.path, run: (c, rf) async => rf.read(skinRouterProvider).go(r.path)), const []));
      }
      for (final c in _commands.where((c) => c.group == 'Actions').take(4)) {
        out.add(_Result(c, const []));
      }
      return out;
    }
    for (final s in _libResults) {
      final path = '/library/${s.id}';
      out.add(_Result(PaletteItem(id: 'lib:${s.id}', group: 'Library', title: s.title, subtitle: s.sourceId, run: (c, rf) async => rf.read(skinRouterProvider).go(path)), paletteMatch(q, s.title) ?? const []));
    }
    final pins = ref.read(sourcePinsProvider).valueOrNull?.pins ?? const [];
    for (final p in pins) {
      final m = paletteMatch(q, p.name);
      if (m != null) {
        out.add(_Result(PaletteItem(id: 'src:${p.sourceId}', group: 'Sources', title: p.name, subtitle: 'Source', run: (c, rf) async => rf.read(skinRouterProvider).go('/sources/${Uri.encodeComponent(p.sourceId)}')), m));
      }
    }
    final rest = <_Result>[];
    for (final c in _commands) {
      final m = paletteMatch(q, '${c.title} ${c.keywords}');
      if (m != null) rest.add(_Result(c, paletteMatch(q, c.title) ?? const []));
    }
    rest.sort((a, b) => paletteScore(q, a.item.title).compareTo(paletteScore(q, b.item.title)));
    out.addAll(rest);
    return out.take(40).toList();
  }

  void _run(_Result r) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final prefs = ref.read(sharedPrefsProvider);
    final profile = ref.read(activeProfileProvider)?.id;
    final path = r.item.subtitle;
    if ((r.item.group == 'Library' || r.item.group == 'Go to') && path != null && path.startsWith('/')) {
      unawaited(writePaletteRecent(prefs, profile, PaletteRecent(r.item.title, path, gateOpen: r.item.group == 'Library')));
    }
    navigator.pop();
    final run = r.item.run;
    if (run != null) {
      // ignore: use_build_context_synchronously
      Future.microtask(() => run(navigator.context, widget.ref));
    }
  }

  void _move(int d, int n) {
    if (n == 0) return;
    setState(() => _active = (_active + d) % n < 0 ? (_active + d) % n + n : (_active + d) % n);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final res = _results();
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      _move(1, res.length);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _move(-1, res.length);
    } else if (k == LogicalKeyboardKey.home && res.isNotEmpty) {
      setState(() => _active = 0);
    } else if (k == LogicalKeyboardKey.end && res.isNotEmpty) {
      setState(() => _active = res.length - 1);
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (res.isNotEmpty) _run(res[_active.clamp(0, res.length - 1)]);
    } else if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.min(640.0, size.width - 48);
    final maxH = size.height * 0.70;
    final results = _results();
    final q = _q.text.trim();
    // Group headers are 28, rows 48.
    final rows = <Widget>[];
    String? last;
    var y = 0.0;
    var activeY = 0.0;
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r.item.group != last) {
        last = r.item.group;
        rows.add(Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: SizedBox(height: 20, child: GlassText(r.item.group.toUpperCase(), role: gt.typeCaption1, wght: 600, onGlass: true))));
        y += 28;
      }
      if (i == _active) activeY = y;
      rows.add(_Row(result: r, active: i == _active, onTap: () => _run(r), onHover: () => setState(() => _active = i)));
      y += 48;
    }
    if (_drop.value != activeY && _drop.isAnimating == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GlassMotion.play(MotionName.tabDroplet, controller: _drop, target: activeY, travelPx: 48);
      });
    }
    String? note;
    if (q.isNotEmpty && _lib == _LibState.searching) note = 'Searching…';
    if (q.isNotEmpty && _lib == _LibState.done && results.isEmpty) note = 'Nothing matches “$q”.';
    if (q.isNotEmpty && results.isEmpty && _lib != _LibState.searching && note == null) note = 'Nothing matches “$q”.';

    final panelH = math.min(maxH, 56 + 32 + math.max(96.0, y + 16)).toDouble();
    return FocusScope(
      child: Focus(
        focusNode: _keys,
        onKeyEvent: _onKey,
        canRequestFocus: false,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.12),
              child: FadeTransition(
                opacity: widget.animation,
                child: Semantics(
                  scopesRoute: true,
                  explicitChildNodes: true,
                  label: 'Command palette',
                  child: SkinGlass(
                    size: Size(width, panelH),
                    tier: GlassTierId.t4,
                    shape: const GlassShape.superellipse(26),
                    layer: GlassLayerKind.overlays,
                    debugLabel: 'GlassCommandPalette',
                    child: GlassHost(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 56,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(GlassGlyph.magnifyingGlass.regular, size: 20, color: gt.colorLabel2),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: EditableText(
                                      controller: _q,
                                      focusNode: _field,
                                      style: roleStyle(context, gt.typeBody, onGlass: true).copyWith(color: gt.colorOnGlass),
                                      cursorColor: gt.colorIris400,
                                      backgroundCursorColor: gt.colorFill3,
                                      onChanged: _onChanged,
                                      onSubmitted: (_) {
                                        if (results.isNotEmpty) _run(results[_active.clamp(0, results.length - 1)]);
                                      },
                                      textInputAction: TextInputAction.go,
                                    ),
                                  ),
                                  if (_q.text.isEmpty) const IgnorePointer(child: Opacity(opacity: 0.0, child: SizedBox.shrink())),
                                  const GlassKeycap('Esc'),
                                ],
                              ),
                            ),
                          ),
                          Container(height: 0.5, color: gt.colorSeparator),
                          Expanded(
                            child: note != null && results.isEmpty
                                ? Center(child: GlassText(note, role: gt.typeCallout, onGlass: true))
                                : Stack(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _drop,
                                        builder: (context, _) => Positioned(
                                          top: _drop.value + 4,
                                          left: 8,
                                          right: 8,
                                          height: 48,
                                          child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(width: 0.5, color: const Color(0x40FFFFFF))))),
                                        ),
                                      ),
                                      ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [if (_lib == _LibState.error) _errorRow(), ...rows]),
                                    ],
                                  ),
                          ),
                          Container(height: 0.5, color: gt.colorSeparator),
                          SizedBox(
                            height: 32,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const GlassKeycaps(['↑', '↓']),
                                  const SizedBox(width: 6),
                                  GlassText('move', role: gt.typeCaption1, onGlass: true),
                                  const SizedBox(width: 12),
                                  const GlassKeycap('↵'),
                                  const SizedBox(width: 6),
                                  GlassText('open', role: gt.typeCaption1, onGlass: true),
                                  const SizedBox(width: 12),
                                  const GlassKeycap('Esc'),
                                  const SizedBox(width: 6),
                                  GlassText('close', role: gt.typeCaption1, onGlass: true),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorRow() => GestureDetector(
        onTap: _search,
        child: SizedBox(height: 48, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: GlassText('Library search failed · Retry', role: gt.typeBody, onGlass: true)))),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.result, required this.active, required this.onTap, required this.onHover});
  final _Result result;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final item = result.item;
    final base = roleStyle(context, gt.typeBody, onGlass: true).copyWith(color: gt.colorOnGlass);
    final spans = <TextSpan>[];
    final hit = result.matches.toSet();
    for (var i = 0; i < item.title.length; i++) {
      spans.add(TextSpan(text: item.title[i], style: hit.contains(i) ? base.copyWith(fontVariations: const [FontVariation('wght', 700)], fontWeight: FontWeight.w700) : base));
    }
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: Semantics(
        button: true,
        selected: active,
        label: item.subtitle == null ? item.title : '${item.title}, ${item.subtitle}',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  SizedBox(width: 32, height: 32, child: item.icon == null ? null : Center(child: Icon(item.icon, size: 20, color: gt.colorOnGlass))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: spans), maxLines: 1, overflow: TextOverflow.ellipsis, textScaler: TextScaler.noScaling),
                        if (item.subtitle != null) GlassText(item.subtitle!, role: gt.typeFootnote, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (active) Icon(GlassGlyph28.arrowRight.regular, size: 16, color: gt.colorOnGlass),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
