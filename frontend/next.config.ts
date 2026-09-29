import type { NextConfig } from "next";

// In-network address of the backend the /api/* rewrite proxies to. In Docker
// this is the private `backend` service; in local dev it's the dev backend.
const BACKEND_INTERNAL_URL =
  process.env.BACKEND_INTERNAL_URL ?? "http://127.0.0.1:8000";

const nextConfig: NextConfig = {
  // Emit a self-contained server bundle (.next/standalone/server.js) for the
  // production Docker image.
  output: "standalone",

  // Same-origin API: the browser calls /api/*, and Next proxies it to the
  // backend server-side. This keeps the backend off the public edge (only the
  // frontend is exposed) and sidesteps CORS entirely. The backend serves its
  // routes at the root, so /api/sources -> {backend}/sources and, critically,
  // /api/health -> {backend}/health (the health contract deploy.sh + Caddy probe).
  // `/` → `/library` for the legacy skin only. Cinematic and Glass render their
  // own Tonight at `/`, so Next skips this redirect when either skin cookie
  // (`mm-skin`, the device mirror, or `mm-skin-debug`, the preview) names one of
  // them. A 307, answered before any React runs. release/00 deletes redirects().
  async redirects() {
    return [
      {
        source: "/",
        destination: "/library",
        permanent: false,
        missing: [
          { type: "cookie", key: "mm-skin", value: "(cinematic|glass)" },
          { type: "cookie", key: "mm-skin-debug", value: "(cinematic|glass)" },
        ],
      },
    ];
  },

  // How long the /api rewrite waits on the backend before answering 500 for
  // it. Next's default is 30 s, and an AI suggestion takes ~40 s or more: the
  // backend finished, DeepSeek charged the day's allowance, and the reader got
  // "Couldn't suggest anything" -- every retry paid again. It is an idle
  // timeout, so a streamed response is unaffected. It must stay above the
  // suggestion call's whole deadline (backend/services/suggestion_service.py,
  // TIMEOUT_SECONDS plus deepseek_client's 2 s pause before its retry).
  experimental: {
    proxyTimeout: 120_000,
    // Same-document view transitions for route changes (cinematic §15.2); off
    // by default in Next 16.2.
    viewTransition: true,
    optimizePackageImports: ["@phosphor-icons/react"],
  },

  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${BACKEND_INTERNAL_URL}/:path*`,
      },
    ];
  },

  // The service worker and the policy it imports must never be answered from
  // the HTTP cache. A worker the browser cannot see has changed is a worker
  // that keeps serving an old app shell, which is the one failure mode of this
  // whole feature that a user cannot get out of on their own.
  //
  // `Service-Worker-Allowed: /` lets /sw.js claim the whole origin regardless
  // of where it is served from, and the offline fallback is revalidated for the
  // same reason as the worker: it is the page shown when everything else failed.
  async headers() {
    return [
      {
        source: "/:path(sw.js|sw-policy.js|offline-fallback.html)",
        headers: [
          { key: "Cache-Control", value: "no-cache, must-revalidate" },
          { key: "Service-Worker-Allowed", value: "/" },
        ],
      },
    ];
  },

  // Covers and reader pages proxy through the backend on the SAME origin
  // (`/api/**`), so the `next/image` optimizer never needs a remotePatterns
  // entry for them — and in practice they render with `unoptimized` anyway
  // (already-sized JPEG/WebP from a proxy). These entries exist only for the
  // few dev/prod cases where an absolute backend URL reaches `next/image`.
  images: {
    remotePatterns: [
      {
        protocol: "http",
        hostname: "127.0.0.1",
        port: "8000",
        pathname: "/**",
      },
      {
        protocol: "http",
        hostname: "localhost",
        port: "8000",
        pathname: "/**",
      },
      {
        protocol: "https",
        hostname: "manhwamaniacs.xyz",
        pathname: "/**",
      },
    ],
  },
};

export default nextConfig;
