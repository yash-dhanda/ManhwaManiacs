import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';

final _counter = StateProvider<int>((_) => 0);

void main() {
  testWidgets('restart re-runs the builder and resets provider state',
      (tester) async {
    var builds = 0;
    late BuildContext deep;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppRestart(builder: () {
          builds++;
          return ProviderScope(
            child: Consumer(builder: (context, ref, _) {
              deep = context;
              return Text('${ref.watch(_counter)}');
            },),
          );
        },),
      ),
    );
    expect(builds, 1);
    ProviderScope.containerOf(deep).read(_counter.notifier).state = 5;
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    AppRestart.of(deep).restart();
    await tester.pump();
    expect(builds, 2);
    expect(find.text('0'), findsOneWidget);
  });
}
