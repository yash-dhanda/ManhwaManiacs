import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// A count on a label (` 201`). The bundled Archivo has no superscript zero, so the
/// count is set as plain figures after a space rather than as tofu.
String superscript(int n) => ' $n';

CineTokens cineOf(BuildContext c) => Theme.of(c).extension<CineTokens>()!;

TextStyle kickerStyle(BuildContext c, {Color? color}) => CineType.style(c, cineOf(c).typeKicker)
    .copyWith(color: color ?? cineOf(c).colorInk60);

/// The typed notice every failure state uses: kicker, headline, deck, actions.
class FeatureNotice extends StatelessWidget {
  const FeatureNotice({
    super.key,
    required this.kicker,
    required this.headline,
    this.deck,
    this.primaryLabel,
    this.onPrimary,
    this.quietLabel,
    this.onQuiet,
    this.correction = false,
  });

  /// A failure (`CORRECTION`): the kicker is set in `proof`.
  final bool correction;

  final String kicker;
  final String headline;
  final String? deck;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? quietLabel;
  final VoidCallback? onQuiet;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    return Scaffold(
      backgroundColor: t.colorPaper0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kicker, style: kickerStyle(context, color: correction ? t.colorProof : null)),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                label: headline,
                excludeSemantics: true,
                child: TypedHeadline(
                  headline,
                  style: TextStyle(fontSize: 32, height: 36 / 32, color: t.colorInk100),
                ),
              ),
              if (deck != null) ...[
                const SizedBox(height: 8),
                Text(deck!, style: TextStyle(fontSize: 18, color: t.colorInk60)),
              ],
              const SizedBox(height: 24),
              if (primaryLabel != null)
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: onPrimary,
                  child: Text(primaryLabel!),
                ),
              if (quietLabel != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: onQuiet,
                  child: Text(quietLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §8.0.10: the same wording for a removed, unknown or gate-hidden series;
/// it never reveals 18+.
class FeatureNotAvailable extends StatelessWidget {
  const FeatureNotAvailable({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context) => FeatureNotice(
        kicker: 'NOT IN THIS ISSUE',
        headline: "This series isn't available here any more.",
        deck: 'It may have been removed from its source.',
        primaryLabel: 'Back to Tonight',
        onPrimary: () => context.go(ScreenId.tonight.path),
        quietLabel: 'Search for it',
        onQuiet: () => context.push(
          title == null
              ? ScreenId.discover.path
              : '${ScreenId.discover.path}?q=${Uri.encodeQueryComponent(title!)}',
        ),
      );
}

class FeatureGalley extends StatelessWidget {
  const FeatureGalley({super.key});

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    Widget bar(double w, double h) => Container(width: w, height: h, color: t.colorGalley);
    return Scaffold(
      backgroundColor: t.colorPaper0,
      body: Semantics(
        label: 'Loading',
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AspectRatio(aspectRatio: 4 / 5, child: ColoredBox(color: t.colorGalley)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(220, 36),
                  const SizedBox(height: 12),
                  bar(160, 16),
                  const SizedBox(height: 24),
                  for (var i = 0; i < 8; i++) ...[
                    bar(double.infinity, 40),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A notice headline that types at 50 ms per character (`type`); reduced
/// motion shows it whole.
class TypedHeadline extends StatefulWidget {
  const TypedHeadline(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<TypedHeadline> createState() => _TypedHeadlineState();
}

class _TypedHeadlineState extends State<TypedHeadline> {
  int _n = 0;
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (CineMotion.reduced(context)) {
      _n = widget.text.length;
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) return;
      setState(() => _n++);
      if (_n >= widget.text.length) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_n >= widget.text.length) return Text(widget.text, style: widget.style);
    return Stack(
      children: [
        // The full text lays the line breaks out; only the typed part shows.
        Opacity(opacity: 0, child: Text(widget.text, style: widget.style)),
        Text(widget.text.substring(0, _n.clamp(0, widget.text.length)), style: widget.style),
      ],
    );
  }
}

/// `OFFLINE EDITION` / `SAVED COPY · 3 H`: a small badge beside the kicker.
class FeatureBadge extends StatelessWidget {
  const FeatureBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: t.colorRule2)),
      child: Text(label, style: kickerStyle(context, color: t.colorInk80)),
    );
  }
}
