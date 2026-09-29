// tokens.g.dart (per skin), token_types.g.dart, contract.g.dart and the generated compile-proof test.
import { dartField, dartStatic, enumName, leaves, DART_RESERVED_WORDS } from "./naming.mjs";
import { optionalSegment } from "./route.mjs";
import { hapticSteps } from "./haptics.mjs";
import { colorLeaves, roleLeaves, scrimLeaves, scalarLeaves } from "./emit-css.mjs";

const q = (s) => `'${s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$")}'`;
const num = (x) => String(Number(x.toFixed(6)));
const dbl = (x) => { const s = num(x); return /[.e]/.test(s) ? s : s + ".0"; };
const hex2 = (n) => n.toString(16).toUpperCase().padStart(2, "0");
function rgba(c) {
  const h = /^#([0-9a-f]{6})$/i.exec(c);
  if (h) return [...h[1].match(/../g).map((x) => parseInt(x, 16)), 1];
  const m = /^rgba?\(([^)]+)\)$/.exec(c);
  if (!m) throw new Error(`colour ${c}`);
  const [r, g, b, a = 1] = m[1].split(",").map(Number);
  return [r, g, b, a];
}
export const dartColor = (c) => { const [r, g, b, a] = rgba(c); return `Color(0x${hex2(Math.round(a * 255))}${hex2(r)}${hex2(g)}${hex2(b)})`; };
const colorFrom = (c, alpha) => { const [r, g, b] = rgba(c); return `Color.from(alpha: ${dbl(alpha)}, red: ${dbl(r / 255)}, green: ${dbl(g / 255)}, blue: ${dbl(b / 255)})`; };
const isScalar = (v) => v && typeof v === "object" && "value" in v;
const PREFIX = { cinematic: "Cine", glass: "Glass" };
const lines = (xs, ind = "  ") => xs.map((x) => ind + x).join("\n");

function alignment(direction, from) {
  const f = from ?? 0;
  const [bx, by, end] = { "to left": [1 - 2 * f, 0, "centerLeft"], "to right": [-1 + 2 * f, 0, "centerRight"], "to bottom": [0, -1 + 2 * f, "bottomCenter"], "to top": [0, 1 - 2 * f, "topCenter"] }[direction];
  return `begin: Alignment(${dbl(bx)}, ${dbl(by)}), end: Alignment.${end}`;
}

// [type, expr] of a static scrim, or null for the runtime-built ones (foot, head, sole).
function scrimDart(t, s) {
  if (s.kind === "eased") return ["LinearGradient", `LinearGradient(${alignment(s.direction, s.from)}, stops: kScrimStops, colors: [${t.scrim.alpha.map((a) => colorFrom(s.end, a)).join(", ")}])`];
  if (s.kind === "linear") return ["LinearGradient", `LinearGradient(${alignment(s.direction, 0)}, colors: [${s.colors.map(dartColor).join(", ")}])`];
  if (s.kind === "radial") return ["RadialGradient", `RadialGradient(center: Alignment(${dbl(2 * s.at[0] - 1)}, ${dbl(2 * s.at[1] - 1)}), radius: 1.0, stops: [${s.stops.map(dbl).join(", ")}], colors: [${s.colors.map(dartColor).join(", ")}], transform: CssEllipse(rx: ${dbl(s.size[0])}, ry: ${dbl(s.size[1])}, cx: ${dbl(s.at[0])}, cy: ${dbl(s.at[1])}))`];
  if (s.kind === "color") return ["Color", dartColor(s.value)];
  return null;
}

const colorOf = (t, ref) => (ref.startsWith("color.") ? leaves(t.color, (v) => typeof v === "string", "color").find(([k]) => k === ref)[1] : ref);

