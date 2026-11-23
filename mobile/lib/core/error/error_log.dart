import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One error the global hooks saw but did not raise a notice for.
class LoggedError {
  const LoggedError({required this.time, required this.source, required this.type, required this.message, required this.stackTop});

  final DateTime time;

  /// Where it came from: a Flutter library name, or `async` for an uncaught future error.
  final String source;

  /// The exception's runtime type: the part that says what actually went wrong.
  final String type;
  final String message;

  /// The first lines of the stack.
  final String stackTop;
}

/// A bounded, in-memory record of the errors that no longer take over the screen, so a real failure
/// that the notice policy keeps quiet can still be read on the Diagnostics screen. The hooks are
/// installed outside the provider tree, so the record is a process-wide instance the provider hands out.
class ErrorLog extends ChangeNotifier {
  ErrorLog({this.capacity = 30, this.stackLines = 6});

  final int capacity;
  final int stackLines;
  final List<LoggedError> _entries = [];

  /// Newest first.
  List<LoggedError> get entries => List.unmodifiable(_entries);

  void record(String source, Object error, StackTrace? stack) {
    final lines = (stack?.toString() ?? '').split('\n').where((l) => l.trim().isNotEmpty).take(stackLines).join('\n');
    _entries.insert(
      0,
      LoggedError(time: DateTime.now(), source: source, type: error.runtimeType.toString(), message: '$error', stackTop: lines),
    );
    if (_entries.length > capacity) _entries.removeRange(capacity, _entries.length);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

/// The record the Cinematic root's error hooks write to.
final ErrorLog appErrorLog = ErrorLog();

final errorLogProvider = Provider<ErrorLog>((ref) => appErrorLog);
