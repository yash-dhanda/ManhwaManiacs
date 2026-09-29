import {
  Archivo,
  Bodoni_Moda,
  IBM_Plex_Mono,
  Newsreader,
  Noto_Sans_JP,
  Noto_Sans_KR,
  Noto_Sans_SC,
  Noto_Serif_JP,
  Noto_Serif_KR,
  Noto_Serif_SC,
} from "next/font/google";

export const bodoni = Bodoni_Moda({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "block", preload: false, variable: "--mm-font-display" });
export const archivo = Archivo({ subsets: ["latin", "latin-ext"], axes: ["wdth"], display: "swap", preload: false, variable: "--mm-font-grotesk" });
export const newsreader = Newsreader({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-newsreader" });
export const plexMono = IBM_Plex_Mono({ subsets: ["latin", "latin-ext"], weight: ["400", "500", "600"], display: "swap", preload: false, variable: "--mm-font-folio" });

export const notoSerifKr = Noto_Serif_KR({ display: "swap", preload: false, variable: "--mm-font-noto-serif-kr" });
export const notoSerifJp = Noto_Serif_JP({ display: "swap", preload: false, variable: "--mm-font-noto-serif-jp" });
export const notoSerifSc = Noto_Serif_SC({ display: "swap", preload: false, variable: "--mm-font-noto-serif-sc" });
export const notoSansKr = Noto_Sans_KR({ display: "swap", preload: false, variable: "--mm-font-noto-sans-kr" });
export const notoSansJp = Noto_Sans_JP({ display: "swap", preload: false, variable: "--mm-font-noto-sans-jp" });
export const notoSansSc = Noto_Sans_SC({ display: "swap", preload: false, variable: "--mm-font-noto-sans-sc" });

/** CJK display titles drop italic and tracking, wght 700, one size down (§3.1). next/font hashes family names, so reference the variables. */
export const cjkDisplayFamily = "var(--mm-font-display), var(--mm-font-noto-serif-kr), var(--mm-font-noto-serif-jp), var(--mm-font-noto-serif-sc), serif";
export const cjkUiFamily = "var(--mm-font-grotesk), var(--mm-font-noto-sans-kr), var(--mm-font-noto-sans-jp), var(--mm-font-noto-sans-sc), sans-serif";

export const coreFonts = [bodoni, archivo, newsreader, plexMono, notoSerifKr, notoSerifJp, notoSerifSc, notoSansKr, notoSansJp, notoSansSc];