export function emitTokensDart(skin, t, header) {
  const P = PREFIX[skin];
  const holders = { Colors: [], Space: [], Dur: [], Curves: [], Springs: [], Scrim: [] };
  const fields = []; // {name, type, expr}
  const add = (key, type, expr, holder) => {
    if (holder) { const m = dartStatic(key); holders[holder].push(`static const ${m} = ${expr};`); expr = `${P}${holder}.${m}`; }
    fields.push({ name: dartField(key), type, expr });
  };
  for (const [k, v] of colorLeaves(t)) add(k, "Color", dartColor(v), "Colors");
  for (const [k, v] of Object.entries(t.space)) add(`space.${k}`, "double", dbl(v), "Space");
  for (const [k, [c, m, g, max]] of Object.entries(t.grid)) add(`grid.${k}`, "GridSpec", `GridSpec(columns: ${c}, margin: ${dbl(m)}, gutter: ${dbl(g)}, max: ${max ? dbl(max) : "double.infinity"})`);
  for (const g of ["bp", "radius", "blur", "hit"]) for (const [k, v] of Object.entries(t[g])) add(`${g}.${k}`, "double", dbl(v));
  for (const [k, r] of Object.entries(t.rule)) {
    if ("width" in r) add(`rule.${k}`, "BorderSide", `BorderSide(color: ${dartColor(colorOf(t, r.color))}, width: ${dbl(r.width)})`);
    else add(`rule.${k}`, "OxfordRule", `OxfordRule(thick: ${dbl(r.thick)}, gap: ${dbl(r.gap)}, thin: ${dbl(r.thin)}, color: ${dartColor(colorOf(t, r.color))})`);
  }
  for (const k of ["width", "offset", "halo"]) add(`focus.${k}`, "double", dbl(t.focus[k]));
  for (const [k, v] of Object.entries(t.z)) add(`z.${k}`, "int", String(v));
  holders.Scrim.push(`static const List<double> kScrimStops = [${t.scrim.stops.map(dbl).join(", ")}];`, `static const List<double> kScrimAlpha = [${t.scrim.alpha.map(dbl).join(", ")}];`);
  for (const [k, s] of scrimLeaves(t)) { const d = scrimDart(t, s); if (d) add(k, d[0], d[1], "Scrim"); }
  for (const [k, v] of leaves(t.dur, isScalar, "dur")) add(k, "Duration", `Duration(milliseconds: ${v.value})`, "Dur");
  for (const [k, v] of Object.entries(t.ease)) add(`ease.${k}`, "Curve", v === "linear" ? "Curves.linear" : `Cubic(${v.bezier.map(dbl).join(", ")})`, "Curves");
  for (const [k, s] of Object.entries(t.spring)) add(`spring.${k}`, "SpringToken", `SpringToken(ms: ${s.ms}, bounce: ${dbl(s.bounce)})`, "Springs");
  for (const [k, v] of scalarLeaves(t))
    add(k, isScalar(v) ? "double" : "MotionStagger", isScalar(v) ? dbl(v.value) : `MotionStagger(${Object.entries(v).map(([a, b]) => `${a}: ${b.value}`).join(", ")})`);
  const fam = (f) => t.font[f].flutter;
  for (const [k, r] of roleLeaves(t)) if (r.size) {
    const bps = Object.values(r.size);
    add(k, `${P}TextRole`, `${P}TextRole(family: ${q(fam(r.font))}, italic: ${r.italic}, wght: ${dbl(r.wght)}, axes: {${Object.entries(r.axes).map(([a, v]) => `${q(a)}: ${dbl(v)}`).join(", ")}}, sizes: [${bps.map((x) => dbl(x[0])).join(", ")}], lines: [${bps.map((x) => dbl(x[1])).join(", ")}], trackingEm: ${dbl(r.tracking)}, cap: ${dbl(r.scaleCap)}${r.upper ? ", upper: true" : ""})`);
  }
  for (const [k, f] of Object.entries(t.font)) add(`font.${k}`, "String", q(f.flutter));
  const names = fields.map((f) => f.name);
  const dup = names.find((n, i) => names.indexOf(n) !== i);
  if (dup) throw new Error(`duplicate Dart field ${dup}`);

  const drop = roleLeaves(t).find(([, r]) => !r.size)?.[1];
  const withAxis = (a) => Object.values(t.font).filter((f) => f.axes?.includes(a)).map((f) => q(f.flutter));
  const T = `${P}Tokens`;
  const hapticMap = Object.entries(t.haptics).map(([e, v]) => `HapticEvent.${enumName(e)}: [${hapticSteps(v).map((s) => `HapticStep(pattern: ${q(s.pattern)}${s.afterMs ? `, afterMs: ${s.afterMs}` : ""}${s.repeatEveryMs !== undefined ? `, repeatEveryMs: ${s.repeatEveryMs}, maxRepeats: ${s.maxRepeats}` : ""})`).join(", ")}],`);
  const ahap = Object.entries(t.ahap).map(([n, ev]) => `${q(n)}: [${ev.map((e) => `AhapEvent(type: ${q(e.type)}, time: ${dbl(e.t)}${e.dur !== undefined ? `, duration: ${dbl(e.dur)}` : ""}, intensity: ${dbl(e.i)}, sharpness: ${dbl(e.s)})`).join(", ")}],`);
  return `// ${header}
// ignore_for_file: type=lint

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class ${T} extends ThemeExtension<${T}> {
  const ${T}({
${lines(fields.map((f) => `required this.${f.name},`), "    ")}
  });

${lines(fields.map((f) => `final ${f.type} ${f.name};`))}

  @override
  ${T} copyWith({
${lines(fields.map((f) => `${f.type}? ${f.name},`), "    ")}
  }) {
    return ${T}(
${lines(fields.map((f) => `${f.name}: ${f.name} ?? this.${f.name},`), "      ")}
    );
  }

  @override
  ${T} lerp(covariant ThemeExtension<${T}>? other, double t) {
    if (other is! ${T}) return this;
    return ${T}(
${lines(fields.map((f) => `${f.name}: ${f.type === "Color" ? `Color.lerp(${f.name}, other.${f.name}, t)!` : `t < 0.5 ? ${f.name} : other.${f.name}`},`), "      ")}
    );
  }
}

const ${skin}Tokens = ${T}(
${fields.map((f) => `  ${f.name}: ${f.expr},`).join("\n")}
);

extension ${T}Context on BuildContext {
  ${T} get ${skin === "cinematic" ? "cine" : skin} => Theme.of(this).extension<${T}>()!;
}
${Object.entries(holders).map(([h, ms]) => `
abstract final class ${P}${h} {
${lines(ms)}
}
`).join("")}
class ${P}TextRole {
  const ${P}TextRole({
    required this.family,
    required this.italic,
    required this.wght,
    required this.axes,
    required this.sizes,
    required this.lines,
    required this.trackingEm,
    required this.cap,
    this.upper = false,
  });

  final String family;
  final bool italic;
  final double wght;
  final Map<String, double> axes;
  /// Per breakpoint: phone, tablet, desktop, wide.
  final List<double> sizes;
  final List<double> lines;
  final double trackingEm;
  final double cap;
  final bool upper;
}

abstract final class ${P}Type {
  static const Map<String, double> _wghtMax = {${Object.values(t.font).map((f) => `${q(f.flutter)}: ${dbl(f.wghtMax)}`).join(", ")}};
  static const Set<String> _wghtAxis = {${withAxis("wght").join(", ")}};
  static const Set<String> _opszAxis = {${withAxis("opsz").join(", ")}};
  static const String _legibleFrom = ${q(fam(t.legible.replaces))};
  static const String _legibleTo = ${q(fam(t.legible.font))};
  static const double _legibleAddLine = ${dbl(t.legible.addLine)};

  static int _breakpoint(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < ${t.bp.tablet} ? 0 : w < ${t.bp.desktop} ? 1 : w < ${t.bp.wide} ? 2 : 3;
  }

  static FontWeight _weight(double wght) => FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)];

  static TextStyle style(BuildContext context, ${P}TextRole role, {bool legible = false}) {
    final i = _breakpoint(context);
    final size = role.sizes[i];
    var line = role.lines[i];
    var family = role.family;
    if (legible && family == _legibleFrom) {
      family = _legibleTo;
      line += _legibleAddLine;
    }
    var wght = role.wght;
    if (MediaQuery.boldTextOf(context)) wght = math.min(wght + 120, _wghtMax[family] ?? wght + 120);
    return TextStyle(
      fontFamily: family,
      fontStyle: role.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: size,
      height: line / size,
      letterSpacing: role.trackingEm * size,
      fontWeight: _weight(wght),
      fontVariations: [
        if (_wghtAxis.contains(family)) FontVariation('wght', wght),
        if (_opszAxis.contains(family)) FontVariation('opsz', math.min(size, 96)),
        for (final e in role.axes.entries)
          if (e.key != 'opsz' && e.key != 'wght') FontVariation(e.key, e.value),
      ],
    );
  }

  static TextScaler scaler(BuildContext context, ${P}TextRole role) => MediaQuery.textScalerOf(context).clamp(maxScaleFactor: role.cap);
${drop ? `
  /// ${drop.sizeRule}; opsz = min(size, 96).
  static TextStyle dropcap(double paragraphLineHeightPx) {
    final size = 3 * paragraphLineHeightPx;
    return TextStyle(
      fontFamily: ${q(fam(drop.font))},
      fontSize: size,
      height: 1,
      letterSpacing: ${dbl(drop.tracking)} * size,
      fontWeight: _weight(${dbl(drop.wght)}),
      fontVariations: [FontVariation('wght', ${dbl(drop.wght)}), FontVariation('opsz', math.min(size, 96))],
    );
  }
` : ""}}

const Map<HapticEvent, List<HapticStep>> ${skin}Haptics = {
${lines(hapticMap)}
};

const Map<String, List<AhapEvent>> ${skin}Ahap = {
${lines(ahap)}
};

const Map<String, String> ${skin}SoundCues = {
${lines(Object.entries(t.sounds).map(([c, stem]) => `${q(c)}: ${q(`assets/sounds/${skin}/${stem}.wav`)},`))}
};

const Map<SoundEvent, List<String>> ${skin}SoundEvents = {
${lines(Object.entries(t.soundEvents).map(([e, c]) => `SoundEvent.${enumName(e)}: [${c ? q(c) : ""}],`))}
};
`;
}

