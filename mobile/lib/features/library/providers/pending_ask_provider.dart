import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A one-shot hand-off of the Ask query from Search to For you (`mobile/41` takes it on arrival).
final pendingAskProvider = NotifierProvider<PendingAskNotifier, String?>(PendingAskNotifier.new);

class PendingAskNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String q) => state = q;

  /// Returns the query and clears it.
  String? take() {
    final v = state;
    state = null;
    return v;
  }
}
