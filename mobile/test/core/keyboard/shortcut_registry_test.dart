import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pump(WidgetTester t, List<ShortcutEntry> entries) async {
    final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: RegisteredShortcuts(
            group: 'General',
            entries: entries,
            child: Column(children: [const TextField(key: Key('tf')), TextButton(autofocus: true, onPressed: () {}, child: const Text('b'))]),
          ),
        ),
      ),
    ),);
    await t.pump();
    return container;
  }

  testWidgets('invokes a binding and lists it in the registry', (t) async {
    var n = 0;
    final c = await pump(t, [
      ShortcutEntry(
        group: 'General',
        activator: const SingleActivator(LogicalKeyboardKey.keyK, control: true),
        description: 'Open',
        onInvoke: () => n++,
      ),
    ]);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(n, 1);
    final groups = c.read(shortcutRegistryProvider.notifier).registeredGroups();
    expect(groups.single.name, 'General');
    expect(groups.single.entries.single.description, 'Open');
  });

  testWidgets('unregisters on dispose', (t) async {
    final c = await pump(t, [
      ShortcutEntry(group: 'General', activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'd', onInvoke: () {}),
    ]);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    expect(c.read(shortcutRegistryProvider.notifier).registeredGroups(), isEmpty);
  });

  testWidgets('nothing fires while a text field has focus', (t) async {
    var n = 0;
    await pump(t, [
      ShortcutEntry(group: 'General', activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'd', singleKey: true, onInvoke: () => n++),
    ]);
    await t.tap(find.byKey(const Key('tf')));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.slash);
    expect(n, 0);
  });

  testWidgets('single-key bindings obey the preference', (t) async {
    var n = 0;
    final c = await pump(t, [
      ShortcutEntry(group: 'General', activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'd', singleKey: true, onInvoke: () => n++),
    ]);
    await t.sendKeyEvent(LogicalKeyboardKey.slash);
    expect(n, 1);
    await c.read(singleKeyShortcutsProvider.notifier).set(false);
    await t.sendKeyEvent(LogicalKeyboardKey.slash);
    expect(n, 1);
    expect(prefs.getString('mm.shortcuts.single.device'), 'off');
  });

  testWidgets('consumed keys never reach a binding', (t) async {
    var n = 0;
    bool eat(KeyEvent e) => e.logicalKey == LogicalKeyboardKey.digit2;
    keyConsumers.add(eat);
    addTearDown(() => keyConsumers.remove(eat));
    await pump(t, [
      ShortcutEntry(group: 'General', activator: const SingleActivator(LogicalKeyboardKey.digit2), description: 'd', singleKey: true, onInvoke: () => n++),
    ]);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    expect(n, 0);
  });
}
