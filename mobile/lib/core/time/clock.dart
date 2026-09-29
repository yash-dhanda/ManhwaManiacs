import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wall clock. Every time-dependent rule reads it through here so tests pin it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now, name: 'clock');
