import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass_scroll_behavior.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart'
    show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scroll_edge.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_meta.dart';
import 'package:manhwamaniacs/skins/glass/shell/insets.dart';
import 'package:manhwamaniacs/skins/glass/shell/large_title.dart';
import 'package:manhwamaniacs/skins/glass/shell/nav_row.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/toolbar.dart';

enum GlassLeading { back, profile, none }

/// One trailing action of a bar (glass 7.14): at most three on phones; [foldable] ones fold into "More" on wider frames when the
/// toolbar would overflow.
class GlassBarAction {
  const GlassBarAction(
      {required this.id,
      required this.label,
      required this.glyph,
      required this.onPress,
      this.badge,
      this.foldable = false,});
  final String id;
  final String label;
  final Glyph glyph;
  final VoidCallback onPress;
  final int? badge;
  final bool foldable;

  GlassButtonIcon get icon => GlassButtonIcon.glyph(glyph);
}

/// How a screen describes its chrome once for every frame (glass 8.0.1): the floating nav row (phone) or toolbar (tablet and desktop
/// frames), the large title, the scroll insets and the two scroll edges. Screens never build their own top bar.
class GlassScaffold extends ConsumerStatefulWidget {
  const GlassScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.largeTitle = true,
    this.leading = GlassLeading.profile,
    this.trailing = const [],
    this.contentModeSwitch = false,
    this.overflow = const [],
    this.showDepth = false,
    this.ambient,
    this.mature = false,
    this.routeKey,
  });

  final String title;
  final bool largeTitle;
  final GlassLeading leading;
  final List<GlassBarAction> trailing;
  final bool contentModeSwitch;
  final List<GlassMenuEntry> overflow;
  final bool showDepth;
  final List<Widget> slivers;
  final GlassAmbientSpec? ambient;
  final bool mature;

  /// The page key of the route this scaffold is the page of (the stack overview captures it).
  final String? routeKey;

  @override
  ConsumerState<GlassScaffold> createState() => _GlassScaffoldState();
}

class _GlassScaffoldState extends ConsumerState<GlassScaffold> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(
        () => _offset.value = _scroll.hasClients ? _scroll.offset : 0,);
    GlassScrollTop.register(_scroll);
  }

  @override
  void dispose() {
    GlassScrollTop.unregister(_scroll);
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _publish() {
    final meta = GlassRouteMetaScope.maybeOf(context);
    if (meta == null) return;
    scheduleMicrotask(
        () => meta.publish(title: widget.title, mature: widget.mature),);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _publish();
  }

  @override
  void didUpdateWidget(GlassScaffold old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.mature != widget.mature) _publish();
  }

  List<GlassBarAction> _actions(bool phone) {
    var a = widget.trailing;
    if (phone && a.length > 3) a = a.sublist(0, 3);
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final frame = GlassFrame.of(context);
    final phone = frame == GlassFrameKind.phone;
    final safe = MediaQuery.paddingOf(context);
    final insets = GlassInsets.watch(context, ref);
    final toast = ref.watch(glassToastShowingProvider);
    final accessory = ref.watch(glassAccessoryVisibleProvider);
    final margin = GlassFrame.screenMargin(context);
    final offline = ref.watch(glassOfflineProvider);
    final actions = _actions(phone);

    Widget content = CustomScrollView(
      controller: _scroll,
      physics: glassScrollPhysics,
      keyboardDismissBehavior: glassKeyboardDismiss,
      slivers: [
        SliverPadding(
            padding:
                EdgeInsets.only(top: insets.top - (widget.largeTitle ? 0 : 0)),),
        if (widget.largeTitle)
          SliverToBoxAdapter(
              child: GlassLargeTitle(
                  title: widget.title, margin: margin, offset: _offset,),),
        SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            sliver: SliverMainAxisGroup(slivers: widget.slivers),),
        SliverPadding(padding: EdgeInsets.only(bottom: insets.bottom)),
      ],
    );
    if (widget.ambient != null) {
      content = GlassAmbientScope(spec: widget.ambient!, child: content);
    }

    final top =
        GlassInsets.topPlateau(frame: frame, safeTop: safe.top, toast: toast);
    final bottom = GlassInsets.bottomPlateau(
        frame: frame, safeBottom: safe.bottom, accessory: accessory,);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
      fit: StackFit.expand,
      children: [
        Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: content,),),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
                child: GlassScrollEdge(edge: GlassEdge.top, plateau: top),),),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
                child:
                    GlassScrollEdge(edge: GlassEdge.bottom, plateau: bottom),),),
        if (phone)
          Positioned(
            top: safe.top + 8,
            left: margin,
            right: margin,
            height: math.max(44.0, GlassFrame.hitMin(context)),
            child: GlassNavRow(
              title: widget.title,
              leading: widget.leading,
              actions: actions,
              overflow: widget.overflow,
              contentModeSwitch: widget.contentModeSwitch,
              showDepth: widget.showDepth,
              offline: offline,
              offset: _offset,
              hasLargeTitle: widget.largeTitle,
              currentKey: widget.routeKey,
            ),
          )
        else
          Positioned(
            top: 12,
            left: margin,
            right: margin,
            height: 48,
            child: GlassToolbar(
              title: widget.title,
              leading: widget.leading,
              actions: actions,
              overflow: widget.overflow,
              offline: offline,
              offset: _offset,
              hasLargeTitle: widget.largeTitle,
              currentKey: widget.routeKey,
            ),
          ),
      ],
    ));
  }
}

/// The scroll views of the current route register here so the dock can scroll the active screen to the top.
abstract final class GlassScrollTop {
  static final List<ScrollController> _stack = [];
  static void register(ScrollController c) => _stack.add(c);
  static void unregister(ScrollController c) => _stack.remove(c);

  /// Scrolls the topmost registered controller that is attached to the top; returns whether anything scrolled.
  static bool scrollToTop() {
    for (final c in _stack.reversed) {
      if (c.hasClients) {
        if (c.offset <= 0) return false;
        unawaited(c.animateTo(0,
            duration: const Duration(milliseconds: 414),
            curve: Curves.easeOutCubic,),);
        return true;
      }
    }
    return false;
  }
}
