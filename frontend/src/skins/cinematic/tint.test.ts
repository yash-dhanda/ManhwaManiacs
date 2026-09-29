import { describe, expect, it } from "vitest";
import { contrastBetween, contrastRatio, over, parseColor } from "@/lib/contrast";
import { ambientRoles, issueStock, pageLight, pageTint } from "./tint";
import { color } from "./tokens.generated";

const c = color;
const rgb = (v: string) => parseColor(v)!;
const flat = (fg: string, bg: string) => contrastRatio(over(rgb(fg), rgb(bg)), rgb(bg));

describe("tint loops (1,440 cases)", () => {
  it("pageLight >= 4.5 on black; Issue ink >= 13 and muted >= 5.5 on the Issue page", () => {
    const t0 = performance.now();
    let n = 0;
    for (let h = 0; h < 360; h++) for (const s of [0.08, 0.35, 0.6, 0.9]) {
      n++;
      expect(contrastBetween(pageLight(h, s), "#000000"), `pageLight ${h}/${s}`).toBeGreaterThanOrEqual(4.5);
      const st = issueStock(ambientRoles(h, s));
      expect(contrastBetween(st.ink, st.page), `ink ${h}/${s}`).toBeGreaterThanOrEqual(13);
      expect(contrastBetween(st.muted, st.page), `muted ${h}/${s}`).toBeGreaterThanOrEqual(5.5);
    }
    expect(n).toBe(1440);
    expect(performance.now() - t0).toBeLessThan(1000);
  });
  it("no ambient gives Nitrate; page tint stays dark", () => {
    expect(issueStock(null).page).toBe("#000000");
    expect(contrastBetween(pageTint(200, 0.9), "#000000")).toBeLessThan(1.5);
  });
});

// Rows a later step fills (web/15, §8.16.5).
const VOICE_FIELD_ROWS: { name: string; ink: string; ground: string }[] = [];

describe("surface x ink loop (§2.1.1)", () => {
  const paper = [c.paper0, c.paper1, c.paper2, c.paper3, c.paper4];
  const grades = [c.moodRomantic, c.moodAction, c.moodComedy, c.moodHorror, c.moodSliceOfLife, c.moodFantasy];
  const plain = [...paper, ...grades, c.ambientFallbackTint, c.groundInk, c.groundSlate];
  const washOf = (wash: string) => [c.paper0, c.paper1, c.paper2, c.paper3].map((p) => flatBg(wash, p));
  function flatBg(fg: string, bg: string) { const o = over(rgb(fg), rgb(bg)); return `#${[o.r, o.g, o.b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("")}`; }
  const stockPages: [string, string, string][] = [
    [c.stockNitratePage, c.stockNitrateInk, c.stockNitrateMuted], [c.stockInkPage, c.stockInkInk, c.stockInkMuted],
    [c.stockSepiaNightPage, c.stockSepiaNightInk, c.stockSepiaNightMuted], [c.stockDuskPage, c.stockDuskInk, c.stockDuskMuted],
    [c.stockMossPage, c.stockMossInk, c.stockMossMuted], [c.stockRosewoodPage, c.stockRosewoodInk, c.stockRosewoodMuted],
  ];
  const inks = { ink60: c.ink60, ink80: c.ink80, ink100: c.ink100, spot: c.spot, set: c.set, info: c.info, proof: c.proof };
  it("every text ink clears 4.5:1 on every raised and plain ground (scope remaps applied)", () => {
    for (const g of plain) for (const [name, ink] of Object.entries(inks)) {
      expect(contrastBetween(ink, g), `${name} on ${g}`).toBeGreaterThanOrEqual(4.5);
    }
    // ink.45 only on paper.0; on raised grounds it is remapped to ink.60, on wash grounds to ink.80
    expect(contrastBetween(c.ink45, c.paper0)).toBeGreaterThanOrEqual(4.5);
    for (const g of plain.slice(1)) expect(contrastBetween(c.ink60, g), `raised ink45 on ${g}`).toBeGreaterThanOrEqual(4.5);
  });
  it("wash grounds (spot.wash, proof.wash over paper.0-3) with the wash scope remap", () => {
    // spot.wash carries neutral ink on top; proof.wash carries neutral ink and the proof text of an error row
    const neutral = { ink60: c.ink80, ink80: c.ink80, ink100: c.ink100 };
    for (const g of washOf(c.spotWash)) for (const [name, ink] of Object.entries({ ...neutral, spot: c.spot })) {
      expect(contrastBetween(ink, g), `${name} on spot.wash ${g}`).toBeGreaterThanOrEqual(4.5);
    }
    for (const g of washOf(c.proofWash)) for (const [name, ink] of Object.entries({ ...neutral, proof: c.proof })) {
      expect(contrastBetween(ink, g), `${name} on proof.wash ${g}`).toBeGreaterThanOrEqual(4.5);
    }
  });
  it("the six fixed stock pages carry their own ink and muted", () => {
    for (const [page, ink, muted] of stockPages) {
      expect(contrastBetween(ink, page)).toBeGreaterThanOrEqual(4.5);
      expect(contrastBetween(muted, page)).toBeGreaterThanOrEqual(4.5);
    }
  });
  it("ink.100 on the twelve avatar fields", () => {
    const fields = [c.avatarViolet, c.avatarCyan, c.avatarRose, c.avatarAmber, c.avatarEmerald, c.avatarEmber, c.avatarBlade, c.avatarPhantom, c.avatarArcane, c.avatarLunar, c.avatarStar, c.avatarReader];
    expect(fields).toHaveLength(12);
    for (const f of fields) expect(contrastBetween(c.ink100, f), f).toBeGreaterThanOrEqual(4.5);
  });
  it("VOICE_FIELD_ROWS is empty until web/15", () => {
    for (const r of VOICE_FIELD_ROWS) expect(contrastBetween(r.ink, r.ground), r.name).toBeGreaterThanOrEqual(4.5);
  });
});

