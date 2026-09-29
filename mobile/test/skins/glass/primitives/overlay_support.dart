import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';

import 'support.dart';

/// A navigator host for overlay tests: a page (wrapped in [GlassRecede]) with a focusable trigger, and the
/// recede scope above the navigator like the Glass root.
class OverlayHost {
  OverlayHost(this.tester);
  final WidgetTester tester;
  final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
  final FocusNode trigger = FocusNode(debugLabel: 'trigger');

  Future<void> pump({
    Size size = const Size(390, 844),
    TargetPlatform platform = TargetPlatform.iOS,
    bool reduced = false,
    bool solid = false,
    List<Override> overrides = const [],
    Widget? page,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      primHost(
        GlassRecedeScope(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Navigator(
              key: nav,
              onGenerateRoute: (s) => PageRouteBuilder<void>(
                pageBuilder: (context, _, __) => ColoredBox(
                  color: const Color(0xFF202030),
                  child: GlassRecede(
                    child: page ??
                        Center(
                          child: Focus(focusNode: trigger, child: const SizedBox(width: 100, height: 44, child: Text('page'))),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        size: size,
        platform: platform,
        reduced: reduced,
        solid: solid,
        overrides: overrides,
        align: false,
      ),
    );
    if (reduced) bindReduced(tester);
    await tester.pump(const Duration(milliseconds: 50));
  }

  void push(Route<dynamic> r) => nav.currentState!.push<dynamic>(r);
}