export function emitTokenTypesDart(header) {
  return `// ${header}
// ignore_for_file: type=lint

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A spring token {ms, bounce}. Motion's visual duration maps to Flutter through ms × flutterScale,
/// so the stiffness matches Motion's (cinematic/DESIGN.md §2.8.4, S13).
class SpringToken {
  const SpringToken({required this.ms, required this.bounce, this.flutterScale = 1.2});

  final int ms;
  final double bounce;
  final double flutterScale;

  SpringDescription get description =>
      SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: (ms * flutterScale).round()), bounce: bounce);
}

/// A curve with its own duration (the stack's {ms, bezier} form).
class CurveToken {
  const CurveToken({required this.ms, required this.curve});

  final int ms;
  final Curve curve;

  Duration get duration => Duration(milliseconds: ms);
}

/// Stagger spacings in ms (cinematic/DESIGN.md §4.6).
class MotionStagger {
  const MotionStagger({this.item, this.row, this.cap, this.startDelay, this.fade});

  final int? item;
  final int? row;
  final int? cap;
  final int? startDelay;
  final int? fade;
}

class GridSpec {
  const GridSpec({required this.columns, required this.margin, required this.gutter, this.max = double.infinity});

  final int columns;
  final double margin;
  final double gutter;
  final double max;
}

/// Thick rule, gap, thin rule, stacked top to bottom.
class OxfordRule {
  const OxfordRule({required this.thick, required this.gap, required this.thin, required this.color});

  final double thick;
  final double gap;
  final double thin;
  final Color color;

  double get height => thick + gap + thin;
}

/// One step of a haptic value: play [pattern] [afterMs] after the previous step, optionally
/// repeating every [repeatEveryMs] up to [maxRepeats] times.
class HapticStep {
  const HapticStep({required this.pattern, this.afterMs = 0, this.repeatEveryMs, this.maxRepeats});

  final String pattern;
  final int afterMs;
  final int? repeatEveryMs;
  final int? maxRepeats;
}

/// One AHAP event: type 'T' (transient) or 'C' (continuous); times in seconds.
class AhapEvent {
  const AhapEvent({required this.type, required this.time, this.duration, required this.intensity, required this.sharpness});

  final String type;
  final double time;
  final double? duration;
  final double intensity;
  final double sharpness;
}

class FocusRingSpec {
  const FocusRingSpec({required this.width, required this.offset, required this.color, this.innerColor, this.innerWidth, this.glow, this.glowColor});

  final double width;
  final double offset;
  final Color color;
  final Color? innerColor;
  final double? innerWidth;
  final double? glow;
  final Color? glowColor;
}

/// Reproduces a CSS radial-gradient ellipse of rx × width by ry × height centred at (cx, cy) of the
/// box: a RadialGradient's radius is a fraction of the shortest side, so scale it per axis.
class CssEllipse extends GradientTransform {
  const CssEllipse({required this.rx, required this.ry, this.cx = 0.5, this.cy = 0.5});

  final double rx;
  final double ry;
  final double cx;
  final double cy;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final s = bounds.shortestSide;
    final px = bounds.left + cx * bounds.width;
    final py = bounds.top + cy * bounds.height;
    return Matrix4.translationValues(px, py, 0)
        .multiplied(Matrix4.diagonal3Values(rx * bounds.width / s, ry * bounds.height / s, 1))
        .multiplied(Matrix4.translationValues(-px, -py, 0));
  }
}
`;
}

