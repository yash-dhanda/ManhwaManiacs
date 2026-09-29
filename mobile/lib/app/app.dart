import 'package:manhwamaniacs/app/skin_app.dart';

export 'package:manhwamaniacs/app/skin_app.dart';

/// Kept so every test that pumps `const ManhwaManiacsApp()` still compiles; it
/// runs the legacy skin unless `skinIdProvider` is overridden.
typedef ManhwaManiacsApp = SkinApp;
