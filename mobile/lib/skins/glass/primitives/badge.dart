import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';

/// glass 7.20 status tags.
enum GlassStatus {
  reading('READING', 'reading'),
  completed('COMPLETED', 'completed'),
  onHold('ON HOLD', 'on hold'),
  planToRead('PLAN TO READ', 'plan to read'),
  dropped('DROPPED', 'dropped'),
  unread('UNREAD', 'unread');

  const GlassStatus(this.text, this.spoken);
  final String text;
  final String spoken;

  Color get color => switch (this) {
        GlassStatus.reading => gt.colorIris400,
        GlassStatus.completed => gt.colorSuccess,
        GlassStatus.onHold => gt.colorWarning,
        GlassStatus.planToRead => gt.colorInfo,
        GlassStatus.dropped => GlassColors.g700,
        GlassStatus.unread => GlassColors.g800,
      };
}

/// Every badge is a capsule that also contributes a text fragment to its host's semantics label
/// (`badgeLabel`), so a badge is never the only signal (glass 7.20).
class GlassBadge extends StatelessWidget {
  const GlassBadge._(this._kind, {super.key, this.count = 0, this.max = 9, this.status, this.text, this.onCover = false, this.loading = false, this.error = false, this.icon, this.disabled = false, this.child});

  /// A count capsule: "9+" above nine (dock and bell), "99+" on posters.
  const GlassBadge.count(int count, {Key? key, int max = 9, bool loading = false, bool error = false}) : this._(_Kind.count, key: key, count: count, max: max, loading: loading, error: error);

  const GlassBadge.dot({Key? key}) : this._(_Kind.dot, key: key);

  /// "N NEW", top-right on posters.
  const GlassBadge.newChapters(int count, {Key? key}) : this._(_Kind.newCh, key: key, count: count, max: 99);

  const GlassBadge.status(GlassStatus status, {Key? key, bool onCover = false}) : this._(_Kind.status, key: key, status: status, onCover: onCover);

  const GlassBadge.mature({Key? key, bool onCover = false}) : this._(_Kind.mature, key: key, onCover: onCover);

  /// The `age-gate` glyph on a 22 px disc.
  const GlassBadge.ageGate({Key? key}) : this._(_Kind.ageGate, key: key);

  /// A source chip: a 12 px favicon (or monogram tile) and the source name.
  const GlassBadge.source(String name, {Key? key, Widget? icon}) : this._(_Kind.source, key: key, text: name, child: icon);

  const GlassBadge.downloaded({Key? key, bool onCover = false}) : this._(_Kind.downloaded, key: key, onCover: onCover);

  /// "Saved copy · 2 h".
  const GlassBadge.offline(String text, {Key? key}) : this._(_Kind.offline, key: key, text: text);

  /// Admin, You, This device.
  const GlassBadge.role(String text, {Key? key}) : this._(_Kind.role, key: key, text: text);

  final _Kind _kind;
  final int count;
  final int max;
  final GlassStatus? status;
  final String? text;
  final bool onCover;
  final bool loading;
  final bool error;
  final IconData? icon;
  final bool disabled;
  final Widget? child;

  /// What this badge adds to its host's semantics label.
  String? get semanticsFragment => switch (_kind) {
        _Kind.count => loading || error ? null : '$count new',
        _Kind.dot => 'new activity',
        _Kind.newCh => '$count new chapters',
        _Kind.status => status!.spoken,
        _Kind.mature => 'mature',
        _Kind.ageGate => 'mature',
        _Kind.source => 'on $text',
        _Kind.downloaded => 'downloaded',
        _Kind.offline => text,
        _Kind.role => text,
      };

  static String _capped(int n, int max) => n > max ? '$max+' : '$n';