// (component, ink, black alpha at the text line, min ratio): over #FFFFFF and #F5F547 (§2.1.4). Later steps append rows.
const OVER_ART: { name: string; ink: string; alpha: number; min?: number }[] = [
  { name: "ink.100 minimum", ink: c.ink100, alpha: 0.6 },
  { name: "ink.80 minimum", ink: c.ink80, alpha: 0.68 },
  { name: "spot minimum", ink: c.spot, alpha: 0.66 },
  { name: "set minimum", ink: c.set, alpha: 0.7 },
  { name: "ink.60 minimum", ink: c.ink60, alpha: 0.82 },
  { name: "proof minimum", ink: c.proof, alpha: 0.84 },
  { name: "on-art fill ink.100", ink: c.ink100, alpha: 0.64 },
  { name: "running head ink.60", ink: c.ink60, alpha: 0.88 },
  { name: "running head spot", ink: c.spot, alpha: 0.88 },
  { name: "running head ink.100", ink: c.ink100, alpha: 0.88 },
  { name: "folio bar ink.60", ink: c.ink60, alpha: 0.9 },
  { name: "folio bar spot", ink: c.spot, alpha: 0.9 },
  { name: "folio bar ink.100", ink: c.ink100, alpha: 0.9 },
  { name: "badge ink.45", ink: c.ink45, alpha: 1 },
  { name: "badge ink.100", ink: c.ink100, alpha: 1 },
];

describe("over-art table (§2.1.4)", () => {
  for (const art of ["#FFFFFF", "#F5F547"]) {
    it(`reaches 4.5:1 over ${art}`, () => {
      for (const row of OVER_ART) {
        const ground = over({ r: 0, g: 0, b: 0, a: row.alpha }, rgb(art));
        const hex = `#${[ground.r, ground.g, ground.b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("")}`;
        expect(contrastBetween(row.ink, hex), `${row.name} over ${art}`).toBeGreaterThanOrEqual(row.min ?? 4.5);
      }
    });
  }
});
void flat;
