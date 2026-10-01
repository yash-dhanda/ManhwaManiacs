import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The signed-in user, or null.
AuthUser? glassUser(WidgetRef ref) {
  final a = ref.watch(authControllerProvider);
  return a is AuthAuthenticated ? a.user : null;
}

bool glassIsAdmin(WidgetRef ref) => glassUser(ref)?.isAdmin ?? false;

/// Builds [child] for admins; anyone else (a direct visit) sees the object lens `shield` "Administrators only" with "Back"
/// (glass 8.25.6, 8.0.10 `forbidden`).
class GlassAdminGate extends ConsumerWidget {
  const GlassAdminGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (glassIsAdmin(ref)) return child;
    return GlassObjectLens(
      situation: LensSituation.adminOnly,
      title: 'Administrators only',
      placement: GlassLensPlacement.inline,
      primary: LensAction('Back', () {
        final r = GoRouter.of(context);
        r.canPop() ? r.pop() : r.go('/settings');
      }),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// "12 min", "3 h", "2 d" for a span, to the nearest minute.
String glassSpan(Duration d) {
  final m = (d.inSeconds + 30) ~/ 60;
  if (m < 60) return '$m min';
  if (m < 48 * 60) return '${m ~/ 60} h';
  return '${m ~/ (24 * 60)} d';
}

/// "12 min ago", "just now".
String glassAgo(DateTime at, DateTime now) {
  final d = now.difference(at);
  return d.inSeconds < 30 ? 'just now' : '${glassSpan(d)} ago';
}

/// "in 18 min", "now".
String glassIn(DateTime at, DateTime now) {
  final d = at.difference(now);
  return d.inSeconds < 30 ? 'now' : 'in ${glassSpan(d)}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "12 Sep".
String glassDay(DateTime t) {
  final l = t.toLocal();
  return '${l.day} ${_months[l.month - 1]}';
}

/// "03:10".
String glassClock(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// "Every 30 min", "Every 2 h".
String glassInterval(int minutes) => minutes >= 60 && minutes % 60 == 0 ? '${minutes ~/ 60} h' : '$minutes min';

/// The inline error block of a server-backed section (glass 8.25): the line and a plain "Try again".
class GlassInlineError extends StatelessWidget {
  const GlassInlineError({super.key, this.message = "Couldn't load this", required this.onRetry, this.retryLabel = 'Try again', this.height});
  final String message, retryLabel;
  final VoidCallback onRetry;
  final double? height;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: height ?? 0),
        child: Padding(
          padding: GlassFrame.gutter(context, top: 16, bottom: 16, inner: 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(liveRegion: true, child: GlassText(message, role: gt.typeCallout, color: gt.colorLabel2)),
            const SizedBox(height: 8),
            GlassButton(label: retryLabel, variant: GlassButtonVariant.plain, size: GlassButtonSize.small, hang: true, onPressed: onRetry),
          ],),
        ),
      );
}

/// Exposes the enclosing `GlassSwipeRow`'s actions as VoiceOver and TalkBack custom actions on a row that is not a `GlassRowShell`.
class GlassSwipeActionsSemantics extends StatelessWidget {
  const GlassSwipeActionsSemantics({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(customSemanticsActions: GlassSwipeSemantics.of(context), child: child);
}

/// [n] row skeletons, 52 px each.
class GlassRowSkeletons extends StatelessWidget {
  const GlassRowSkeletons(this.n, {super.key, this.label = 'Loading'});
  final int n;
  final String label;
  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        label: label,
        child: Padding(
          padding: GlassFrame.gutter(context, top: 16, bottom: 16),
          child: Column(children: [
            for (var i = 0; i < n; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 52, index: i)),
          ],),
        ),
      );
}
