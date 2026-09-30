import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// A short stable hash of an error's type and message: the "Reference" the owner can quote.
String errorReference(Object error) {
  var h = 0x811C9DC5;
  for (final b in utf8.encode('${error.runtimeType}:$error')) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// Whether [error] reads as the server not answering rather than a render bug.
bool isNetworkFailure(Object error) => error.toString().contains('NetworkError') || error.toString().contains('TimeoutError');

/// The route error screen (glass 8.28), what `ErrorWidget.builder` builds in release builds: "Something broke" with a reference and
/// "Try again" / "Back home"; the network variant says the server did not answer. The lens drops in once with the `error` haptic.
class GlassRouteError extends ConsumerStatefulWidget {
  const GlassRouteError({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  ConsumerState<GlassRouteError> createState() => _GlassRouteErrorState();
}

class _GlassRouteErrorState extends ConsumerState<GlassRouteError> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(glassHapticsProvider).fire(HapticEvent.error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = isNetworkFailure(widget.error);
    final router = ref.read(skinRouterProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassObjectLens(
            situation: net ? LensSituation.serverUnreachable : LensSituation.loadError,
            tone: GlassLensTone.error,
            title: net ? "Can't reach the server" : 'Something broke',
            description: net
                ? "The server didn't answer. It may be starting up, or the connection dropped. Your library is untouched."
                : 'This page failed while rendering. Nothing was lost; trying again usually works.',
            primary: LensAction('Try again', widget.onRetry ?? router.refresh),
            secondary: LensAction('Back home', () => router.go('/')),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: gt.colorFill3, borderRadius: BorderRadius.circular(8)),
            child: GlassText('Reference ${errorReference(widget.error)}', role: gt.typeMono, color: gt.colorLabel2),
          ),
        ],
      ),
    );
  }
}
