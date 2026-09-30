import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_layout.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_figures.dart';
import 'package:share_plus/share_plus.dart';

export 'package:manhwamaniacs/skins/glass/wrapped/share_layout.dart' show ShareFormat;

/// Every string a share PNG draws and every image URL it loads, in debug builds only, cleared per render: the mature-rule tests read them.
final List<String> debugGlassShareTexts = [];
final List<String> debugGlassShareImages = [];

/// What one share card is: its words and its figure, never anything but the server's `shareable` data (glass 9.2.4, 14.11).
class ShareSpec {
  const ShareSpec({required this.id, required this.eyebrow, required this.headline, this.footnote = '', this.wrapped, this.stat, this.fileName = 'manhwamaniacs.png'});

  final String id;
  final String eyebrow;
  final String headline;
  final String footnote;
  final WrappedShare? wrapped;
  final StatShare? stat;
  final String fileName;

  /// A Wrapped card's share side; null when the card has none (card 11, or nothing eligible).
  static ShareSpec? forCard(WrappedCard card, Annual a, {Set<String> matureSources = const {}}) {
    final data = shareEligible(card, a, matureSources: matureSources);
    if (data == null) return null;
    final copy = wrappedCopy(card, a);
    return ShareSpec(
      id: 'wrapped-${a.year}-${card.number}',
      eyebrow: copy.eyebrow,
      headline: copy.headline,
      footnote: card == WrappedCard.cover ? '' : copy.footnote,
      wrapped: WrappedShare(card, a, data),
      fileName: 'manhwamaniacs-${a.year}.png',
    );
  }

  /// A total card, the streak, a milestone or the range: card 2's layout with a numeral, one context line and a cover or bars.
  factory ShareSpec.stat(
          {required String id,
          required String eyebrow,
          required String numeral,
          required String unit,
          required String contextLine,
          String? coverUrl,
          List<DailyActivity> bars = const [],
          bool flame = false,
          String headline = '',}) =>
      ShareSpec(
        id: id,
        eyebrow: eyebrow,
        headline: headline,
        stat: StatShare(numeral: numeral, unit: unit, contextLine: contextLine, coverUrl: coverUrl, bars: bars, flame: flame),
        fileName: 'manhwamaniacs-$id.png',
      );
}

class WrappedShare {
  const WrappedShare(this.card, this.annual, this.data);
  final WrappedCard card;
  final Annual annual;
  final ShareData data;
}

class StatShare {
  const StatShare({required this.numeral, required this.unit, required this.contextLine, this.coverUrl, this.bars = const [], this.flame = false});
  final String numeral;
  final String unit;
  final String contextLine;
  final String? coverUrl;
  final List<DailyActivity> bars;
  final bool flame;
}

/// The source ids the catalogue marks mature. While the catalogue is unknown every source counts as mature (the conservative side).
final glassMatureSourcesProvider = Provider<Set<String>?>(
  (ref) {
    final list = ref.watch(sourcesListProvider).valueOrNull;
    return list == null
        ? null
        : {
            for (final s in list)
              if (s.mature) s.id,
          };
  },
  name: 'glassMatureSources',
);

/// The authenticated cover image of [url] (a share draws covers through this and precaches them first).
final glassShareImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) {
    final base = ref.watch(apiBaseUrlProvider);
    final token = ref.watch(authTokenStoreProvider).token;
    final profileId = ref.watch(activeProfileProvider)?.id;
    return (url) => CachedNetworkImageProvider(coverUrlAtWidth(resolveApiResourceUrl(base, url), coverRequestWidth(112, 3)), headers: apiImageHttpHeaders(token, profileId: profileId));
  },
  name: 'glassShareImage',
);

abstract interface class GlassShareDelegate {
  Future<ShareResult> share(ShareParams params);
}

class _SharePlusDelegate implements GlassShareDelegate {
  const _SharePlusDelegate();
  @override
  Future<ShareResult> share(ShareParams params) => SharePlus.instance.share(params);
}

final glassShareDelegateProvider = Provider<GlassShareDelegate>((ref) => const _SharePlusDelegate(), name: 'glassShareDelegate');

/// Every cover URL [spec] will load.
List<String> shareImageUrls(ShareSpec spec) {
  final out = <String>[];
  final w = spec.wrapped;
  if (w != null) {
    for (final s in w.data.series) {
      if (s.coverUrl != null) out.add(s.coverUrl!);
    }
    for (final s in [w.data.first, w.data.last]) {
      if (s?.coverUrl != null) out.add(s!.coverUrl!);
    }
  }
  if (spec.stat?.coverUrl != null) out.add(spec.stat!.coverUrl!);
  return out;
}

