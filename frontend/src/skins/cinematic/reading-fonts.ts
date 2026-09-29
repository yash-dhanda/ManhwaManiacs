import { Atkinson_Hyperlegible_Next, Literata, Source_Serif_4 } from "next/font/google";

// preload: false means no request until rendered text uses the face. Their
// variables sit on <html> so Hyperlegible text can swap --mm-font-text anywhere.
export const literata = Literata({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-literata" });
export const sourceSerif = Source_Serif_4({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-source-serif" });
export const atkinson = Atkinson_Hyperlegible_Next({ style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-atkinson" });

export const readingFonts = [literata, sourceSerif, atkinson];
