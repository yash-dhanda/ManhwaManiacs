import 'package:flutter/widgets.dart';

/// Rebuilds everything below it, re-running [builder] so boot state (the
/// `mm.skin.*` keys) is read again. A key swap alone would keep old overrides.
class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.builder});
  final Widget Function() builder;
  static AppRestartState of(BuildContext context) =>
      context.findAncestorStateOfType<AppRestartState>()!;
  @override
  State<AppRestart> createState() => AppRestartState();
}

class AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();
  late Widget _child = widget.builder();
  void restart() => setState(() {
        _key = UniqueKey();
        _child = widget.builder();
      });
  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: _child);
}