/// The three ground colours: the first three palette colours of the shareable covers, else `iris800`, `iris900`, `g25`.
List<Color> shareBlobColors(ShareSpec spec) {
  final ambient = <Color>[];
  final a = spec.wrapped?.annual.shareable?.topSeries ?? const [];
  for (final s in a) {
    final duo = s.ambient?.duo;
    if (duo != null && duo.length == 7) {
      final v = int.tryParse(duo.substring(1), radix: 16);
      if (v != null) ambient.add(Color(0xFF000000 | v));
    }
  }
  const fallback = [Color(0xFF4336A3), Color(0xFF2B2370), Color(0xFF060608)];
  return [for (var i = 0; i < 3; i++) i < ambient.length ? ambient[i] : fallback[i]];
}

/// The share card laid out in its 360 logical px frame (glass 9.2.4); the PNG is this at pixel ratio 3.
class ShareCardView extends StatelessWidget {
  const ShareCardView({super.key, required this.spec, required this.format, required this.images, this.profileName});
  final ShareSpec spec;
  final ShareFormat format;
  final Map<String, ImageProvider> images;
  final String? profileName;

  @override
  Widget build(BuildContext context) {
    final logical = shareLogical(format);
    final boxes = shareBoxes(format);
    double l(double v) => v / kShareScale;
    Rect lr(Rect r) => Rect.fromLTRB(l(r.left), l(r.top), l(r.right), l(r.bottom));
    void note(String t) {
      if (kDebugMode) debugGlassShareTexts.add(t);
    }

    Widget cover(String? url, double w, double h, double radius) {
      if (url != null && kDebugMode) debugGlassShareImages.add(url);
      final img = url == null ? null : images[url];
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
            width: w,
            height: h,
            child: img == null ? const ColoredBox(color: Color(0xFF1A1A20)) : Image(image: img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A20))),),
      );
    }

    Widget label(String text, Rect box, {required GlassTypeRole role, required double size, Color? color, int? wght, int maxLines = 1, bool caps = false, double tracking = 0}) {
      note(text);
      final base = roleStyle(context, role, size: size, wght: wght, maxScale: 1);
      return Positioned.fromRect(
        rect: lr(box),
        child: Text(
          caps ? text.toUpperCase() : text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: base.copyWith(color: color ?? gt.colorLabel1, letterSpacing: tracking * size),
        ),
      );
    }

    final colors = shareBlobColors(spec);
    final centres = format == ShareFormat.story ? const [Offset(216, 384), Offset(864, 768), Offset(540, 1536)] : [const Offset(216, 384), const Offset(864, 768), const Offset(540, 1536 * 1350 / 1920)];
    final stat = spec.stat;
    final children = <Widget>[
      Positioned.fill(child: CustomPaint(painter: _GroundPainter(colors, centres))),
      label(spec.eyebrow, boxes.eyebrow, role: gt.typeCaption1, size: 12, caps: true, tracking: 0.18, color: gt.colorLabel2, wght: 600),
    ];
    if (stat == null) {
      children
        ..add(label(spec.headline, boxes.headline, role: gt.typeTitle1, size: 28, maxLines: format == ShareFormat.story ? 3 : 2))
        ..add(_figure(spec, boxes, format, images, cover, note));
      if (format == ShareFormat.story && spec.footnote.isNotEmpty) children.add(label(spec.footnote, boxes.footnote, role: gt.typeFootnote, size: 13, color: gt.colorLabel2, maxLines: 2));
    } else {
      children
        ..add(label(stat.numeral, boxes.numeral, role: gt.typeWrappedNumeral, size: 88))
        ..add(label(stat.unit.isEmpty ? stat.contextLine : '${stat.unit} · ${stat.contextLine}', boxes.context, role: gt.typeTitle3, size: 56 / 3, color: gt.colorLabel2, maxLines: 2));
      if (format == ShareFormat.story) {
        if (stat.bars.isNotEmpty) {
          children.add(Positioned.fromRect(rect: lr(boxes.bars), child: CustomPaint(painter: _BarsPainter(stat.bars))));
        } else if (stat.flame) {
          children.add(Positioned.fromRect(rect: lr(boxes.bars), child: const Center(child: StreakFlamePicture(size: 120))));
        } else if (stat.coverUrl != null) {
          children.add(Positioned.fromRect(rect: lr(boxes.cover), child: cover(stat.coverUrl, 80, 120, 28 / 3)));
        }
      }
    }
    // The foot: the wordmark, the mono line and the optional profile name.
    Rect foot(double baseline, double h) => Rect.fromLTWH(kShareMargin, baseline - h, 1080 - 2 * kShareMargin, h * 1.3);
    children
      ..add(label('ManhwaManiacs', foot(boxes.wordmarkBaseline, 68), role: gt.typeTitle1, size: 22, wght: 700, color: const Color(0xFFF5F7FA)))
      ..add(label('ManhwaManiacs · ${spec.wrapped?.annual.year ?? DateTime.now().year}', foot(boxes.monoBaseline, 24), role: gt.typeMono, size: 8, color: gt.colorLabel2));
    final name = profileName;
    if (name != null && name.isNotEmpty) children.add(label(name, foot(boxes.nameBaseline, 36), role: gt.typeCaption1, size: 12, color: gt.colorLabel2));
    return SizedBox(width: logical.width, height: logical.height, child: Stack(children: children));
  }
}

