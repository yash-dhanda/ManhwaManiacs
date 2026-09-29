import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';

/// The phone portrait lock of glass 8.0.1, installed at the Glass root: on phones (shorter side under
/// 600) the app is portrait only; tablets rotate freely. Leaving Glass (a skin switch through
/// `AppRestart`) restores rotation.
class GlassOrientationScope extends StatefulWidget {
  const GlassOrientationScope({super.key, required this.child});
  final Widget child;

  @override
  State<GlassOrientationScope> createState() => _GlassOrientationScopeState();
}

class _GlassOrientationScopeState extends State<GlassOrientationScope> {
  bool? _phone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    if (phone == _phone) return;
    _phone = phone;
    SystemChrome.setPreferredOrientations(phone ? const [DeviceOrientation.portraitUp] : const <DeviceOrientation>[]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// For the readers' routes (mobile/35, mobile/36): the reader may rotate on phones too.
abstract final class GlassOrientation {
  static bool get _phone {
    final views = ui.PlatformDispatcher.instance.views;
    return views.isNotEmpty && GlassFrame.isPhoneView(views.first);
  }

  static Future<void> widenForReader() => SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);

  /// Back to portrait on a phone (tablets were never locked).
  static Future<void> restoreAfterReader() =>
      SystemChrome.setPreferredOrientations(_phone ? const [DeviceOrientation.portraitUp] : const <DeviceOrientation>[]);
}