const ENUM_TAKEN = new Set(["index", "values", "name", "hashCode", "runtimeType"]);
const safeEnum = (id, special = {}) => {
  const n = special[id] ?? enumName(id);
  if (DART_RESERVED_WORDS.has(n) || ENUM_TAKEN.has(n)) throw new Error(`enum value ${n} (${id}) needs a rename`);
  return n;
};
export const screenEnum = (id) => safeEnum(id, { index: "indexHub" });

export function emitContractDart(c, header) {
  const global = Object.keys(c.globalQuery);
  const routes = c.screens.flatMap((s) => {
    const n = screenEnum(s.id);
    const out = [`static const ${n}Pattern = ${q(s.path)};`];
    const app = s.aliases.filter((a) => a.platforms.includes("app")).map((a) => q(a.path));
    if (app.length) out.push(`static const List<String> ${n}Aliases = [${app.join(", ")}];`);
    if (s.redirect?.app) out.push(`static const ${n}Redirect = ${q(s.redirect.app)};`);
    const allowed = `{${[...s.query, ...global.filter((g) => !s.query.includes(g))].map(q).join(", ")}}`;
    const checks = [`assert(_known(query, const ${allowed}));`, ...(s.requiredQuery ?? []).map((r) => `assert(query[${q(r)}] != null);`)];
    const opt = optionalSegment(s);
    if (opt) out.push(`static String ${n}([SettingsSection? ${opt.name}, Map<String, Object?> query = const {}]) {`, ...checks.map((x) => "  " + x),
      `  return ${opt.name} == null ? _build(${n}Pattern, const [], query) : _build(${q(opt.pattern)}, [${opt.name}.slug], query);`, "}");
    else out.push(`static String ${n}(${[...s.params.map((p) => `Object ${p}`), s.requiredQuery ? "Map<String, Object?> query" : "[Map<String, Object?> query = const {}]"].join(", ")}) {`, ...checks.map((x) => "  " + x),
      `  return _build(${n}Pattern, ${s.params.length ? `[${s.params.join(", ")}]` : "const []"}, query);`, "}");
    return [...out, ""];
  });
  const en = (name, field, ids, special) => `enum ${name} {
${lines(ids.map((id, i) => `${safeEnum(id, special)}(${q(id)})${i === ids.length - 1 ? ";" : ","}`))}

  const ${name}(this.${field});

  final String ${field};
}
`;
  return `// ${header}
// ignore_for_file: type=lint

import 'dart:convert';

enum ScreenId {
${lines(c.screens.map((s, i) => `${screenEnum(s.id)}(${q(s.id)}, ${q(s.path)})${i === c.screens.length - 1 ? ";" : ","}`))}

  const ScreenId(this.id, this.path);

  final String id;
  final String path;
}

/// Route patterns and encoding builders (cinematic/DESIGN.md §8.0.3). Path segments go through
/// Uri.encodeComponent; the query is WHATWG form-encoded like the web's URLSearchParams, in the
/// map's insertion order, with null values skipped.
abstract final class Routes {
${lines(routes)}
  static bool _known(Map<String, Object?> query, Set<String> names) => query.keys.every(names.contains);

  static String _build(String pattern, List<Object> params, Map<String, Object?> query) {
    var i = 0;
    final path = pattern.replaceAllMapped(RegExp(r':[A-Za-z]+'), (_) => Uri.encodeComponent(params[i++].toString()));
    final qs = [
      for (final e in query.entries)
        if (e.value != null) '\${_formEncode(e.key)}=\${_formEncode(e.value.toString())}',
    ].join('&');
    return qs.isEmpty ? path : '\$path?\$qs';
  }

  /// application/x-www-form-urlencoded exactly as URLSearchParams writes it: UTF-8 bytes,
  /// A-Z a-z 0-9 * - . _ kept, space as +, every other byte %XX. (Uri(queryParameters:) differs:
  /// it keeps ~ and encodes *.)
  static String _formEncode(String s) {
    final out = StringBuffer();
    for (final b in utf8.encode(s)) {
      if ((b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A) || b == 0x2A || b == 0x2D || b == 0x2E || b == 0x5F) {
        out.writeCharCode(b);
      } else if (b == 0x20) {
        out.write('+');
      } else {
        out.write('%\${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }
}

${en("SettingsSection", "slug", c.settingsSections.map((s) => s.slug))}
abstract final class SheetIds {
${lines(c.sheets.map((s) => `static const ${enumName(s)} = ${q(s)};`))}

  static const List<String> all = [${c.sheets.map((s) => enumName(s)).join(", ")}];
}

abstract final class Flags {
  static const bool glassAvailable = ${c.flags.glass_available};
}

${en("HapticEvent", "id", c.hapticEvents)}
${en("SoundEvent", "id", c.soundEvents)}`;
}

