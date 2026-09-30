import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Where the orb was when the search opened, so the field can grow out of it and shrink back into it.
final glassSearchOriginProvider = StateProvider<Rect?>((ref) => null);

/// `mobile/38` fills this with the Discover body; until then the slot shows the shared pending screen.
final glassDiscoverBodyProvider = StateProvider<Widget Function(BuildContext context, String query)?>((ref) => null);

/// The 50 px search orb's content (its glass is a shape of the dock's group). A tap opens `/search`.
class GlassSearchOrbBody extends StatelessWidget {
  const GlassSearchOrbBody({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        onTap: onTap,
        semanticsLabel: 'Search',
        tooltip: 'Search',
        builder: (context, info) => const Center(child: GlassIcon(GlassIconRole.search)),
      );
}

void openGlassSearch(BuildContext context, WidgetRef ref, {String? query}) {
  ref.read(glassSearchOriginProvider.notifier).state = globalRectOf(context);
  final loc = query == null || query.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(query)}';
  unawaited(ref.read(skinRouterProvider).push<void>(loc));
}

/// The `/search` page (a root-navigator route with a 434 ms transition): the field grows out of the orb along `springMorph` while the
/// dock sinks; above it the Discover body. "Cancel" shrinks it back and pops.
class GlassSearchPage extends ConsumerStatefulWidget {
  const GlassSearchPage({super.key, required this.animation});
  final Animation<double> animation;

  @override
  ConsumerState<GlassSearchPage> createState() => _GlassSearchPageState();
}

class _GlassSearchPageState extends ConsumerState<GlassSearchPage> {
  final TextEditingController _q = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'search field');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = GoRouter.of(context).state.uri.queryParameters['q'];
    if (initial != null) _q.text = initial;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _write(String q) => GoRouter.of(context).replace<void>(q.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(q)}');

  @override
  Widget build(BuildContext context) {
    final body = ref.watch(glassDiscoverBodyProvider);
    final origin = ref.watch(glassSearchOriginProvider);
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final fieldRect = Rect.fromLTWH(kFieldInset, size.height - (keyboard > 0 ? keyboard + 12 : safeBottom + kFieldInset) - 50, size.width - 2 * kFieldInset, 50);
    final orb = origin ?? Rect.fromLTWH(size.width - kFieldInset - 50, fieldRect.top, 50, 50);
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: widget.animation,
          child: body != null ? body(context, _q.text) : const PendingScreen(screenId: 'discover', location: '/search'),
        ),
        AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            final t = Curves.linear.transform(widget.animation.value.clamp(0.0, 1.0));
            return Positioned.fromRect(rect: Rect.lerp(orb, fieldRect, t)!, child: child!);
          },
          child: GlassSearchField(
            variant: GlassSearchVariant.bottom,
            controller: _q,
            focusNode: _focus,
            onQuery: (q) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => _write(q));
            },
            onSubmitted: _write,
            onCancel: () => Navigator.of(context).maybePop(),
            onCollapse: () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }
}

const double kFieldInset = 21;

/// The route transition of `/search`: 434 ms (the `morph` settle).
const Duration kGlassSearchDuration = Duration(milliseconds: 434);

