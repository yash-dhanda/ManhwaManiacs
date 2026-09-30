import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rail_math.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A section rail for items that are not posters (cuttings, source tiles): the section header (drawn
/// rule, folio, revealed H3, See all), then a snapping horizontal row that shows [visiblePhone] items
/// on phones and [visibleTablet] from 600 px, at the rail gap.
class TonightRail extends StatefulWidget {
  const TonightRail({
    super.key,
    required this.headingId,
    required this.heading,
    required this.folio,
    required this.itemCount,
    required this.visiblePhone,
    required this.visibleTablet,
    required this.itemHeight,
    required this.itemBuilder,
    this.onSeeAll,
    this.caption,
    this.captionWidget,
    this.error = false,
    this.onRetry,
  });

  final String headingId, heading, folio;
  final int itemCount;
  final double visiblePhone, visibleTablet;

  /// The row's height for an item [width] wide.
  final double Function(double width) itemHeight;
  final Widget Function(BuildContext context, int index, double width) itemBuilder;
  final VoidCallback? onSeeAll;

  /// A kicker line under the header (`SUGGESTED SOURCES`).
  final String? caption;

  /// A widget under the header instead of a kicker line (`Sent to you`'s typed note).
  final Widget? captionWidget;
  final bool error;
  final VoidCallback? onRetry;

  @override
  State<TonightRail> createState() => _TonightRailState();
}

class _TonightRailState extends State<TonightRail> {
  final _scroll = ScrollController();
  double _w = 100, _gap = 8;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _snap() {
    if (!_scroll.hasClients) return;
    final target = railSnapOffset(offset: _scroll.offset, posterWidth: _w, gap: _gap, maxExtent: _scroll.position.maxScrollExtent);
    if ((target - _scroll.offset).abs() < 0.5) return;
    if (CineMotion.reduced(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: CineDur.column, curve: CineCurves.settle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final wide = tonightWide(context);
    return Padding(
      padding: EdgeInsets.only(bottom: wide ? 64 : 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineSectionHeader(headingId: widget.headingId, heading: widget.heading, folio: widget.folio, onSeeAll: widget.onSeeAll),
        SizedBox(height: c.space3),
        if (widget.caption != null) ...[CineRoleText(widget.caption!, c.typeKicker, color: c.colorInk45), SizedBox(height: c.space2)],
        if (widget.captionWidget != null) ...[widget.captionWidget!, SizedBox(height: c.space2)],
        if (widget.error)
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: c.space3, children: [
            CineRoleText("This row didn't load.", c.typeCaption, color: c.colorProof),
            if (widget.onRetry != null) CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onRetry),
          ],)
        else
          LayoutBuilder(builder: (context, box) {
            final screenW = MediaQuery.sizeOf(context).width;
            final visible = wide ? widget.visibleTablet : widget.visiblePhone;
            _gap = railGap(screenW);
            _w = railPosterWidth(contentWidth: box.maxWidth, visible: visible, gap: _gap);
            return SizedBox(
              height: widget.itemHeight(_w),
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.horizontal) _snap();
                  return false;
                },
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemExtent: _w + _gap,
                  itemCount: widget.itemCount,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(right: _gap),
                    child: SizedBox(width: _w, child: widget.itemBuilder(context, i, _w)),
                  ),
                ),
              ),
            );
          },),
      ],),
    );
  }
}
