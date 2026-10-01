import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart' show PageSample;
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';

/// What the reader chrome reads and asks of the Glass manga reader. The reader's `State` implements it; the chrome never
/// moves the page layer itself, every movement is an engine command issued here.
abstract interface class GlassReaderHost {
  ReaderEngine get engine;

  String get sourceId;
  String get seriesKey;

  /// "Solo Leveling".
  String get seriesTitle;

  /// "Ch 143" for [chapterId] (the chapter under the reading line).
  String chapterShort(String chapterId);

  /// The chapter the engine names, or null while none is loaded.
  ReaderChapter? chapterById(String id);

  /// The page of [chapterId] (1-based), for thumbnails.
  ReaderPage? pageOf(String chapterId, int page);

  bool get readAll;
  bool get paged;
  bool get cinema;
  bool get hideCinemaProgress;
  bool get locked;
  bool get offline;
  bool get accessible;
  bool get reducedMotion;
  bool get pageTinted;

  /// The Rain scene is playing and nothing switches the shader off (Reduce Motion, Reduce Transparency, Solid glass).
  bool get rainOn;

  /// The page sample the chrome's legibility follows: the engine's, held through a fling above 3000 px/s.
  PageSample? get lbSample;

  /// The chrome's current page tint (already gated and held), null for neutral glass.
  Color? get tint;

  /// The label of the next chapter for the bottom capsule's tooltip, null when there is none.
  String? get nextChapterLabel;

  /// The open go-to-page popover.
  bool get goToOpen;
  int? get zoomChipPercent;
  String? get seamChip;
  int get lockPulse;

  /// The hit lens and its match capsule are up.
  bool get matchesShown;

  void back();
  void openSeries();
  void openChapterList({bool byKey = false});
  void openSettings({bool byKey = false});
  void toggleBookmark();
  void setGoTo(bool open);
  void jumpTo(int page);
  void previousChapter();
  void nextChapter();
  void toggleCruise();

  /// Guided view (glass 9.4.3): open, and whether the page under the reading line has panels (the panel-focus button shows).
  bool get guidedOn;
  bool get guidedAvailable;
  void toggleGuided();

  /// The cruise pill's state, and whether the layout can cruise at all (a strip does; Single and Double do not).
  CruiseState get cruise;
  bool get cruiseAvailable;
  void cruisePreview(double v);
  void cruiseCommit(double v);
  void cruiseStep(double by);
  void cruiseResume();

  /// The scrub rail took or released the finger (the chrome holds while scrubbing).
  void scrubbing(bool active, {double? thumbY});
}
