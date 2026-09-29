// Glass: mobile/lib/skins/glass/tokens.g.dart and its generated compile test (glass/DESIGN.md §2.8
// Flutter column, §3.3, §3.6, §3.7, §5, §6).
import { enumName } from "./naming.mjs";
import { hapticSteps } from "./haptics.mjs";
import { dartColor } from "./emit-dart.mjs";
import { glassSprings, TIERS } from "./emit-glass-css.mjs";

const q = (s) => `'${s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$")}'`;
const num = (x) => String(Number(x.toFixed(6)));
const dbl = (x) => { const s = num(x); return /[.e]/.test(s) ? s : s + ".0"; };
const cap = (s) => s[0].toUpperCase() + s.slice(1);
const camel = (...ps) => ps.map((p, i) => (i ? cap(p) : p)).join("");
const lines = (xs, ind = "  ") => xs.map((x) => ind + x).join("\n");
const colorOf = (t, c) => (c.startsWith("color.") ? c.slice(6).split(".").reduce((o, p) => o[p], t.color) : c);
function shadow(s) {
  const [x, y, b, ...rest] = s.split(" ");
  return `BoxShadow(offset: Offset(${dbl(parseFloat(x))}, ${dbl(parseFloat(y))}), blurRadius: ${dbl(parseFloat(b))}, color: ${dartColor(rest.join(" "))})`;
}
const side = (t, b) => `BorderSide(color: ${dartColor(colorOf(t, b.color))}, width: ${dbl(b.width)})`;
const FAMILY = { sans: "GoogleSansFlexMM", mono: "GoogleSansCodeMM" };

