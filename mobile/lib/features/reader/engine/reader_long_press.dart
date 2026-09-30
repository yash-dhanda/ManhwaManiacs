import 'package:flutter/gestures.dart';

/// The reader's page long press: 450 ms hold; a drag past 8 px loses the arena to scrolling.
class ReaderLongPressRecognizer extends LongPressGestureRecognizer {
  ReaderLongPressRecognizer() : super(duration: const Duration(milliseconds: 450));

  @override
  double? get preAcceptSlopTolerance => 8;
}
