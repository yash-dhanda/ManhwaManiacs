import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A one-shot Ask draft: Search's Ask card and `?scope=ask` write it, For you reads it once and clears it.
final pendingAskProvider = NotifierProvider<PendingAsk, String?>(PendingAsk.new, name: 'pendingAsk');

class PendingAsk extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String draft) => state = draft;

  /// The draft, cleared by reading it.
  String? take() {
    final d = state;
    state = null;
    return d;
  }
}