export function emitGlassDart(skin, t, header) {
  const holders = { Colors: [], Space: [], Radius: [], Springs: [], Curves: [], Physics: [], Thresholds: [] };
  const fields = []; // {name, type, expr, def?}
  const add = (name, type, expr, holder, member) => {
    if (holder) { holders[holder].push(`static const ${member} = ${expr};`); expr = `Glass${holder}.${member}`; }
    fields.push({ name, type, expr });
  };
  const colors = (o, p) => Object.entries(o).flatMap(([k, v]) => (typeof v === "string" ? [[[...p, k], v]] : colors(v, [...p, k])));
  for (const [ps, v] of colors(t.color, [])) add(camel("color", ...ps), "Color", dartColor(v), "Colors", camel(...ps));
  for (const [k, v] of Object.entries(t.space)) add(camel("space", k), "double", dbl(v), "Space", k);
  for (const [k, v] of Object.entries(t.layout)) {
    if (typeof v === "number") add(camel("layout", k), "double", dbl(v));
    else if ("android" in v) { add(camel("layout", k), "double", dbl(v.value)); add(camel("layout", k, "android"), "double", dbl(v.android)); }
    else if ("fraction" in v) { const b = k.replace(/Max$/, ""); add(camel("layout", b, "min"), "double", dbl(v.min)); add(camel("layout", b, "fraction"), "double", dbl(v.fraction)); add(camel("layout", k), "double", dbl(v.max)); }
    else add(camel("layout", k, "ch"), "int", String(v.value));
  }
  for (const [k, v] of Object.entries(t.bp)) add(camel("bp", k), "double", dbl(v));
  for (const [k, v] of Object.entries(t.radius)) add(camel("radius", k), "double", dbl(v), "Radius", k);
  for (const [k, v] of Object.entries(t.blur)) add(camel("blur", k), "double", dbl(v));
  for (const [k, b] of Object.entries(t.border)) {
    if ("offset" in b) add(camel("border", k), "FocusRingSpec", `FocusRingSpec(width: ${dbl(b.width)}, offset: ${dbl(b.offset)}, color: ${dartColor(colorOf(t, b.color))}, innerColor: ${dartColor(b.innerColor)}, innerWidth: ${dbl(b.innerWidth)}, glow: ${dbl(b.glow)}, glowColor: ${dartColor(b.glowColor)})`);
    else add(camel("border", k), "BorderSide", side(t, b));
  }
  add("lightAngle", "double", dbl(t.light.angle));
  add("lightRange", "double", dbl(t.light.range));
  for (const [k, v] of Object.entries(t.z)) add(camel("z", k), "int", String(v));
  for (const k of TIERS) {
    const g = t.glass[k];
    add(camel("glass", k), "GlassTier", `GlassTier(thickness: ${dbl(g.thickness)}, bezel: ${dbl(g.bezel)}, displacement: ${dbl(g.displacement)}, blur: ${dbl(g.blur)}, saturate: ${dbl(g.saturate)}, fill: ${dartColor(g.fill)}, rim: ${dartColor(g.rim)}, specular: ${dbl(g.specular)}, shadow: ${shadow(g.shadow)}, dispersion: ${dbl(g.dispersion)}, rond: ${dbl(g.rond)})`);
  }
  for (const k of ["clear", "tinted"]) {
    const f = t.glass[k];
    const parts = [`fill: ${dartColor(f.fill)}`, ...(f.fillPressed ? [`fillPressed: ${dartColor(f.fillPressed)}`] : []), `blur: ${dbl(f.blur)}`, `saturate: ${dbl(f.saturate)}`, `rim: ${dartColor(f.rim)}`,
      typeof f.specular === "number" ? `specular: ${dbl(f.specular)}` : `specularColor: ${dartColor(f.specular)}`, ...(f.shadow ? [`shadow: ${shadow(f.shadow)}`] : [])];
    add(camel("glass", k), "GlassFinish", `GlassFinish(${parts.join(", ")})`);
  }
  for (const k of ["solid1", "solid2"]) add(camel("glass", k), "Color", dartColor(t.glass[k]));
  for (const k of ["materialThin", "materialRegular", "materialThick"]) add(camel("glass", k), "MaterialSpec", `MaterialSpec(fill: ${dartColor(t.glass[k].fill)}, blur: ${dbl(t.glass[k].blur)})`);
  const L = t.dim.legibility;
  for (const [n, v] of [["dimMin", L.min], ["dimSlope", L.slope], ["dimMax", L.max], ["dimMinHc", L.minHc], ["dimMaxHc", L.maxHc], ["gradSlope", t.dim.grad.slope], ["dimEdgePlateau", t.dim.edgePlateau], ["dimEdgeFade", t.dim.edgeFade]]) add(n, "double", dbl(v));
  add("glassSnap", "List<double>", `[${t.glass.snap.map(dbl).join(", ")}]`);
  for (const [k, v] of Object.entries(t.caustic)) add(camel("caustic", k), "double", dbl(v));
  for (const [k, s] of glassSprings(t)) add(camel("spring", k), "SpringToken", `SpringToken(ms: ${s.ms}, bounce: ${dbl(s.bounce)}, flutterScale: 1.0)`, "Springs", k);
  for (const [k, c] of Object.entries(t.curve)) {
    if (!c.bezier && !c.curve) { add(camel("curve", k), "Duration", `Duration(milliseconds: ${c.ms})`, "Curves", k); continue; }
    const curve = c.bezier ? `Cubic(${c.bezier.map(dbl).join(", ")})` : c.curve === "linear" ? "Curves.linear" : "Threshold(0.5)";
    add(camel("curve", k), "CurveToken", `CurveToken(ms: ${c.ms}, curve: ${curve})`, "Curves", k);
  }
  for (const [k, v] of Object.entries(t.physics)) add(camel("physics", k), "double", dbl(v), "Physics", k);
  for (const [k, v] of Object.entries(t.threshold)) add(camel("threshold", k), "double", dbl(v), "Thresholds", k);
  const rec = (x) => (x ? `(${dbl(x[0])}, ${dbl(x[1])})` : "null");
  for (const [k, r] of Object.entries(t.type))
    add(camel("type", k), "GlassTypeRole", `GlassTypeRole(family: ${q(FAMILY[r.font])}, phone: ${rec(r.phone)}, tablet: ${rec(r.tablet)}, desktop: ${rec(r.desktop)}, wide: ${rec(r.wide)}, wght: ${dbl(r.wght)}, rond: ${r.rond === null ? "null" : dbl(r.rond)}, trackingEm: ${dbl(r.tracking)}${r.capAt ? `, capAt: ${dbl(r.capAt)}` : ""}${r.floor ? `, floor: ${dbl(r.floor)}` : ""})`);
  const names = fields.map((f) => f.name);
  const dup = names.find((n, i) => names.indexOf(n) !== i);
  if (dup) throw new Error(`duplicate Dart field ${dup}`);

  const T = "GlassTokens";
  const all = [...fields, { name: "legible", type: "bool" }];
  const hapticMap = Object.entries(t.haptics).map(([e, v]) => `HapticEvent.${enumName(e)}: [${hapticSteps(v).map((s) => `HapticStep(pattern: ${q(s.pattern)}${s.afterMs ? `, afterMs: ${s.afterMs}` : ""}${s.repeatEveryMs !== undefined ? `, repeatEveryMs: ${s.repeatEveryMs}, maxRepeats: ${s.maxRepeats}` : ""})`).join(", ")}],`);
  const ahap = Object.entries(t.ahap).map(([n, ev]) => `${q(n)}: [${ev.map((e) => `AhapEvent(type: ${q(e.type)}, time: ${dbl(e.t)}${e.dur !== undefined ? `, duration: ${dbl(e.dur)}` : ""}, intensity: ${dbl(e.i)}, sharpness: ${dbl(e.s)})`).join(", ")}],`);
  const cues = (v) => (v === null ? [] : Array.isArray(v) ? v : [v]);
  return `// ${header}
// ignore_for_file: type=lint

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class ${T} extends ThemeExtension<${T}> {
  const ${T}({
${lines(fields.map((f) => `required this.${f.name},`), "    ")}
    this.legible = false,
  });

${lines(fields.map((f) => `final ${f.type} ${f.name};`))}
  /// Legible text (§3.6): every GlassType style switches to Atkinson Hyperlegible Next.
  final bool legible;

  @override
  ${T} copyWith({
${lines(all.map((f) => `${f.type}? ${f.name},`), "    ")}
  }) {
    return ${T}(
${lines(all.map((f) => `${f.name}: ${f.name} ?? this.${f.name},`), "      ")}
    );
  }

  @override
  ${T} lerp(covariant ThemeExtension<${T}>? other, double t) {
    if (other is! ${T}) return this;
    return ${T}(
${lines(all.map((f) => `${f.name}: ${f.type === "Color" ? `Color.lerp(${f.name}, other.${f.name}, t)!` : f.type === "double" ? `${f.name} + (other.${f.name} - ${f.name}) * t` : `t < 0.5 ? ${f.name} : other.${f.name}`},`), "      ")}
    );
  }
}

const ${skin}Tokens = ${T}(
${fields.map((f) => `  ${f.name}: ${f.expr},`).join("\n")}
);

extension ${T}Context on BuildContext {
  ${T} get glass => Theme.of(this).extension<${T}>()!;
}
${Object.entries(holders).map(([h, ms]) => `
abstract final class Glass${h} {
${lines(ms)}
}
`).join("")}
/// One glass tier (§2.4.3): lengths in logical px, blur as σ, fill and rim colours, the shadow.
class GlassTier {
  const GlassTier({required this.thickness, required this.bezel, required this.displacement, required this.blur, required this.saturate, required this.fill, required this.rim, required this.specular, required this.shadow, required this.dispersion, required this.rond});

  final double thickness;
  final double bezel;
  final double displacement;
  final double blur;
  final double saturate;
  final Color fill;
  final Color rim;
  final double specular;
  final BoxShadow shadow;
  final double dispersion;
  final double rond;
}

/// A finish on its host tier (§2.4.2): clear, or the one tinted action.
class GlassFinish {
  const GlassFinish({required this.fill, this.fillPressed, required this.blur, required this.saturate, required this.rim, this.specular, this.specularColor, this.shadow});

  final Color fill;
  final Color? fillPressed;
  final double blur;
  final double saturate;
  final Color rim;
  final double? specular;
  final Color? specularColor;
  final BoxShadow? shadow;
}

/// A frosted material behind content (fill + blur σ).
class MaterialSpec {
  const MaterialSpec({required this.fill, required this.blur});

  final Color fill;
  final double blur;
}

/// A type role (§3.7): (size, line) px per frame, null where the role does not exist.
class GlassTypeRole {
  const GlassTypeRole({required this.family, this.phone, this.tablet, this.desktop, this.wide, required this.wght, this.rond, required this.trackingEm, this.capAt, this.floor});

  final String family;
  final (double, double)? phone;
  final (double, double)? tablet;
  final (double, double)? desktop;
  final (double, double)? wide;
  final double wght;
  /// null for the Google Sans Code roles, which have no ROND axis.
  final double? rond;
  final double trackingEm;
  /// The largest size text scaling may reach (§3.3), or null for no cap.
  final double? capAt;
  /// The smallest size text scaling may reach (footnote, 11 px).
  final double? floor;

  bool get isMono => family == ${q(FAMILY.mono)};

  /// The (size, line) at frame i (0 phone … 3 wide); a null frame takes the previous one, a null phone the tablet's.
  (double, double) at(int i) {
    final xs = [phone, tablet, desktop, wide];
    for (var j = i; j >= 0; j--) {
      if (xs[j] != null) return xs[j]!;
    }
    return xs.firstWhere((x) => x != null)!;
  }
}

abstract final class GlassType {
  static const String _legibleFamily = ${q(t.font.legible.flutter)};
  static const double _legibleTrackingEm = 0.01;

  /// 0 phone, 1 tablet, 2 desktop, 3 wide (glass conventions).
  static int frame(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= ${t.bp.wide}) return 3;
    if (size.width >= ${t.bp.desktop} && size.shortestSide >= 600) return 2;
    if (size.width >= ${t.bp.frame}) return 1;
    return 0;
  }

  static FontWeight _weight(double wght) => FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)];

  /// [grad] is the caller's GRAD (the backdrop's, +20 with Bold Text on glass); [rond] overrides the role's.
  static TextStyle style(BuildContext context, GlassTypeRole role, {bool legible = false, double? rond, double grad = 0}) {
    final (size, line) = role.at(frame(context));
    final swap = legible && !role.isMono;
    var wght = role.wght;
    if (MediaQuery.boldTextOf(context)) wght = math.min(wght + 100, 800);
    final tracking = role.trackingEm + (swap ? _legibleTrackingEm : 0);
    return TextStyle(
      fontFamily: swap ? _legibleFamily : role.family,
      fontSize: size,
      height: line / size,
      letterSpacing: tracking * size,
      fontWeight: _weight(wght),
      fontVariations: [
        FontVariation('wght', wght),
        if (!role.isMono) ...[
          FontVariation('opsz', size),
          FontVariation('ROND', rond ?? role.rond ?? 0),
          FontVariation('GRAD', grad),
        ],
      ],
    );
  }

  /// capAt / base size, or infinity for an uncapped role.
  static double maxScaleFor(BuildContext context, GlassTypeRole role) {
    final cap = role.capAt;
    return cap == null ? double.infinity : cap / role.at(frame(context)).$1;
  }

  static TextScaler scaler(BuildContext context, GlassTypeRole role) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxScaleFor(context, role));

  /// The rendered size after text scaling, its cap and the footnote floor.
  static double scaledSize(BuildContext context, GlassTypeRole role) {
    final scaled = scaler(context, role).scale(role.at(frame(context)).$1);
    return math.max(scaled, role.floor ?? 0);
  }
}

const Map<HapticEvent, List<HapticStep>> ${skin}Haptics = {
${lines(hapticMap)}
};

const Map<String, List<AhapEvent>> ${skin}Ahap = {
${lines(ahap)}
};

const Map<String, String> ${skin}SoundCues = {
${lines(Object.entries(t.sounds).map(([c, stem]) => `${q(c)}: ${q(`assets/sounds/${skin}/${stem}.wav`)},`))}
};

/// nav.push lists one cue per depth 1 to 4.
const Map<SoundEvent, List<String>> ${skin}SoundEvents = {
${lines(Object.entries(t.soundEvents).map(([e, c]) => `SoundEvent.${enumName(e)}: [${cues(c).map(q).join(", ")}],`))}
};
`;
}