Widget _figure(ShareSpec spec, ShareBoxes boxes, ShareFormat format, Map<String, ImageProvider> images, CoverBuilder cover, void Function(String) note) {
  final w = spec.wrapped;
  if (w == null) return const SizedBox.shrink();
  final fit = figureFit(boxes.figure);
  final s = fit.scale / kShareScale;
  return Positioned(
    left: fit.origin.dx / kShareScale,
    top: fit.origin.dy / kShareScale,
    width: kFigureUnits.width * s,
    height: kFigureUnits.height * s,
    child: FittedBox(
      child: wrappedFigure(FigureInput(card: w.card, annual: w.annual, data: w.data, cover: cover, onText: note, share: true)),
    ),
  );
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter(this.colors, this.centres);
  final List<Color> colors;
  final List<Offset> centres;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF000000));
    final k = size.width / 1080;
    for (var i = 0; i < 3; i++) {
      final c = centres[i] * k;
      final shader = ui.Gradient.radial(c, 720 * k, [colors[i].withValues(alpha: 0.55), colors[i].withValues(alpha: 0)]);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) => true;
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.days);
  final List<DailyActivity> days;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    final mx = days.fold<int>(1, (m, d) => d.chaptersRead > m ? d.chaptersRead : m);
    final w = (size.width / days.length - 1.5).clamp(1.0, 10.0);
    final step = size.width / days.length;
    for (var i = 0; i < days.length; i++) {
      final h = days[i].chaptersRead <= 0 ? 1.0 : size.height * days[i].chaptersRead / mx;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * step + (step - w) / 2, size.height - h, w, h), const Radius.circular(1.5)),
          Paint()..color = days[i].chaptersRead <= 0 ? gt.colorFill2 : gt.colorIris500,);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.days != days;
}

/// Renders [spec] as a PNG: the share card laid out at 360 logical px in an offstage `RepaintBoundary` on the root overlay, every cover
/// precached, then `toImage(pixelRatio: 3)` (1080 x 1920 Story, 1080 x 1350 Post). Text scale and bold text are pinned so the PNG
/// never depends on the phone's settings.
Future<Uint8List> renderShareCard(BuildContext context, WidgetRef ref, ShareSpec spec, ShareFormat format, {String? profileName}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  if (kDebugMode) {
    debugGlassShareTexts.clear();
    debugGlassShareImages.clear();
  }
  final provider = ref.read(glassShareImageProvider);
  final images = <String, ImageProvider>{};
  await Future.wait([
    for (final u in shareImageUrls(spec).toSet())
      () async {
        final p = provider(u);
        try {
          await precacheImage(p, context);
          images[u] = p;
        } catch (_) {
          // A cover that fails becomes a #1A1A20 box; the card still renders.
        }
      }(),
  ]);
  if (!context.mounted) throw StateError('share card: the host left');
  final key = GlobalKey();
  final logical = shareLogical(format);
  final mq = MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling, boldText: false);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -100000,
      top: 0,
      width: logical.width,
      height: logical.height,
      child: MediaQuery(
        data: mq,
        child: ExcludeSemantics(
          child: RepaintBoundary(key: key, child: ShareCardView(spec: spec, format: format, images: images, profileName: profileName)),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: kShareScale);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

/// The "Show my profile name" line: only when the switch is on.
String? shareProfileName(bool on, String? name) => on ? name : null;

/// Kept for callers that only need the streak line.
String streakShareLine(int days) => '${plural(days, 'day')} in a row';
