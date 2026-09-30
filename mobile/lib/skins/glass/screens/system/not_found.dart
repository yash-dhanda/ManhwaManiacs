import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

const String kNotFoundTitle = 'Nothing here';
const String kNotFoundBody = "This page doesn't exist. It may have been renamed, or the series it pointed to may have left your library.";

/// The router's not-found screen (glass 8.28): the object lens with a question mark, "Back home" and "Open library"; `Enter`
/// activates the primary action; on tablet and desktop frames a hint names the palette key.
class GlassNotFound extends ConsumerWidget {
  const GlassNotFound({super.key, this.location});
  final String? location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(skinRouterProvider);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
      child: Actions(
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => router.go('/'))},
        child: Focus(
          autofocus: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassObjectLens(
                  situation: LensSituation.notFound,
                  title: kNotFoundTitle,
                  description: kNotFoundBody,
                  primary: LensAction('Back home', () => router.go('/')),
                  secondary: LensAction('Open library', () => router.go('/library')),
                ),
                if (wide) Padding(padding: const EdgeInsets.only(top: 16), child: GlassText('Press ${ios ? '⌘K' : 'Ctrl K'} to search everything', role: gt.typeFootnote, color: gt.colorLabel2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