// The compile proof: the analyzer skips *.g.dart, so this test imports every generated file.
// Its literals are written here, not derived from the JSON, so they catch regressions.
export function emitContractTestDart(header) {
  return `// ${header}

import 'package:flutter/painting.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

void main() {
  test('screen ids', () {
    expect(ScreenId.values.length, 35);
    expect(ScreenId.indexHub.id, 'index');
    expect(ScreenId.indexHub.path, '/more');
  });

  test('route builders encode like the web', () {
    expect(Routes.feature('mangadex', 'a/b c%'), '/sources/mangadex/series/a%2Fb%20c%25');
    expect(Routes.reader('s1', 'x!y', 'é'), '/reader/s1/x!y/%C3%A9');
    expect(Routes.recap('s1', 'k', {'to': '12'}), '/recap/s1/k?to=12');
    expect(Routes.library({'q': 'solo leveling', 'fav': 1}), '/library?q=solo+leveling&fav=1');
    expect(Routes.discover({'q': 'a~b*c é'}), '/search?q=a%7Eb*c+%C3%A9');
    expect(Routes.settings(), '/settings');
    expect(Routes.settings(SettingsSection.readingManga), '/settings/reading-manga');
  });

  test('event vocabularies', () {
    expect(HapticEvent.values.length, 90);
    expect(SoundEvent.values.length, 52);
    expect(HapticEvent.tapPrimary.id, 'tap.primary');
  });

  test('colours', () {
    expect(CineColors.spot, const Color(0xFFF4D03F));
    expect(cinematicTokens.colorSpotWash, const Color(0x29F4D03F));
  });

  test('springs map through ms x 1.2', () {
    final release = CineSprings.release.description;
    expect(release.stiffness, closeTo(155.42, 0.01));
    expect(release.damping, closeTo(24.93, 0.01));
    final sheet = CineSprings.sheet.description;
    final expected = SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 576),
    );
    expect(sheet.stiffness, expected.stiffness);
    expect(sheet.damping, expected.damping);
  });

  test('haptics and sounds cover every event', () {
    final complete = cinematicHaptics[HapticEvent.chapterComplete]!;
    expect(complete.length, 2);
    expect(complete[1].afterMs, 120);
    for (final e in HapticEvent.values) {
      expect(cinematicHaptics.containsKey(e), isTrue, reason: e.id);
    }
    for (final e in SoundEvent.values) {
      expect(cinematicSoundEvents.containsKey(e), isTrue, reason: e.id);
    }
  });
}
`;
}
