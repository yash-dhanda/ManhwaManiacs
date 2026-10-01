import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The global rect of the card the story opened from (You, Statistics, the December Home card): the close shrinks the story back into it
/// on `zoom`. Every entry point writes it before pushing `Routes.annual(year)`; with no rect the story fades out and goes to Statistics.
final wrappedOriginProvider = StateProvider<Rect?>((ref) => null, name: 'wrappedOrigin');
