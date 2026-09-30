import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/physical_activator.dart';

void main() {
  testWidgets('matches the physical key with Alt, whatever the logical key is', (tester) async {
    const a = PhysicalActivator(PhysicalKeyboardKey.digit1);
    // Option+1 on an iPad keyboard yields "¡".
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    const ev = KeyDownEvent(physicalKey: PhysicalKeyboardKey.digit1, logicalKey: LogicalKeyboardKey(0xA1), timeStamp: Duration.zero);
    expect(a.accepts(ev, HardwareKeyboard.instance), isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(a.accepts(ev, HardwareKeyboard.instance), isFalse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    const other = KeyDownEvent(physicalKey: PhysicalKeyboardKey.digit2, logicalKey: LogicalKeyboardKey.digit2, timeStamp: Duration.zero);
    expect(a.accepts(other, HardwareKeyboard.instance), isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  });
}
