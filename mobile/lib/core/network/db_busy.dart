import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts GETs whose quiet `503 db_busy` retries all failed. The Cinematic toast host listens and
/// shows the "server is busy" subtitle.
final dbBusyExhaustedProvider = StateProvider<int>((ref) => 0, name: 'dbBusyExhausted');
