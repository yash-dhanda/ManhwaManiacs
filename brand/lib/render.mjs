import { Resvg } from "@resvg/resvg-js";
import sharp from "sharp";

export function svgToPng(svg, { width, height, background } = {}) {
  const opts = { font: { loadSystemFonts: false } };
  if (width) opts.fitTo = { mode: "width", value: width };
  if (background) opts.background = background;
  return Buffer.from(new Resvg(svg, opts).render().asPng());
}
export const toOpaquePng = (png, bg = "#000000") =>
  sharp(png).flatten({ background: bg }).removeAlpha().toColourspace("srgb").png({ compressionLevel: 9 }).toBuffer();
export const toWebp = (png, { quality = 82 } = {}) => sharp(png).webp({ quality, effort: 6 }).toBuffer();
export const resize = (png, w, h = w) => sharp(png).resize(w, h, { kernel: "lanczos3" }).png({ compressionLevel: 9 }).toBuffer();
