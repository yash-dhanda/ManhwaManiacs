import type { MetadataRoute } from "next";

// Web app manifest per cinematic DESIGN.md 12.3 and 15.2. Skin-neutral: black, no orientation lock
// (landscape layouts must work when installed), no categories.
export default function manifest(): MetadataRoute.Manifest {
  return {
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
  };
}
