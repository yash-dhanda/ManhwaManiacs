import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_oxford_rule.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart' show splashDoneProvider;
import 'package:manhwamaniacs/skins/cinematic/splash/cine_wordmark.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Bare frame of Setup, Login and Register (cinematic 8.0.9): black, no running head, the
/// content in the full 4-column grid below 600 px and in columns 2-7 of the 8-column grid from
/// 600 px, the [footer] pinned to the bottom of the scroll viewport (above the keyboard).
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.children, this.footer, this.top});

  final List<Widget> children;
  final Widget? footer;

  /// A leading widget above the column (Register's back arrow).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final grid = CineGrid.of(context);
    final tablet = grid.width >= 600;
    final maxW = tablet ? grid.span(6) : double.infinity;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tablet ? 0 : grid.left),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (top != null) top!,
                        ...children,
                        const Spacer(),
                        if (footer != null) Padding(padding: EdgeInsets.only(top: context.cine.space6, bottom: context.cine.space4), child: footer),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The masthead block both Bare screens share: the one-line lockup at 28 px over the Oxford rule,
/// and (Login) the date line. The rule sits at the same y on Setup and Login, so Setup's
/// underline lands where Login's rule will be. [ruleKey] marks the rule for that move.
/// [extend] (0..1) widens the rule from the lockup's width to the whole column (Login's sign-in).
class AuthMasthead extends StatelessWidget {
  const AuthMasthead({super.key, this.dateLine = false, this.ruleKey, this.extend = 0, this.hideRule = false});

  final bool dateLine;
  final GlobalKey? ruleKey;
  final double extend;

  /// Setup hides its own rule while the moving one is in flight.
  final bool hideRule;

  /// The block is 20 % of the screen height, at least 96 px.
  static double heightFor(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final v = h * 0.2;
    return v < 96 ? 96 : v;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    const mark = CineWordmark.line(withRule: false);
    final lockW = mark.lineWidth(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: heightFor(context)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = lockW + (box.maxWidth - lockW) * extend.clamp(0.0, 1.0);
          return Padding(
            padding: EdgeInsets.only(top: c.space6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              mark,
              SizedBox(height: c.space2),
              Opacity(
                opacity: hideRule ? 0 : 1,
                child: SizedBox(key: ruleKey, width: w, child: const CineOxfordRule(spotLead: true)),
              ),
              if (dateLine) ...[
                SizedBox(height: c.space3),
                CineRoleText(mastheadDateLine(DateTime.now()), c.typeFolio, color: c.colorInk60),
              ],
            ],),
          );
        },
      ),
    );
  }
}

/// The screen's kicker in `typeKicker` `ink.60`.
class AuthKicker extends StatelessWidget {
  const AuthKicker(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => CineRoleText(text, context.cine.typeKicker, color: context.cine.colorInk60, upper: true);
}

/// The level-1 headline in `typeHeadline`, typed once the splash hand-off has begun (at once when
/// the screen is reached later). Space is reserved before it starts.
class AuthHeadline extends ConsumerWidget {
  const AuthHeadline(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final style = CineText.style(context, c.typeHeadline);
    if (!ref.watch(splashDoneProvider)) {
      return Opacity(opacity: 0, child: ExcludeSemantics(child: Text(text, style: style)));
    }
    return TypedHeadline(text, style: style, cap: c.typeHeadline.cap, level: 1);
  }
}

/// A cover line in `typePull`, revealed by letters (`SetHeading`, `SetTrigger.signal`) once the
/// hand-off has begun. [index] staggers the tablet's three lines 400 ms apart.
class AuthCoverLine extends ConsumerWidget {
  const AuthCoverLine(this.text, {super.key, this.index = 0});
  final String text;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final style = CineText.style(context, c.typePull).copyWith(color: c.colorInk80);
    if (!ref.watch(splashDoneProvider)) {
      return Opacity(opacity: 0, child: ExcludeSemantics(child: Text(text, style: style)));
    }
    return SetHeading(
      text,
      id: 'auth-cover-$index',
      style: style,
      cap: c.typePull.cap,
      level: null,
      trigger: SetTrigger.signal,
      startDelayMs: 120 + 400 * index,
    );
  }
}

/// The error line under a primary button: `typeCaption` `proof`, a live region.
class AuthErrorLine extends StatelessWidget {
  const AuthErrorLine(this.text, {super.key});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final t = text;
    if (t == null) return const SizedBox.shrink();
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space3),
      child: Semantics(liveRegion: true, child: CineRoleText(t, c.typeCaption, color: c.colorProof)),
    );
  }
}

/// The live countdown of a rate-limited attempt: whole seconds, ticking once a second.
class RateCountdown extends ChangeNotifier {
  int _left = 0;
  Timer? _t;

  int get seconds => _left;
  bool get active => _left > 0;

  void start(Duration d) {
    _t?.cancel();
    _left = d.inSeconds < 1 ? 1 : d.inSeconds;
    notifyListeners();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      _left--;
      if (_left <= 0) {
        _left = 0;
        t.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}