  @override
  Widget build(BuildContext context) {
    Widget capsule({required double height, required Color fill, required Widget child, Color? rim, EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 8), double minWidth = 0}) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: height, minWidth: minWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(height), border: rim == null ? null : Border.all(color: rim)),
            child: Padding(padding: pad, child: Center(widthFactor: 1, heightFactor: 1, child: child)),
          ),
        );

    Widget body;
    switch (_kind) {
      case _Kind.count:
        body = capsule(
          height: 18,
          minWidth: 18,
          fill: error ? gt.colorWarning : gt.colorIris400,
          pad: const EdgeInsets.symmetric(horizontal: 5),
          child: loading
              ? const GlassSpinner(size: 10, color: Color(0xFF000000))
              : error
                  ? const SizedBox(width: 8, height: 8)
                  : GlassLabel(_capped(count, max), role: gt.typeCaption1, wght: 700, color: const Color(0xFF000000)),
        );
        if (!loading && !error) body = GlassPop(trigger: count, child: body);
      case _Kind.dot:
        body = Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: const Color(0xFF000000), shape: BoxShape.circle, border: Border.all(width: 2)),
          child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris400, shape: BoxShape.circle)),
        );
      case _Kind.newCh:
        body = capsule(height: 18, fill: gt.colorIris400, child: GlassLabel('${_capped(count, 99)} NEW', role: gt.typeCaption1, wght: 700, color: const Color(0xFF000000)));
      case _Kind.status:
        final c = status!.color;
        final label = GlassLabel(status!.text, role: gt.typeCaption1, wght: 600, extraTrackingEm: 0.06, color: c);
        body = onCover
            ? capsule(height: 22, fill: gt.colorCoverBacking, rim: c.withValues(alpha: 0.4), child: label)
            : capsule(height: 22, fill: Color.alphaBlend(c.withValues(alpha: 0.18), const Color(0xFF000000)), child: label);
      case _Kind.mature:
        final c = gt.colorMature;
        final label = GlassLabel('18+', role: gt.typeCaption1, wght: 600, color: c);
        body = onCover
            ? capsule(height: 20, fill: gt.colorCoverBacking, rim: c.withValues(alpha: 0.4), child: label)
            : capsule(height: 20, fill: Color.alphaBlend(c.withValues(alpha: 0.18), const Color(0xFF000000)), child: label);
      case _Kind.ageGate:
        body = Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xB8000000), shape: BoxShape.circle),
          child: const Icon(GlassGlyphs.ageGateRegular, size: 14, color: Color(0xFFFF5C93)),
        );
      case _Kind.source:
        body = capsule(
          height: 20,
          fill: gt.colorFill3,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (child != null) ...[SizedBox(width: 12, height: 12, child: child), const SizedBox(width: 4)],
              Flexible(child: GlassLabel(text!, role: gt.typeCaption1, color: gt.colorLabel1)),
            ],
          ),
        );
      case _Kind.downloaded:
        const droplet = Icon(GlassGlyphs.dropletFill, size: 14, color: Color(0xFF3DDC84));
        body = onCover
            ? Container(width: 22, height: 22, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xB8000000), shape: BoxShape.circle), child: droplet)
            : droplet;
      case _Kind.offline:
        body = capsule(height: 20, fill: Color.alphaBlend(gt.colorWarning.withValues(alpha: 0.18), const Color(0xFF000000)), child: GlassLabel(text!, role: gt.typeCaption1, wght: 600, color: gt.colorWarning));
      case _Kind.role:
        body = capsule(height: 20, fill: gt.colorFill2, child: GlassLabel(text!, role: gt.typeCaption1, wght: 600, color: gt.colorLabel1));
    }
    return Opacity(opacity: disabled ? 0.4 : 1, child: body);
  }
}

enum _Kind { count, dot, newCh, status, mature, ageGate, source, downloaded, offline, role }

/// A host's semantics label: the title and each badge's fragment ("Solo Leveling, 3 new chapters, downloaded").
String badgeLabel(String title, Iterable<GlassBadge> badges) {
  final parts = [title, for (final b in badges) if (b.semanticsFragment != null) b.semanticsFragment!];
  return parts.join(', ');
}

/// Count pop (glass 4.10): 1, 1.25, 1 on `springTick` whenever [trigger] changes.
class GlassPop extends ConsumerStatefulWidget {
  const GlassPop({super.key, required this.trigger, required this.child, this.peak = 1.25});
  final Object trigger;
  final Widget child;
  final double peak;

  @override
  ConsumerState<GlassPop> createState() => _GlassPopState();
}

class _GlassPopState extends ConsumerState<GlassPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: gt.springTick.ms));

  @override
  void didUpdateWidget(GlassPop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !ref.read(glassReducedProvider)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          // 1 -> peak -> 1 with a springy return.
          final t = _c.value;
          final s = t == 0 || t == 1 ? 1.0 : 1 + (widget.peak - 1) * (t < 0.35 ? t / 0.35 : (1 - (t - 0.35) / 0.65) * (1 + 0.25 * (1 - t)));
          return Transform.scale(scale: s, child: child);
        },
      );
}

/// A count badge pinned to the top-right corner of [child].
class GlassBadged extends StatelessWidget {
  const GlassBadged({super.key, required this.child, required this.badge, this.offset = const Offset(6, -6)});
  final Widget child;
  final Widget? badge;
  final Offset offset;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (badge != null) Positioned(top: offset.dy, right: -offset.dx, child: badge!),
        ],
      );
}

