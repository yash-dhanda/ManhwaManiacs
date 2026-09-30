import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ShortcutActivator;

/// Matches on the physical key plus Alt (glass 8.0.6): Option+1 on an iPad keyboard yields "¡" as the logical key.
class PhysicalActivator implements ShortcutActivator {
  const PhysicalActivator(this.physical, {this.alt = true});
  final PhysicalKeyboardKey physical;
  final bool alt;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      (event is KeyDownEvent || event is KeyRepeatEvent) && event.physicalKey == physical && state.isAltPressed == alt;

  @override
  String debugDescribeKeys() => '${alt ? 'Alt+' : ''}${physical.debugName}';

  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;
}
