import 'dart:async';
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ImageProvider;
import 'package:manhwamaniacs/features/reader/engine/page_analysis.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';
import 'package:manhwamaniacs/features/reader/engine/words.dart';

/// Panels of one page: found (page fractions), being analysed, or none (whole page).
sealed class PanelsState {
  const PanelsState();
}

final class PanelsFound extends PanelsState {
  const PanelsFound(this.fractions);
  final List<PanelRect> fractions;
}

final class PanelsFinding extends PanelsState {
  const PanelsFinding();
}

final class PanelsNone extends PanelsState {
  const PanelsNone();
}

/// One chapter's new samples, posted once on exit.
class AmbientReport {
  const AmbientReport({required this.tints, required this.panels});
  final Map<int, String> tints;
  final Map<int, List<PanelRect>> panels;
  bool get isEmpty => tints.isEmpty && panels.isEmpty;
}

typedef PageImageResolver = ImageProvider? Function(String chapterId, int page);
typedef AnalyseFn = Future<AnalysisResult> Function({
  ImageProvider? tintPage,
  ImageProvider? panelPage,
  required PanelDirection direction,
});

/// The ambient engine duties (cinematic 15.4): page tint sampling through [TintTracker], panel
/// detection one page ahead in the same isolate call, words on screen, words per panel and the
/// exit reports. Skin-neutral; the skin passes the sample interval.
class ReaderAmbient {
  ReaderAmbient({AnalyseFn analyse = _defaultAnalyse}) : _analyse = analyse;

  static Future<AnalysisResult> _defaultAnalyse({ImageProvider? tintPage, ImageProvider? panelPage, required PanelDirection direction}) =>
      analysePage(tintPage: tintPage, panelPage: panelPage, direction: direction);

  final AnalyseFn _analyse;

  /// The chrome's tint source; null while page tint is off or nothing is sampled yet.
  final ValueNotifier<PageTintSource?> pageTint = ValueNotifier(null);

  /// Panels of the chapter on screen, by 1-based page.
  final ValueNotifier<Map<int, PanelsState>> panels = ValueNotifier(const {});

  /// Words inside the viewport while pace by dialogue has dialogue text; null otherwise.
  final ValueNotifier<int?> wordsOnScreen = ValueNotifier(null);

  PageImageResolver? resolver;
  Duration sampleInterval = const Duration(milliseconds: 600);
  bool tintEnabled = true;
  bool panelsWanted = false;
  PanelDirection direction = PanelDirection.ltr;
  int pageCount = 0;

  String _chapter = '';
  final TintTracker _tracker = TintTracker();
  final Map<String, Map<int, String?>> _tints = {}; // chapter -> page -> seed (null = greyscale)
  final Map<String, Map<int, PanelsState>> _panels = {};
  final Map<String, Map<int, String>> _dirtyTints = {};
  final Map<String, Map<int, List<PanelRect>>> _dirtyPanels = {};
  final Set<String> _inFlight = {};
  DateTime? _lastSample;
  Timer? _trailing;
  ({String chapter, int page})? _pending;
  int analysisCalls = 0;

  /// A decode that never comes back (a hung fetch) is a failure: the cover colour, a whole page.
  Duration analysisTimeout = const Duration(seconds: 12);
  DateTime Function() clock = DateTime.now;
  bool _disposed = false;

  /// Seeds a chapter with stored values: the manifest's `pages[].tint` / `pages[].panels` or the
  /// saved copy's. [panels] null = unknown, empty = analysed with none.
  void seed(String chapterId, {Map<int, String> tints = const {}, Map<int, List<PanelRect>?> panels = const {}}) {
    final t = _tints.putIfAbsent(chapterId, () => {});
    tints.forEach((page, hex) => t[page] = hex.toUpperCase());
    final p = _panels.putIfAbsent(chapterId, () => {});
    panels.forEach((page, rects) {
      if (rects == null) return;
      p[page] = rects.isEmpty ? const PanelsNone() : PanelsFound(rects);
    });
    _publishPanels();
  }

