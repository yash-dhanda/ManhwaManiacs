import { existsSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import manifest from "./manifest";

describe("web app manifest", () => {
  const m = manifest();
  it("has exactly the Cinematic 12.3 fields", () => {
    expect(m).toEqual({
      id: "/",
      name: "ManhwaManiacs",
      short_name: "Maniacs",
      description: "Every source. One shelf.",
      start_url: "/",
      scope: "/",
      display: "standalone",
      background_color: "#000000",
      theme_color: "#000000",
      icons: [
        { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
        { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
        { src: "/icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
      ],
    });
  });
  it("has no orientation lock", () => {
    expect("orientation" in m).toBe(false);
  });
  it("points at icon files that exist", () => {
    for (const i of m.icons ?? []) expect(existsSync(join(process.cwd(), "public", i.src))).toBe(true);
  });
});
