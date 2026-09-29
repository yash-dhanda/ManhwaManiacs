import type { CSSProperties } from "react";
import { notFound } from "next/navigation";
import { Icon as CinematicIcon } from "@/skins/cinematic/Icon";
import { cjkDisplayFamily } from "@/skins/cinematic/fonts";
import { ICON_ROLES as CINEMATIC_ROLES, type IconRole as CinematicRole } from "@/skins/cinematic/icons/roles.generated";
import { Icon as GlassIcon } from "@/skins/glass/Icon";
import { cjkFamily } from "@/skins/glass/fonts";
import { ICON_ROLES as GLASS_ROLES, type IconRole as GlassRole } from "@/skins/glass/icons/roles.generated";

// Proof surface only: 404 in production, linked from nowhere.
const CJK = "나 혼자만 레벨업 · 俺だけレベルアップな件 · 我独自升级";
const grid: CSSProperties = { display: "flex", flexWrap: "wrap", gap: 16, alignItems: "flex-end" };
const cell: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center", gap: 6, minWidth: 72 };
const mono = (c: string): CSSProperties => ({ font: '500 11px var(--mm-font-folio), monospace', color: c, opacity: 0.7 });

function Cinematic() {
  const ink = "#F3F0E8";
  const roles = Object.keys(CINEMATIC_ROLES) as CinematicRole[];
  return (
    <main style={{ background: "#000000", color: ink, padding: 32, display: "grid", gap: 24 }}>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-display)", fontStyle: "italic", fontSize: 72, fontVariationSettings: '"opsz" 72, "wght" 600' }}>ManhwaManiacs</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-grotesk)", fontSize: 13, fontVariationSettings: '"wdth" 62, "wght" 700', textTransform: "uppercase", letterSpacing: "0.16em" }}>NOW SHOWING</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-newsreader)", fontSize: 18, lineHeight: "28px" }}>The page turns and the city holds its breath.</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-folio)", fontWeight: 500 }}>CH 143 · P. 18 / 64</p>
      <p style={{ margin: 0, fontFamily: cjkDisplayFamily, fontWeight: 700, fontSize: 32 }}>{CJK}</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-literata)" }}>Literata: the reader sets this in long chapters.</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-source-serif)" }}>Source Serif 4: the reader sets this in long chapters.</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-atkinson)" }}>Atkinson Hyperlegible Next: the reader sets this in long chapters.</p>
      {([16, 20, 24, 32] as const).map((size) => (
        <section key={size} style={grid}>
          {roles.map((r) => (
            <div key={r} style={cell}>
              <CinematicIcon name={r} size={size} />
              <span style={mono(ink)}>{r}</span>
            </div>
          ))}
        </section>
      ))}
      <section style={grid}>
        {roles.map((r) => (
          <div key={r} style={cell}>
            <CinematicIcon name={r} size={24} filled />
            <span style={mono(ink)}>{r}</span>
          </div>
        ))}
      </section>
    </main>
  );
}

function Glass() {
  const ink = "#F2F2F7";
  const roles = Object.keys(GLASS_ROLES) as GlassRole[];
  const row = (label: string, render: (r: GlassRole) => React.ReactNode) => (
    <section style={{ display: "grid", gap: 8 }}>
      <span style={mono(ink)}>{label}</span>
      <div style={grid}>
        {roles.map((r) => (
          <div key={r} style={cell}>
            {render(r)}
            <span style={mono(ink)}>{r}</span>
          </div>
        ))}
      </div>
    </section>
  );
  return (
    <main style={{ background: "#000000", color: ink, padding: 32, display: "grid", gap: 24, fontFamily: "var(--mm-font-sans)" }}>
      {[300, 500, 800].map((w) =>
        [0, 100].map((rond) => (
          <p key={`${w}-${rond}`} style={{ margin: 0, fontSize: 32, fontVariationSettings: `"wght" ${w}, "ROND" ${rond}` }}>
            Read the next chapter · wght {w} · ROND {rond}
          </p>
        )),
      )}
      <p style={{ margin: 0, fontFamily: "var(--mm-font-mono)", fontSize: 14 }}>12:04 · 3.5×</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-serif)" }}>Literata: the reader sets this in long chapters.</p>
      <p style={{ margin: 0, fontFamily: "var(--mm-font-legible)" }}>Atkinson Hyperlegible Next: the reader sets this in long chapters.</p>
      <p style={{ margin: 0, fontFamily: cjkFamily }}>{CJK}</p>
      {row("rest 22", (r) => <GlassIcon name={r} />)}
      {row("active 22", (r) => <GlassIcon name={r} state="active" />)}
      {row("pressed 22", (r) => <GlassIcon name={r} state="pressed" />)}
      {row("ornamental 56", (r) => <GlassIcon name={r} size={56} tier="ornamental" />)}
      {row("dense 16", (r) => <GlassIcon name={r} size={16} tier="dense" />)}
    </main>
  );
}

export default async function SpecimenPage({ params }: { params: Promise<{ skin: string }> }) {
  if (process.env.NODE_ENV === "production") notFound();
  const { skin } = await params;
  return skin === "glass" ? <Glass /> : <Cinematic />;
}
