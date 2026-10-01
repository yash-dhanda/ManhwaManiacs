import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';

/// The paper of the reader (C2): the page, the contents sheet, the loading skeleton, toasts in the reader and every state paint from
/// it.
class PaperScope extends InheritedWidget {
  const PaperScope({super.key, required this.paper, required this.colors, required super.child});
  final GlassPaper paper;
  final PaperColors colors;

  static PaperScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PaperScope>();

  static PaperColors of(BuildContext context) => maybeOf(context)?.colors ?? paperColors(GlassPaper.voidPaper);

  @override
  bool updateShouldNotify(PaperScope old) => old.paper != paper || old.colors != colors;
}

/// The Glass paper's field (C3): opaque to 20 % of the viewport height, transparent at 30 %.
const double kGlassFieldSolidTo = 0.20, kGlassFieldClearAt = 0.30;

/// The field spec of the Glass paper: the book's cover palette (else the profile mood) at 10 %.
GlassAmbientSpec glassPaperSpec(CoverPalette? palette, Mood mood) =>
    palette == null ? GlassAmbientSpec.mood(mood, opacity: kGlassPaperFieldAlpha) : GlassAmbientSpec.palette(palette, opacity: kGlassPaperFieldAlpha, fallbackMood: mood);

/// The paper painted edge to edge, under the safe areas (B2). On the Glass paper it declares the cover field and paints the field of
/// `mobile/25` (one `CustomPaint`) masked to the top 30 % of the screen.
class PaperFrame extends StatelessWidget {
  const PaperFrame({super.key, required this.paper, required this.colors, this.spec, required this.child});
  final GlassPaper paper;
  final PaperColors colors;
  final GlassAmbientSpec? spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.bg),
        if (paper == GlassPaper.glass)
          Positioned.fill(
            child: ShaderMask(
              key: const ValueKey('glass-paper-field'),
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                stops: [0, kGlassFieldSolidTo, kGlassFieldClearAt],
              ).createShader(r),
              child: const GlassAmbientField(),
            ),
          ),
        child,
      ],
    );
    final s = spec;
    final scoped = PaperScope(paper: paper, colors: colors, child: body);
    return paper == GlassPaper.glass && s != null ? GlassAmbientScope(spec: s, child: scoped) : scoped;
  }
}