// The compile proof for Glass and both motion enums; literals written here, not derived from the JSON.
export function emitGlassTestDart(header) {
  return `// ${header}

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart' as cine;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart' as glass;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

void main() {
  test('colours', () {
    expect(GlassColors.iris600, const Color(0xFF7563F2));
    expect(glassTokens.colorLabel2, const Color(0xA3EBEBF5));
  });

  test('physical springs: withDurationAndBounce at ms x 1.0', () {
    final page = GlassSprings.page.description;
    expect(page.stiffness, closeTo(146.0, 0.05));
    expect(page.damping, closeTo(24.17, 0.01));
    expect(GlassSprings.track.description.stiffness, closeTo(1754.6, 0.1));
  });

  test('layout, snap and focus', () {
    expect(glassTokens.glassSnap, [36, 57, 97]);
    expect(glassTokens.layoutTouchMin, 44);
    expect(glassTokens.layoutTouchMinAndroid, 48);
    expect(glassTokens.borderFocusRing.width, 2);
    expect(glassTokens.legible, isFalse);
  });

  test('motion names', () {
    expect(glass.MotionName.values.length, 116);
    expect(glass.MotionName.throwMove.label, 'THROW');
    expect(cine.MotionName.values.length, 38);
  });

  test('haptics and sounds cover every event', () {
    for (final e in HapticEvent.values) {
      expect(glassHaptics.containsKey(e), isTrue, reason: e.id);
    }
    for (final e in SoundEvent.values) {
      expect(glassSoundEvents.containsKey(e), isTrue, reason: e.id);
    }
    expect(glassSoundEvents[SoundEvent.navPush]!.length, 4);
    expect(glassHaptics[HapticEvent.navRoot]!.single.maxRepeats, 4);
  });
}
`;
}
