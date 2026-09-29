import 'dart:async';

import 'package:manhwamaniacs/core/error/app_error.dart';

final StreamController<AppError> _failures = StreamController<AppError>.broadcast(sync: true);

/// Every `NetworkError` and `TimeoutError` the error interceptor maps. The offline edition
/// (mobile/06) listens; nothing else has to.
Stream<AppError> get networkFailures => _failures.stream;

void reportNetworkFailure(AppError e) {
  if (!_failures.isClosed) _failures.add(e);
}
