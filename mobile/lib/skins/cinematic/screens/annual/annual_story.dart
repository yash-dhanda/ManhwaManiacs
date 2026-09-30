import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cue.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_controls.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_player.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_segments.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/colophon_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/cover_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/press_run_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/text_pages.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Annual's story (cinematic 9.2.4): eleven pages in a pager, segments, a
/// close button; a full-screen takeover on phones, a centred 9:16 column at full
/// height on tablets and landscape phones.
class AnnualStory extends ConsumerStatefulWidget {
  const AnnualStory({super.key, required this.annual, required this.profileName, required this.onClose, required this.onReadNumbers});

  final Annual annual;
  final String profileName;
  final VoidCallback onClose;
  final VoidCallback onReadNumbers;

  @override
  ConsumerState<AnnualStory> createState() => _AnnualStoryState();
}

class _AnnualStoryState extends ConsumerState<AnnualStory> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final List<AnnualPageSpec> _pages = annualPages(widget.annual);
  final PageController _pager = PageController();
  late final AnnualPlayer _player;
  late final AnimationController _spring = AnimationController.unbounded(vsync: this);
  double _drag = 0;
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AnnualPlayer(vsync: this, pages: _pages, onAdvance: (i) => _goTo(i, user: false));
    _spring.addListener(() => setState(() => _drag = _spring.value));
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _player.autoAdvance = !(cineReduced(context) || MediaQuery.accessibleNavigationOf(context));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _player.inactive = state != AppLifecycleState.resumed;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    _pager.dispose();
    _spring.dispose();
    super.dispose();
  }

  void _announce(int i) {
    SemanticsService.announce('Page ${i + 1} of ${_pages.length}: ${_pages[i].title}', TextDirection.ltr);
  }

  Future<void> _goTo(int i, {required bool user}) async {
    if (i < 0 || i >= _pages.length || i == _player.index || !_pager.hasClients) return;
    if (user) cinematicCue(ref, HapticEvent.annualPage, SoundEvent.annualPage);
    _programmatic = true;
    _player.showPage(i);
    _announce(i);
    if (cineReduced(context)) {
      _pager.jumpToPage(i);
    } else {
      await _pager.animateToPage(i, duration: CineDur.pageturn, curve: CineCurves.turn);
    }
    _programmatic = false;
  }

  void _next() => _goTo(_player.index + 1, user: true);
  void _previous() => _goTo(_player.index - 1, user: true);

  void _dragEnd(double v) {
    if (_drag > 120 || v > 800) {
      widget.onClose();
      return;
    }
    _spring.value = _drag;
    _spring.animateWith(SpringSimulation(CineSprings.release.description, _drag, 0, v / 3));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(builder: (context, box) {
      final columnMode = box.maxWidth >= 600 || box.maxHeight < 500;
      final colH = box.maxHeight;
      final colW = columnMode ? colH * 9 / 16 : box.maxWidth;
      final story = _story(context, Size(colW, colH), media);
      return ColoredBox(
        color: const Color(0xFF000000),
        child: Center(child: SizedBox(width: colW, height: colH, child: MediaQuery(data: media.copyWith(size: Size(colW, colH)), child: story))),
      );
    },);
  }

  Widget _story(BuildContext context, Size size, MediaQueryData media) {
    final accessible = media.accessibleNavigation;
    final pad = media.viewPadding;
    final hit = minHit(context);
    final env = AnnualEnv(
      annual: widget.annual,
      profileName: widget.profileName,
      player: _player,
      goTo: (i) => _goTo(i, user: true),
      close: widget.onClose,
      readNumbers: widget.onReadNumbers,
      now: ref.read(numbersNowProvider)(),
    );
    Widget pageFor(int i) => switch (_pages[i].kind) {
          AnnualPageKind.cover => AnnualCoverPage(env: env),
          AnnualPageKind.time => AnnualTimePage(env: env),
          AnnualPageKind.chapters => AnnualChaptersPage(env: env),
          AnnualPageKind.no1 => AnnualNumberOnePage(env: env),
          AnnualPageKind.genres => AnnualGenresPage(env: env),
          AnnualPageKind.clock => AnnualClockPage(env: env),
          AnnualPageKind.streak => AnnualStreakPage(env: env),
          AnnualPageKind.sources => AnnualSourcesPage(env: env),
          AnnualPageKind.circle => AnnualCirclePage(env: env),
          AnnualPageKind.colophon => AnnualColophonPage(env: env, index: i),
          AnnualPageKind.pressRun => AnnualPressRunPage(env: env),
        };
    return KeyMap(
      actions: {
        LogicalKeyboardKey.arrowRight: _next,
        LogicalKeyboardKey.arrowLeft: _previous,
        LogicalKeyboardKey.space: _player.togglePause,
        LogicalKeyboardKey.escape: widget.onClose,
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(TapGestureRecognizer.new, (r) {
            r.onTapUp = (d) {
              final p = d.localPosition;
              if (p.dy < pad.top + 64 || p.dy > size.height - pad.bottom - 48) return;
              if (p.dx > size.width * 2 / 3) {
                _next();
              } else if (p.dx < size.width / 3) {
                _previous();
              }
            };
          }),
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(() => LongPressGestureRecognizer(duration: const Duration(milliseconds: 450)), (r) {
            r.onLongPressStart = (_) => _player.held = true;
            r.onLongPressEnd = (_) => _player.held = false;
            r.onLongPressCancel = () => _player.held = false;
          }),
          VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(VerticalDragGestureRecognizer.new, (r) {
            r.onStart = (_) => _spring.stop();
            r.onUpdate = (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0.0, 2000.0));
            r.onEnd = (d) => _dragEnd(d.primaryVelocity ?? 0);
          }),
        },
        child: Transform.translate(
          offset: Offset(0, _drag),
          child: Stack(fit: StackFit.expand, children: [
            ListenableBuilder(
              listenable: _player,
              builder: (context, _) => Semantics(
                container: true,
                label: 'The Annual ${widget.annual.year}, page ${_player.index + 1} of ${_pages.length}',
                customSemanticsActions: {
                  const CustomSemanticsAction(label: 'Next page'): _next,
                  const CustomSemanticsAction(label: 'Previous page'): _previous,
                  const CustomSemanticsAction(label: 'Pause'): _player.togglePause,
                },
                child: PageView.builder(
                  controller: _pager,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    if (_programmatic) return;
                    // A swipe: the player follows the finger.
                    cinematicCue(ref, HapticEvent.annualPage, SoundEvent.annualPage);
                    _player.showPage(i);
                    _announce(i);
                  },
                  itemBuilder: (context, i) => pageFor(i),
                ),
              ),
            ),
            Positioned(left: 16, right: 16, top: pad.top + 8, child: AnnualSegments(player: _player)),
            Positioned(right: 16 - (hit - 40) / 2, top: pad.top + 8 + 2 + 8 - (hit - 40) / 2, child: OnArtButton(role: CineIconRole.close, label: 'Close', onPressed: widget.onClose)),
            if (accessible)
              Positioned(
                left: 16,
                right: 16,
                bottom: pad.bottom + 12,
                child: ListenableBuilder(listenable: _player, builder: (context, _) => ScreenReaderControls(onPrevious: _previous, onNext: _next, onPause: _player.togglePause, paused: _player.userPaused)),
              ),
          ],),
        ),
      ),
    );
  }
}
