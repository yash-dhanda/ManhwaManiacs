import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/front_page.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_mood_grade.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_states.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Tonight, the Cinematic landing screen at `/` (cinematic 8.8): the cover story with its typed
/// headline and the trailer scrub, Also in this issue, the numbered sections, and every loading,
/// empty, offline, error and stale state. Reads the skin-neutral [homeFeedProvider].
class TonightScreen extends ConsumerStatefulWidget {
  const TonightScreen({super.key});

  @override
  ConsumerState<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends ConsumerState<TonightScreen> {
  final TonightCommands _commands = TonightCommands();
  final FocusNode _headline = FocusNode(debugLabel: 'tonight-headline');

  /// Decided once, when the first feed lands: does the Front page moment play?
  bool? _animate;
  bool _sawGalley = false;

  @override
  void dispose() {
    _headline.dispose();
    super.dispose();
  }

  FrontVariant _variant(HomeFeed f) => f.streak.atRisk ? FrontVariant.atRisk : FrontVariant.normal;

  bool _decide(HomeFeedView v) {
    final feed = v.feed!;
    if (_animate == null) {
      // Focus on arrival: the level-1 headline takes focus once it exists (the feed can land after
      // the route settled), so screen readers announce the page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _headline.context != null) _headline.requestFocus();
      });
    }
    return _animate ??= !v.offline && shouldPlayFrontPage(ref.read(frontPageStoreProvider).read(), ref.read(clockProvider)(), _variant(feed));
  }

  void _typed(HomeFeed f) => ref.read(frontPageStoreProvider).mark(ref.read(clockProvider)(), _variant(f));


  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeFeedProvider);
    final mood = ref.watch(_moodProvider);
    final Widget body;
    final v = async.valueOrNull;
    if (v == null && async.isLoading) {
      _sawGalley = true;
      body = const TonightGalley(key: ValueKey('galley'));
    } else if (v == null || v.state == HomeFeedState.unavailable || v.feed == null) {
      body = TonightErrorNotice(
        key: const ValueKey('error'),
        retryAfter: v?.retryAfter,
        onRetry: () => ref.invalidate(homeFeedProvider),
        onDownloads: () => goSection(context, 3),
      );
    } else {
      final feed = v.feed!;
      body = TonightFeed(
        key: const ValueKey('feed'),
        view: v,
        commands: _commands,
        headlineFocus: _headline,
        animateHeadline: _decide(v),
        onTyped: () => _typed(feed),
      );
    }
    // Data that arrives after a skeleton dissolves in over 160 ms instead of running Set.
    final switched = AnimatedSwitcher(
      duration: _sawGalley && !CineMotion.reduced(context) ? CineDur.beat : Duration.zero,
      child: body,
    );
    return CineScaffold(
      runningTitle: 'Tonight',
      customRunningHead: true,
      firstRunNote: false,
      mastheadFocusNode: _headline,
      body: CineMoodGrade(mood: mood, child: TonightShortcuts(commands: _commands, child: switched)),
    );
  }
}

/// The active profile's mood as the wire value `cineMoodColor` reads.
final _moodProvider = Provider<String?>((ref) => ref.watch(activeProfileProvider.select((p) => p?.mood.wire)));
