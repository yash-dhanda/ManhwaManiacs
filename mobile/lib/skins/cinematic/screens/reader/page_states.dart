import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What a page box holds inside the strip's reserved box (cinematic 8.14.11): nothing while it
/// loads, the broken-page state when it failed.
Widget cinePageState(BuildContext context, int page, PageStatus kind, String? reason, VoidCallback retry) => switch (kind) {
      PageStatus.placeholder => const SizedBox.expand(),
      PageStatus.broken => BrokenPage(page: page, reason: reason, retry: retry),
    };

/// `PAGE 18 DIDN'T LOAD`, a quiet `Retry` that refetches that image only, the reason as a caption
/// when it is known.
class BrokenPage extends StatelessWidget {
  const BrokenPage({super.key, required this.page, required this.retry, this.reason});

  final int page;
  final String? reason;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: "Page $page didn't load",
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(c.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CineRoleText("PAGE $page DIDN'T LOAD", c.typeKicker, color: c.colorInk60, textAlign: TextAlign.center),
              SizedBox(height: c.space2),
              CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: retry),
              if (reason != null) ...[
                SizedBox(height: c.space2),
                CineRoleText(reason!, c.typeCaption, color: c.colorInk60, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
