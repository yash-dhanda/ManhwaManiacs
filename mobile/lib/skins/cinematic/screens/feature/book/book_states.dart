import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// The Book page's whole-page notices (E7). Headlines type at 50 ms per glyph.
class BookOfflineNotice extends StatelessWidget {
  const BookOfflineNotice({super.key, required this.sourceId});
  final String sourceId;

  @override
  Widget build(BuildContext context) => FeatureNotice(
        kicker: 'OFFLINE',
        headline: 'This book needs a connection to load.',
        quietLabel: 'Back to the source',
        onQuiet: () => context.canPop() ? context.pop() : context.go('/sources/$sourceId'),
      );
}

class BookErrorNotice extends StatelessWidget {
  const BookErrorNotice({super.key, required this.sourceId, this.onRetry});
  final String sourceId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => FeatureNotice(
        kicker: 'CORRECTION',
        headline: "Couldn't load this book.",
        primaryLabel: onRetry == null ? null : 'Try again',
        onPrimary: onRetry,
        quietLabel: 'Back to the source',
        onQuiet: () => context.canPop() ? context.pop() : context.go('/sources/$sourceId'),
      );
}

/// The Book's loading galley: title bars and greeked lines.
class BookGalley extends StatelessWidget {
  const BookGalley({super.key});

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
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 48),
            bar(120, 12),
            const SizedBox(height: 12),
            bar(240, 40),
            const SizedBox(height: 8),
            bar(160, 22),
            const SizedBox(height: 24),
            for (var i = 0; i < 6; i++) ...[bar(double.infinity, 12), const SizedBox(height: 10)],
          ],
        ),
      ),
    );
  }
}

enum ContentsNoticeKind { loading, offline, error, unavailable, empty }

/// The states of the contents list under the section rule.
class ContentsNotice extends StatelessWidget {
  const ContentsNotice({super.key, required this.kind, this.onRetry});
  final ContentsNoticeKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    switch (kind) {
      case ContentsNoticeKind.loading:
        return Column(
          key: const Key('contents-loading'),
          children: [
            for (var i = 0; i < 10; i++)
              Container(
                height: 48,
                alignment: Alignment.centerLeft,
                child: Container(height: 14, width: 200 + (i % 3) * 40.0, color: t.colorGalley),
              ),
          ],
        );
      case ContentsNoticeKind.offline:
        return const _Line('The contents need a connection to load.');
      case ContentsNoticeKind.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Line("Couldn't load the contents"),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        );
      case ContentsNoticeKind.unavailable:
        return const _Line("Contents didn't come through.");
      case ContentsNoticeKind.empty:
        return const _Line('No chapters yet.');
    }
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(24), child: Text(text));
}
