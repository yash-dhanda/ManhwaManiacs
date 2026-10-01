import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/shell/insets.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Anchors for the settings index (glass 8.25): every row registers a key under its index id so a search hit can scroll to it and
/// flash it with the Row pulse. One object for the whole Settings stack.
class SettingsAnchors extends ChangeNotifier {
  final Map<String, GlobalKey> _keys = {};
  String? _pulsing;

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'settings:$id'));

  String? get pulsing => _pulsing;

  /// Scrolls [id] into view (alignment 0) and starts its pulse. Returns false when the row is not mounted.
  bool reveal(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return false;
    // The row lands just below the floating bar (its top inset), not under it.
    final viewport = Scrollable.maybeOf(ctx)?.position.viewportDimension ?? 0;
    final top = GlassInsets.of(ctx).top + 8;
    Scrollable.ensureVisible(ctx, alignment: viewport > top ? top / viewport : 0);
    _pulsing = id;
    notifyListeners();
    return true;
  }

  void pulseDone(String id) {
    if (_pulsing != id) return;
    _pulsing = null;
    notifyListeners();
  }
}

final settingsAnchorsProvider = Provider<SettingsAnchors>((ref) => SettingsAnchors(), name: 'settingsAnchors');

/// Wraps [child] as the index row [id]: a keyed subtree plus the Row pulse (`iris600` at 14 % fading to 0 over 900 ms on the
/// `fadeOut` curve; reduced motion: shown 900 ms then removed).
class SettingsAnchor extends ConsumerStatefulWidget {
  const SettingsAnchor({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  ConsumerState<SettingsAnchor> createState() => _SettingsAnchorState();
}

class _SettingsAnchorState extends ConsumerState<SettingsAnchor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final SettingsAnchors _anchors = ref.read(settingsAnchorsProvider);
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _anchors.addListener(_changed);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _on = false);
        _anchors.pulseDone(widget.id);
      }
    });
  }

  void _changed() {
    if (_anchors.pulsing != widget.id || _on || !mounted) return;
    setState(() => _on = true);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _anchors.removeListener(_changed);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return KeyedSubtree(
      key: _anchors.keyFor(widget.id),
      child: Stack(children: [
        widget.child,
        if (_on)
          Positioned.fill(
            child: IgnoreSemantics(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final t = reduced ? 1.0 : 1 - Curves.easeOut.transform(_c.value);
                  return ColoredBox(color: Color.fromRGBO(0x75, 0x63, 0xF2, 0.14 * t));
                },
              ),
            ),
          ),
      ],),
    );
  }
}

/// `ExcludeSemantics` with a shorter name.
class IgnoreSemantics extends StatelessWidget {
  const IgnoreSemantics({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => IgnorePointer(child: ExcludeSemantics(child: child));
}

/// One settings row (glass 7.17): title, optional caption line, trailing control (a `GlassSwitch`, a value, ...). [id] is the
/// index id the search overlay scrolls to.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.id, required this.title, this.caption, this.value, this.trailing, this.onTap, this.caret = false, this.enabled = true, this.loading = false});
  final String id, title;
  final String? caption, value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool caret, enabled, loading;

  @override
  Widget build(BuildContext context) => SettingsAnchor(
        id: id,
        child: GlassListRow(title: title, subtitle: caption, value: value, trailing: trailing, onTap: onTap, caret: caret, enabled: enabled, loading: loading),
      );
}

/// A row whose body is a control of its own (a slider, a segmented control, chips): padded, anchored, with a title and caption.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, required this.id, required this.title, this.caption, required this.child});
  final String id, title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => SettingsAnchor(
        id: id,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            GlassText(title, role: gt.typeBody, maxScale: 1.6),
            if (caption != null) Padding(padding: const EdgeInsets.only(top: 2), child: GlassText(caption!, role: gt.typeFootnote, color: gt.colorLabel2, maxScale: 1.6)),
            const SizedBox(height: 8),
            child,
          ],),
        ),
      );
}

/// A titled group of rows (glass 7.17 grouped list). [id] anchors the group header for `reading-novels`, `listen` and `ambient`.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.id, this.header, this.footer, required this.children});
  final String? id, header, footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final g = GlassGroupedList(header: header, footer: footer, children: children);
    return id == null ? g : SettingsAnchor(id: id!, child: g);
  }
}

/// Anchors an existing widget (one that builds its own row) under an index id.
class SettingsAnchorBox extends StatelessWidget {
  const SettingsAnchorBox({super.key, required this.id, required this.child});
  final String id;
  final Widget child;
  @override
  Widget build(BuildContext context) => SettingsAnchor(id: id, child: child);
}
