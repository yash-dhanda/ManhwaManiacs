import {
  Atkinson_Hyperlegible_Next,
  Google_Sans_Code,
  Google_Sans_Flex,
  Literata,
  Noto_Sans_JP,
  Noto_Sans_KR,
  Noto_Sans_SC,
} from "next/font/google";

export const googleSansFlex = Google_Sans_Flex({ subsets: ["latin"], axes: ["ROND", "GRAD", "opsz"], display: "swap", preload: false, variable: "--mm-font-sans" });
export const googleSansCode = Google_Sans_Code({ subsets: ["latin"], display: "swap", preload: false, variable: "--mm-font-mono" });
export const literata = Literata({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-serif" });
// Never preloaded: the server cannot know the profile's Legible text setting.
export const atkinson = Atkinson_Hyperlegible_Next({ subsets: ["latin"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-legible" });

export const notoSansKr = Noto_Sans_KR({ display: "swap", preload: false, variable: "--mm-font-noto-sans-kr" });
export const notoSansJp = Noto_Sans_JP({ display: "swap", preload: false, variable: "--mm-font-noto-sans-jp" });
export const notoSansSc = Noto_Sans_SC({ display: "swap", preload: false, variable: "--mm-font-noto-sans-sc" });

export const cjkFamily = "var(--mm-font-sans), var(--mm-font-noto-sans-kr), var(--mm-font-noto-sans-jp), var(--mm-font-noto-sans-sc), system-ui, sans-serif";

export const glassFonts = [googleSansFlex, googleSansCode, literata, atkinson, notoSansKr, notoSansJp, notoSansSc];
