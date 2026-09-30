import 'package:flutter/widgets.dart';

/// The recap's hardware-keyboard group `Recap`: `Enter` continue, `s` skip the recap, `Esc` close,
/// `Space` completes the streaming and then pauses or resumes the countdown. Keys bubble up from
/// whichever control has focus; a control that handles a key (a button on Enter) wins.
class RecapKeys extends StatelessWidget {
  const RecapKeys({super.key, required this.child, required this.onKey});
  final Widget child;
  final KeyEventResult Function(KeyEvent) onKey;

  /// Listed in the shortcut sheet under the group `Recap`.
  static const group = 'Recap';
  static const entries = <(String, String)>[('Enter', 'Continue'), ('S', 'Skip the recap'), ('Esc', 'Close'), ('Space', 'Finish the recap, pause the countdown')];

  @override
  Widget build(BuildContext context) => Focus(onKeyEvent: (_, e) => onKey(e), child: child);
}
