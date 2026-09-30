import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "28 Sep · build 57" (glass 8.29), parts the server left out are dropped.
String whatsNewFolio(ChangelogRelease r) {
  final d = DateTime.tryParse(r.date);
  final date = d != null ? '${d.day} ${_months[d.month - 1]}' : r.date;
  return [if (date.isNotEmpty) date, if (r.build > 0) 'build ${r.build}'].join(' · ');
}

/// The body of the `?sheet=whats-new` sheet: "What's new" / "Recent improvements" and a release card per version (`surface1`, radius
/// 20, padding 16): a version capsule (`iris400` on its 18 % wash), "Latest" on the first, the folio, bullets with `droplet` markers.
class GlassWhatsNewBody extends ConsumerWidget {
  const GlassWhatsNewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releases = ref.watch(appChangelogProvider);
    return releases.when(
      loading: () => const Center(child: GlassSpinner()),
      error: (_, __) => _unavailable(),
      data: (list) => list.isEmpty
          ? _unavailable()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                GlassText('Recent improvements', role: gt.typeCallout, onGlass: true),
                const SizedBox(height: 12),
                for (var i = 0; i < list.length; i++) ...[_Card(release: list[i], latest: i == 0), const SizedBox(height: 12)],
              ],
            ),
    );
  }

  Widget _unavailable() => const Center(child: GlassObjectLens(situation: LensSituation.unavailable, title: 'Release notes are unavailable'));
}

class _Card extends StatelessWidget {
  const _Card({required this.release, required this.latest});
  final ChangelogRelease release;
  final bool latest;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: wash(gt.colorIris400), borderRadius: BorderRadius.circular(100)),
                  child: GlassText(release.version, role: gt.typeFootnote, wght: 600, color: gt.colorIris400),
                ),
                if (latest) ...[const SizedBox(width: 8), GlassText('Latest', role: gt.typeFootnote, wght: 600)],
                const Spacer(),
                GlassText(whatsNewFolio(release), role: gt.typeFootnote, color: gt.colorLabel2),
              ],
            ),
            const SizedBox(height: 12),
            for (final h in release.highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 6, right: 10), child: Container(width: 12, height: 12, decoration: BoxDecoration(color: gt.colorIris400, shape: BoxShape.circle))),
                    Expanded(child: GlassText(h, role: gt.typeCallout)),
                  ],
                ),
              ),
          ],
        ),
      );
}