  /// The reading line is on [page] of [chapterId]: sample its tint (at most once per interval) and
  /// analyse the next page's panels in the same call.
  void onPage(String chapterId, int page) {
    if (_disposed || chapterId.isEmpty) return;
    if (chapterId != _chapter) {
      _chapter = chapterId;
      _publishPanels();
    }
    final known = _tints[chapterId]?[page];
    if (_tints[chapterId]?.containsKey(page) ?? false) {
      if (tintEnabled) _feed(known);
    }
    final needTint = tintEnabled && !(_tints[chapterId]?.containsKey(page) ?? false);
    final needPanels = panelsWanted && page + 1 <= pageCount && _panels[chapterId]?[page + 1] == null;
    if (!needTint && !needPanels) return;
    _pending = (chapter: chapterId, page: page);
    _sampleSoon();
  }

  void _sampleSoon() {
    final now = clock();
    final last = _lastSample;
    if (last == null || now.difference(last) >= sampleInterval) {
      _run();
    } else {
      _trailing ??= Timer(sampleInterval - now.difference(last), () {
        _trailing = null;
        _run();
      });
    }
  }

  void _run() {
    final p = _pending;
    _pending = null;
    if (p == null || _disposed) return;
    _lastSample = clock();
    unawaited(_analyseAt(p.chapter, p.page));
  }

  Future<void> _analyseAt(String chapter, int page) async {
    final r = resolver;
    if (r == null) return;
    final wantTint = tintEnabled && !(_tints[chapter]?.containsKey(page) ?? false);
    final wantPanels = panelsWanted && page + 1 <= pageCount && _panels[chapter]?[page + 1] == null;
    final key = '$chapter:$page:$wantTint:$wantPanels';
    if (!(wantTint || wantPanels) || !_inFlight.add(key)) return;
    analysisCalls++;
    if (wantPanels) _setPanels(chapter, page + 1, const PanelsFinding());
    try {
      final result = await _guarded(
        _analyse(
          tintPage: wantTint ? r(chapter, page) : null,
          panelPage: wantPanels ? r(chapter, page + 1) : null,
          direction: direction,
        ),
      );
      if (_disposed) return;
      if (wantTint) {
        if (result.tintFailed) {
          if (chapter == _chapter) pageTint.value = PageTintSource.cover;
        } else {
          (_tints[chapter] ??= {})[page] = result.seed;
          if (result.seed != null) (_dirtyTints[chapter] ??= {})[page] = result.seed!;
          if (chapter == _chapter) _feed(result.seed);
        }
      }
      if (wantPanels) {
        if (result.panelsFailed || result.panels == null) {
          _setPanels(chapter, page + 1, const PanelsNone());
        } else {
          _storePanels(chapter, page + 1, result.panels!);
        }
      }
    } catch (_) {
      if (wantPanels) _setPanels(chapter, page + 1, const PanelsNone());
      if (wantTint && chapter == _chapter) pageTint.value = PageTintSource.cover;
    } finally {
      _inFlight.remove(key);
    }
  }

  final Set<Timer> _guards = {};

  /// [f] or a timeout after [analysisTimeout]; the timer is cancelled on completion and on dispose,
  /// so a finished or abandoned analysis leaves nothing pending.
  Future<AnalysisResult> _guarded(Future<AnalysisResult> f) {
    final done = Completer<AnalysisResult>();
    late final Timer t;
    t = Timer(analysisTimeout, () {
      _guards.remove(t);
      if (!done.isCompleted) done.completeError(TimeoutException('page analysis', analysisTimeout));
    });
    _guards.add(t);
    f.then((v) {
      if (!done.isCompleted) done.complete(v);
    }, onError: (Object e, StackTrace st) {
      if (!done.isCompleted) done.completeError(e, st);
    },).whenComplete(() {
      t.cancel();
      _guards.remove(t);
    });
    return done.future;
  }

  void _feed(String? seed) {
    pageTint.value = _tracker.feed(seed);
  }

  void _storePanels(String chapter, int page, List<PanelRect> fractions) {
    _setPanels(chapter, page, fractions.isEmpty ? const PanelsNone() : PanelsFound(fractions));
    (_dirtyPanels[chapter] ??= {})[page] = fractions;
  }

