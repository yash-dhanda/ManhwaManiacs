import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_physics.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_stage.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlights.dart';

/// The Home spotlight (glass 8.8): up to six cards. Phones page one card per flick over the card's own enlargement; tablet and desktop
/// frames show the stage. [onFocusedChanged] reports the page's palette (Light follows the story).
class Spotlight extends ConsumerStatefulWidget {
  const Spotlight({super.key, required this.specs, required this.handlers, required this.onFocusedChanged, required this.tiltActive, required this.controlsOnScreen, this.initialDrop = true});

  final List<SpotlightSpec> specs;
  final SpotlightHandlers handlers;
  final void Function(int index, SpotlightSpec spec) onFocusedChanged;
  final bool tiltActive;

  /// False while the spotlight is scrolled out of the viewport: the actions render their content twins.
  final bool controlsOnScreen;

  /// The signature drop of the first paint (scale 0.9 to 1, minus 24 px to 0).
  final bool initialDrop;

  @override
  ConsumerState<Spotlight> createState() => SpotlightState();
}

class SpotlightState extends ConsumerState<Spotlight> {
  final PageController _pages = PageController();
  final FocusNode _focus = FocusNode(debugLabel: 'Spotlight');
  int _index = 0;

  int get index => _index;

  @override
  void initState() {
    super.initState();
    if (widget.specs.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFocusedChanged(0, widget.specs.first));
  }

  @override
  void didUpdateWidget(Spotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.specs.length && widget.specs.isNotEmpty) {
      _index = widget.specs.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
        if (mounted) widget.onFocusedChanged(_index, widget.specs[_index]);
      });
    }
    if (oldWidget.specs.isEmpty && widget.specs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFocusedChanged(0, widget.specs.first);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(int i) {
    if (i == _index || i < 0 || i >= widget.specs.length) return;
    setState(() => _index = i);
    final spec = widget.specs[i];
    widget.onFocusedChanged(i, spec);
    glassFire(ref, HapticEvent.select);
    try {
      unawaited(SemanticsService.sendAnnouncement(View.of(context), '${i + 1} of ${widget.specs.length}: ${spec.title}', Directionality.of(context)));
    } catch (_) {}
  }

  /// Pages to [i] (the dots, the keys, the strip, the semantics actions).
  void go(int i) {
    if (i < 0 || i >= widget.specs.length) return;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (_pages.hasClients) {
      if (reduced) {
        _pages.jumpToPage(i);
      } else {
        unawaited(_pages.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic));
      }
    }
    _changed(i);
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent || widget.specs.isEmpty) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final spec = widget.specs[_index];
    if (k == LogicalKeyboardKey.arrowRight) {
      go(_index + 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      go(_index - 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      widget.handlers.onOpen(spec, _box());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyP && spec.secondaryIsRecap) {
      widget.handlers.onSecondary(spec, _box());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Rect _box() {
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    final specs = widget.specs;
    if (specs.isEmpty) return const SizedBox.shrink();
    final frame = GlassFrame.of(context);
    final wide = frame.index >= GlassFrameKind.tablet.index;
    final n = specs.length;
    final spec = specs[_index.clamp(0, n - 1)];
    final body = wide
        ? SpotlightStage(specs: specs, index: _index, handlers: widget.handlers, onSelect: go, tiltActive: widget.tiltActive, controlsOnScreen: widget.controlsOnScreen, desktop: frame.index >= GlassFrameKind.desktop.index)
        : _Phone(state: this, specs: specs, spec: spec, n: n);
    return Semantics(
      container: true,
      label: 'Spotlight',
      value: '${_index + 1} of $n',
      increasedValue: _index + 1 < n ? '${_index + 2} of $n' : null,
      decreasedValue: _index > 0 ? '$_index of $n' : null,
      onIncrease: _index + 1 < n ? () => go(_index + 1) : null,
      onDecrease: _index > 0 ? () => go(_index - 1) : null,
      child: Focus(focusNode: _focus, onKeyEvent: _key, child: body),
    );
  }
}

class _Phone extends ConsumerWidget {
  const _Phone({required this.state, required this.specs, required this.spec, required this.n});
  final SpotlightState state;
  final List<SpotlightSpec> specs;
  final SpotlightSpec spec;
  final int n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = spotlightCoverWidth(context, wide: false);
    final h = w * 1.5;
    final margin = GlassFrame.screenMargin(context);
    final widget = state.widget;
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: h + 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: -margin, right: -margin, top: -24, bottom: -24, child: HeroField(palette: spec.palette)),
              NotificationListener<ScrollEndNotification>(
                onNotification: (_) => false,
                child: PageView.builder(
                  controller: state._pages,
                  physics: const SpotlightPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: n,
                  onPageChanged: state._changed,
                  itemBuilder: (context, i) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: _Drop(
                        enabled: widget.initialDrop && i == 0,
                        child: SpotlightTilt(
                          active: widget.tiltActive && i == state.index,
                          child: SpotlightCover(spec: specs[i], width: w, position: i, count: n, handlers: widget.handlers),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20 + 16,
                child: Center(child: SpotlightActions(spec: spec, handlers: widget.handlers, onScreen: widget.controlsOnScreen)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: SpotlightText(spec: spec)),
        const SizedBox(height: 4),
        SpotlightDots(count: n, index: state.index, onSelect: state.go, reduced: reduced),
      ],
    );
  }
}

/// The spotlight drop of the first paint (Spotlight drop): scale 0.9 to 1 and -24 px to 0 on `springLens`; reduced motion fades in over 200 ms.
class _Drop extends ConsumerStatefulWidget {
  const _Drop({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  ConsumerState<_Drop> createState() => _DropState();
}

class _DropState extends ConsumerState<_Drop> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _on = true);
      });
    } else {
      _on = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    if (reduced) {
      return AnimatedOpacity(opacity: _on ? 1 : 0, duration: const Duration(milliseconds: 200), child: widget.child);
    }
    return SpringValue(
      value: _on ? 1 : 0,
      spring: gt.springLens,
      builder: (context, v, _) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, -24 * (1 - v)), child: Transform.scale(scale: 0.9 + 0.1 * v, child: child(context))),
      ),
    );
  }

  Widget child(BuildContext context) => widget.child;
}

/// The droplet page dots: 6 px `g500` dots, the current one an 18 x 6 `iris400` capsule sliding on `springTab`; each a real button.
class SpotlightDots extends StatelessWidget {
  const SpotlightDots({super.key, required this.count, required this.index, required this.onSelect, required this.reduced});
  final int count, index;
  final ValueChanged<int> onSelect;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(
            width: hit,
            height: hit,
            child: GlassPressable(
              material: GlassMaterial.content,
              sink: 0.9,
              shape: const GlassShape.circle(),
              minHit: false,
              onTap: () => onSelect(i),
              semanticsLabel: 'Show spotlight ${i + 1} of $count',
              semanticsSelected: i == index,
              builder: (context, info) => Center(
                child: SpringValue(
                  value: i == index ? 18 : 6,
                  spring: gt.springTab,
                  builder: (context, w, _) => Container(width: w.clamp(6.0, 22.0), height: 6, decoration: BoxDecoration(color: i == index ? gt.colorIris400 : gt.colorG500, borderRadius: BorderRadius.circular(3))),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The palette of a spec for the ambient field.
CoverPalette? spotlightPalette(SpotlightSpec s) => paletteOf(s.palette, s.ambient);
