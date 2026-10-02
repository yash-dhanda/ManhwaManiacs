import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("an older toast's Undo runs its own undo, not the newest one", () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final ran = <String>[];
    void a() => ran.add('a');
    void b() => ran.add('b');
    final n = c.read(glassToastProvider.notifier)
      ..show(GlassToastSpec('A removed', undo: a))
      ..show(GlassToastSpec('B removed', undo: b));
    expect(n.undo(a), isTrue);
    expect(ran, ['a']);
    expect(c.read(glassToastProvider).first.leaving, isTrue);
    expect(n.undoLast(), isTrue);
    expect(ran, ['a', 'b']);
  });
}