  void _setPanels(String chapter, int page, PanelsState s) {
    (_panels[chapter] ??= {})[page] = s;
    if (chapter == _chapter) _publishPanels();
  }

  void _publishPanels() {
    panels.value = Map.unmodifiable(_panels[_chapter] ?? const <int, PanelsState>{});
  }

  /// Guided view entered on [page]: analyse that page at once when there is no result.
  Future<void> ensurePanels(String chapterId, int page) async {
    if (_panels[chapterId]?[page] != null && _panels[chapterId]![page] is! PanelsFinding) return;
    final r = resolver;
    if (r == null) return;
    _setPanels(chapterId, page, const PanelsFinding());
    analysisCalls++;
    try {
      final result = await _guarded(_analyse(panelPage: r(chapterId, page), direction: direction));
      if (_disposed) return;
      if (result.panelsFailed || result.panels == null) {
        _setPanels(chapterId, page, const PanelsNone());
      } else {
        _storePanels(chapterId, page, result.panels!);
      }
    } catch (_) {
      _setPanels(chapterId, page, const PanelsNone());
    }
  }

  PanelsState? panelsOf(int page) => _panels[_chapter]?[page];

  // ── Words ────────────────────────────────────────────────────────────────

  Map<int, List<OcrWordBox>> _boxes = const {};
  Timer? _wordsTimer;

  bool get hasDialogueText => _boxes.isNotEmpty;

  /// The chapter's OCR boxes by page (page fractions); an empty map = no dialogue text.
  void setOcr(Map<int, List<OcrWordBox>> boxesByPage) {
    _boxes = boxesByPage;
    if (boxesByPage.isEmpty) wordsOnScreen.value = null;
  }

  /// Every 250 ms while [enabled] and there is dialogue text: the words whose centres are inside
  /// the viewport. [toViewport] maps (page, fraction) to viewport px, [viewport] is its rect.
  void trackWords({
    required bool enabled,
    required Offset Function(int page, Offset fraction) toViewport,
    required Rect Function() viewport,
  }) {
    _wordsTimer?.cancel();
    _wordsTimer = null;
    if (!enabled) {
      wordsOnScreen.value = null;
      return;
    }
    _wordsTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_boxes.isEmpty) {
        wordsOnScreen.value = null;
        return;
      }
      wordsOnScreen.value = wordsInViewport(_boxes, toViewport, viewport());
    });
  }

  /// Words in panel [panelIndex] of [page] (0-based index into the page's panels), or null when the
  /// page has no dialogue text.
  int? wordsInPanel(int page, int panelIndex) {
    final boxes = _boxes[page];
    final st = _panels[_chapter]?[page];
    if (boxes == null || st is! PanelsFound || panelIndex < 0 || panelIndex >= st.fractions.length) return null;
    return wordsInRect(boxes, st.fractions[panelIndex]);
  }

  // ── Exit reports ─────────────────────────────────────────────────────────

  /// Test hook: marks samples as new, the way a finished analysis does.
  @visibleForTesting
  void debugAddSamples(String chapterId, {Map<int, String> tints = const {}, Map<int, List<PanelRect>> panels = const {}}) {
    (_dirtyTints[chapterId] ??= {}).addAll(tints);
    (_dirtyPanels[chapterId] ??= {}).addAll(panels);
  }

  /// The chapter's new samples since the last call, or an empty report.
  AmbientReport takeReport(String chapterId) {
    final t = _dirtyTints.remove(chapterId) ?? const <int, String>{};
    final p = _dirtyPanels.remove(chapterId) ?? const <int, List<PanelRect>>{};
    return AmbientReport(tints: t, panels: p);
  }

  void dispose() {
    _disposed = true;
    _trailing?.cancel();
    _wordsTimer?.cancel();
    for (final t in _guards.toList()) {
      t.cancel();
    }
    _guards.clear();
    pageTint.dispose();
    panels.dispose();
    wordsOnScreen.dispose();
  }
}
