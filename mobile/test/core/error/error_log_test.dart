import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/error_log.dart';

/// Listens to the log and rebuilds, the way a Diagnostics screen does.
class _Listening extends StatefulWidget {
  const _Listening(this.log, this.onBuildRecord);
  final ErrorLog log;
  final void Function()? onBuildRecord;

  @override
  State<_Listening> createState() => _ListeningState();
}

class _ListeningState extends State<_Listening> {
  @override
  void initState() {
    super.initState();
    widget.log.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.log.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuildRecord?.call();
    return Text('${widget.log.entries.length}', textDirection: TextDirection.ltr);
  }
}

void main() {
  testWidgets('a record made while the tree is building does not throw, and listeners hear of it afterwards', (t) async {
    final log = ErrorLog();
    var recorded = false;
    await t.pumpWidget(_Listening(log, () {
      if (!recorded) {
        recorded = true;
        log.record('test', StateError('during build'), StackTrace.current);
      }
    }),);
    expect(t.takeException(), isNull);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('1'), findsOneWidget);
    log.record('test', StateError('later'), null);
    await t.pump();
    await t.pump();
    expect(find.text('2'), findsOneWidget, reason: 'listeners are told afterwards');
  });

  test('several records make one notification', () async {
    final log = ErrorLog();
    var notified = 0;
    log.addListener(() => notified++);
    log.record('a', 'x', null);
    log.record('b', 'y', null);
    log.record('c', 'z', null);
    expect(notified, 0);
    await Future<void>.delayed(Duration.zero);
    expect(notified, 1);
    expect(log.entries, hasLength(3));
  });
}
