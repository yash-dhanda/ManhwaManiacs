import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/cruise_engage.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';

class FakeEngine extends ReaderEngine {
  final calls = <String>[];
  double? px;
  Duration? ramp;
  int engage = 0;

  @override
  void startAutoScroll(double pxPerSecond, {Duration ramp = Duration.zero}) {
    px = pxPerSecond;
    this.ramp = ramp;
    calls.add('start');
    value = value.copyWith(autoScrolling: true);
  }

  @override
  void setAutoScrollPxPerSecond(double pxPerSecond) {
    px = pxPerSecond;
    calls.add('set');
  }

  @override
  void toggleAutoScroll() {
    calls.add('toggle');
    value = value.copyWith(autoScrolling: !value.autoScrolling);
  }

  @override
  void engageFromVelocity() => engage++;
}

void main() {
  late FakeEngine engine;
  late ProviderContainer c;
  late List<double> saved;
  var reduced = false;

  CruiseController attach({double speed = 1.0}) {
    engine = FakeEngine();
    saved = [];
    reduced = false;
    c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(cruiseControllerProvider, (_, __) {});
    final n = c.read(cruiseControllerProvider.notifier);
    n.attach(EngineCruiseSource(engine), speed: speed, persist: saved.add, reduced: () => reduced);
    return n;
  }

  test('a tap starts at 60 px/s x m with the 400 ms ramp, and stops', () {
    final n = attach(speed: 1.5);
    n.toggle();
    expect(engine.px, 90);
    expect(engine.ramp, const Duration(milliseconds: 400));
    expect(c.read(cruiseControllerProvider).running, isTrue);
    n.toggle();
    expect(c.read(cruiseControllerProvider).running, isFalse);
  });

  test('Reduce Motion starts with no ramp', () {
    final n = attach();
    reduced = true;
    n.start();
    expect(engine.ramp, Duration.zero);
  });

  test('dragging previews live and saves once on release; steps are 0.25', () {
    final n = attach();
    n.start();
    n.preview(1.5);
    expect(engine.px, 90);
    expect(saved, isEmpty);
    n.commit(1.5);
    expect(saved, [1.5]);
    n.step(0.25);
    expect(c.read(cruiseControllerProvider).speed, 1.75);
    n.step(-0.25);
    expect(c.read(cruiseControllerProvider).speed, 1.5);
  });

  test('stepping onto the 1.0 magnet lands exactly on 1.0', () {
    final n = attach(speed: 1.05);
    n.step(0.0);
    expect(c.read(cruiseControllerProvider).speed, 1.0);
  });

  test('a flick that engages cruise saves the coasting speed', () async {
    attach();
    engine.emitCruiseEngaged(const CruiseEngaged(2.5, 150));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(cruiseControllerProvider).speed, 2.5);
    expect(saved, [2.5]);
  });

  test('Reduce Motion never engages from a flick', () async {
    attach();
    reduced = true;
    engine.emitCruiseEngaged(const CruiseEngaged(2.5, 150));
    await Future<void>.delayed(Duration.zero);
    expect(saved, isEmpty);
  });

  test('disposing the container stops the engine', () {
    final n = attach();
    n.start();
    c.dispose();
    expect(engine.value.autoScrolling, isFalse);
  });
}
