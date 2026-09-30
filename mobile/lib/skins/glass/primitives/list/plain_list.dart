import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';

/// No container: rows separated by hairlines (notifications, bookmarks, sessions) (glass 7.17).
class GlassPlainList extends StatelessWidget {
  const GlassPlainList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: glassSeparated(children));
}
