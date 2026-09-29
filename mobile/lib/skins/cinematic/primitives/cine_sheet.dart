import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_physics.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The body states of a sheet (cinematic 7.9): loading shows a 24 px leader dial and `LOADING`
/// after 400 ms; error shows a notice in the body.
enum CineSheetState { ready, loading, error }

/// The sheet scaffold (cinematic 7.9): `paper.2` raised, radius 0, full width on phones (720
/// centred from 600 px), a 1 px `rule.2` top edge, a 32 x 3 grabber, a 56 px header and a body
/// that scrolls. Pushed by `showCineSheet` inside a `CineSheetRoute`, which owns the Rise; this
/// widget owns the drag (pixels of offset, follows the finger 1:1, rubber band above the top
/// detent, `CineSprings.sheet` release, 30 % / 800 px/s dismissal).
class CineSheet extends StatefulWidget {
  const CineSheet({
    super.key,
    required this.kicker,
    required this.title,
    required this.child,
    this.livePreview = false,
    this.state = CineSheetState.ready,
    this.errorHeadline = 'This didn’t load.',
    this.errorDeck,
    this.onRetry,
    this.reduced = false,
    this.onClose,
  });

  final String kicker, title;
  final Widget child;

  /// `[0.5, 0.92]` detents so the page stays visible above (reader settings and the like).
  final bool livePreview;
  final CineSheetState state;
  final String errorHeadline;
  final String? errorDeck;
  final VoidCallback? onRetry;
  final bool reduced;

  /// Closes the sheet; defaults to popping the enclosing navigator.
  final VoidCallback? onClose;

  @override
  State<CineSheet> createState() => _CineSheetState();
}

class _CineSheetState extends State<CineSheet> with SingleTickerProviderStateMixin {
  /// The displayed offset of the sheet below its top detent, in px (negative above it).
  late final AnimationController _dy = AnimationController.unbounded(vsync: this);
  final _surfaceKey = GlobalKey();
  final _done = FocusNode(debugLabel: 'sheet-done');
  double _raw = 0;
  bool _placed = false, _fromBody = false, _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_placed) return;
    _placed = true;
    if (widget.livePreview && !CineReflow.of(context).fullDetent) {
      final h = MediaQuery.sizeOf(context).height;
      _raw = h * 0.92 - h * 0.5;
      _dy.value = _raw;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = FocusScope.of(context);
      if (scope.focusedChild == null || !scope.focusedChild!.hasPrimaryFocus) _done.requestFocus();
    });
  }

  @override
  void dispose() {
    _dy.dispose();
    _done.dispose();
    super.dispose();
  }

  double get _sheetH {
    final box = _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box.size.height : MediaQuery.sizeOf(context).height * 0.92;
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    (widget.onClose ?? () => Navigator.of(context).maybePop())();
  }

  void _dragUpdate(double dy) {
    _dy.stop();
    _raw += dy;
    _dy.value = _raw >= 0 ? _raw : -rubberBand(-_raw, _sheetH);
  }

  void _dragEnd(double v) {
    final h = _sheetH, screen = MediaQuery.sizeOf(context).height;
    final visible = h - _dy.value;
    if (shouldDismiss(visible / h, v)) {
      cineFeedback(context, HapticEvent.sheetDismiss);
      _close();
      return;
    }
    final detents = widget.livePreview ? [screen * 0.5, h] : [h];
    final target = h - nearestDetent(visible, detents);
    _raw = target;
    if (widget.reduced || CineMotion.reduced(context)) {
      _dy.value = target;
      cineFeedback(context, HapticEvent.sheetDetent);
      return;
    }
    final handle = CineMotion.track(MotionName.rise, CineSprings.sheet.ms);
    _dy.animateWith(SpringSimulation(CineSprings.sheet.description, _dy.value, target, v)).whenComplete(() {
      handle.end();
      if (mounted && !_closing) cineFeedback(context, HapticEvent.sheetDetent);
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _fromBody = true;
      _dragUpdate(-n.overscroll);
    } else if (n is ScrollEndNotification && _fromBody) {
      _fromBody = false;
      _dragEnd(n.dragDetails?.primaryVelocity ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = MediaQuery.sizeOf(context);
    final topMax = size.height * 0.92;
    final live = widget.livePreview;
    final inset = MediaQuery.viewPaddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom;

    Widget body = switch (widget.state) {
      CineSheetState.ready => widget.child,
      CineSheetState.loading => Padding(
          padding: EdgeInsets.symmetric(vertical: c.space8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CineLeaderDial(size: 24),
            SizedBox(height: c.space3),
            CineDelayed(delay: const Duration(milliseconds: 400), child: CineRoleText('LOADING', c.typeKicker, color: c.colorInk60)),
          ],),
        ),
      CineSheetState.error => CineNotice(
          tone: CineNoticeTone.error,
          headline: widget.errorHeadline,
          deck: widget.errorDeck,
          primary: widget.onRetry == null ? null : CineNoticeAction('Retry', widget.onRetry!),
        ),
    };
    body = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space6 + inset),
        child: SizedBox(width: double.infinity, child: body),
      ),
    );

    final header = GestureDetector(
      key: const Key('cine-sheet-drag'),
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragUpdate: (d) => _dragUpdate(d.delta.dy),
      onVerticalDragEnd: (d) => _dragEnd(d.velocity.pixelsPerSecond.dy),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(child: Container(key: const Key('cine-sheet-grabber'), width: 32, height: 3, color: c.colorInk30)),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: EdgeInsets.only(left: c.space4, right: c.space2),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  CineRoleText(widget.kicker, c.typeKicker, color: c.colorInk60),
                  CineRoleText(widget.title, c.typeSubhead),
                ],),
              ),
              CineButton(key: const Key('cine-sheet-done'), label: 'Done', variant: CineButtonVariant.quiet, focusNode: _done, onPressed: _close),
            ],),
          ),
        ),
      ],),
    );

    final column = Column(mainAxisSize: live ? MainAxisSize.max : MainAxisSize.min, children: [
      header,
      if (live) Expanded(child: body) else Flexible(child: body),
    ],);

    Widget surface = CineStock.raised(
      KeyedSubtree(
        key: const Key('cine-sheet-surface'),
        child: Container(
        key: _surfaceKey,
        decoration: BoxDecoration(color: c.colorPaper2, border: Border(top: BorderSide(color: c.colorRule2))),
          child: live ? SizedBox(height: topMax, child: column) : ConstrainedBox(constraints: BoxConstraints(maxHeight: topMax), child: column),
        ),
      ),
    );
    // Paper under the sheet so an upward rubber band never shows a gap.
    surface = Stack(clipBehavior: Clip.none, children: [
      surface,
      Positioned(left: 0, right: 0, bottom: -size.height, height: size.height, child: ColoredBox(color: c.colorPaper2)),
    ],);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: widget.title,
        child: FocusTraversalGroup(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width >= 600 ? 720 : double.infinity),
              child: AnimatedBuilder(
                animation: _dy,
                child: surface,
                builder: (_, child) => Transform.translate(offset: Offset(0, _dy.value), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
