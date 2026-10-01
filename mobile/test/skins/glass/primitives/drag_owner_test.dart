import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';

void main() {
  test('two owners: a row and a rail at its leading edge', () {
    final r = GlassDragOwnerRegistry();
    final atStart = ValueNotifier(true);
    r.register('row', kind: GlassDragOwnerKind.row, rect: () => const Rect.fromLTWH(0, 0, 390, 60));
    r.register('rail', kind: GlassDragOwnerKind.rail, rect: () => const Rect.fromLTWH(0, 100, 390, 200), atLeadingEdge: atStart);
    // inside the row, away from the back strip: owned both ways
    expect(r.ownsDragAt(const Offset(200, 30), movingRight: true), isTrue);
    expect(r.ownsDragAt(const Offset(200, 30), movingRight: false), isTrue);
    // the 24 px strip is never owned
    expect(r.ownsDragAt(const Offset(10, 30), movingRight: true), isFalse);
    // a rail at offset 0 lets a rightward drag through to the back swipe, but keeps a leftward one
    expect(r.ownsDragAt(const Offset(200, 150), movingRight: true), isFalse);
    expect(r.ownsDragAt(const Offset(200, 150), movingRight: false), isTrue);
    atStart.value = false;
    expect(r.ownsDragAt(const Offset(200, 150), movingRight: true), isTrue);
    // outside every owner
    expect(r.ownsDragAt(const Offset(200, 500), movingRight: true), isFalse);
    r.unregister('row');
    expect(r.ownsDragAt(const Offset(200, 30), movingRight: false), isFalse);
    expect(r.length, 1);
  });

  testWidgets('an owner in a muted subtree (an offstage tab, a covered route) owns nothing', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    Widget app(bool on) => UncontrolledProviderScope(
          container: c,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TickerMode(enabled: on, child: const GlassDragOwner(kind: GlassDragOwnerKind.row, child: SizedBox.expand())),
          ),
        );
    await t.pumpWidget(app(true));
    final r = c.read(glassDragOwnerRegistryProvider);
    expect(r.ownsDragAt(const Offset(200, 300), movingRight: false), isTrue);
    await t.pumpWidget(app(false));
    expect(r.ownsDragAt(const Offset(200, 300), movingRight: false), isFalse);
  });
}
