import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';

/// Registers a Circle surface with the poll controller (cinematic 9.3.8): the 60 s timer runs while
/// some scope is visible (an enabled `TickerMode`: offstage branches and covered routes are not)
/// and the app is resumed.
class CirclePollScope extends ConsumerStatefulWidget {
  const CirclePollScope({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CirclePollScope> createState() => _CirclePollScopeState();
}

class _CirclePollScopeState extends ConsumerState<CirclePollScope> {
  final Object _token = Object();
  late final _controller = ref.read(circlePollControllerProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.register(_token, visible: TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _controller.unregister(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
