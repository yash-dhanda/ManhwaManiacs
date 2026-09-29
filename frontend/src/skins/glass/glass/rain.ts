import { isGlassReduced } from "../motion";

export interface Drop { x: number; y: number; vy: number; r: number; phase: number; t: number }
export interface RainBounds { w: number; h: number }

const RUN_S = 4;
const WOBBLE = 0.15;
const WOBBLE_PERIOD_S = 1.2;

/** Constant acceleration so a droplet crosses height H in 4 s: a = 2H / (4 s)^2. */
export const rainAcceleration = (h: number) => (2 * h) / RUN_S ** 2;

export function spawnDrop(b: RainBounds, rand: () => number = Math.random): Drop {
  const r = 3 + rand() * 3;
  return { x: rand() * b.w, y: -r, vy: 0, r, phase: rand() * Math.PI * 2, t: 0 };
}

/** Advance one droplet by dt seconds (pure): gravity down, lateral wobble dx/dt = 0.15 x dy/dt x sin(2pi t / 1.2 s + phase), respawn at the top. */
export function rainStep(d: Drop, dt: number, b: RainBounds, rand: () => number = Math.random): Drop {
  const t = d.t + dt;
  const vy = d.vy + rainAcceleration(b.h) * dt;
  const y = d.y + vy * dt;
  const x = d.x + WOBBLE * vy * Math.sin((2 * Math.PI * t) / WOBBLE_PERIOD_S + d.phase) * dt;
  return y - d.r > b.h ? spawnDrop(b, rand) : { ...d, t, vy, y, x };
}

/** 16 x 16 hemisphere displacement tile (R, G encode the inward push, neutral 128 outside the disc). Browser only. */
function hemisphereTile(): string {
  const c = document.createElement("canvas");
  c.width = c.height = 16;
  const img = new ImageData(16, 16);
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    const nx = (x - 7.5) / 8, ny = (y - 7.5) / 8, d = Math.hypot(nx, ny), o = (y * 16 + x) * 4;
    const m = d < 1 ? Math.sin((d * Math.PI) / 2) : 0;
    img.data[o] = 128 - (d > 0 ? (nx / d) * m * 127 : 0);
    img.data[o + 1] = 128 - (d > 0 ? (ny / d) * m * 127 : 0);
    img.data[o + 2] = 128;
    img.data[o + 3] = 255;
  }
  c.getContext("2d")!.putImageData(img, 0, 0);
  return c.toDataURL("image/png");
}

const SVG_NS = "http://www.w3.org/2000/svg";

/**
 * Rain on a glass group. Active only while told (the Rain soundscape, web/44) and while the host is visible.
 * Tier A ("liquid"): pass the host's <filter>; a second pass places one hemisphere tile per droplet after the
 * group's displacement (30 fps). Tier B: droplet spans moved by transform. It never adds a backdrop-filter element.
 */
export function createRain(host: HTMLElement, opts: { renderer: "liquid" | "frosted"; filter?: SVGFilterElement | null; rand?: () => number }) {
  const rand = opts.rand ?? Math.random;
  const layer = document.createElement("span");
  layer.className = "glass__rain";
  layer.setAttribute("aria-hidden", "true");
  let drops: Drop[] = [];
  let nodes: HTMLElement[] = [];
  let tiles: SVGFEImageElement[] = [];
  let raf = 0, last = 0, acc = 0, active = false, visible = true;
  let pass: SVGElement[] = [];

  const bounds = (): RainBounds => ({ w: host.offsetWidth, h: host.offsetHeight });

  const build = () => {
    const b = bounds();
    drops = Array.from({ length: 6 + Math.floor(rand() * 5) }, () => ({ ...spawnDrop(b, rand), y: rand() * b.h }));
    if (opts.renderer === "frosted" || !opts.filter) {
      nodes = drops.map(() => {
        const n = document.createElement("i");
        layer.appendChild(n);
        return n;
      });
    } else {
      const f = opts.filter;
      const last = f.lastElementChild as SVGElement | null;
      if (!last) return;
      last.setAttribute("result", "rainBase");
      const mk = <K extends keyof SVGElementTagNameMap>(tag: K) => document.createElementNS(SVG_NS, tag) as SVGElementTagNameMap[K];
      const flood = mk("feFlood");
      flood.setAttribute("flood-color", "rgb(128,128,128)");
      flood.setAttribute("result", "rainNeutral");
      const merge = mk("feMerge");
      merge.setAttribute("result", "rainMap");
      const nodeN = mk("feMergeNode");
      nodeN.setAttribute("in", "rainNeutral");
      merge.appendChild(nodeN);
      const href = hemisphereTile();
      tiles = drops.map(() => {
        const im = mk("feImage");
        im.setAttribute("href", href);
        im.setAttribute("preserveAspectRatio", "none");
        f.appendChild(im);
        return im;
      });
      // each tile needs a result name to merge
      tiles.forEach((im, i) => {
        im.setAttribute("result", `rainTile${i}`);
        const mn = mk("feMergeNode");
        mn.setAttribute("in", `rainTile${i}`);
        merge.appendChild(mn);
      });
      const disp = mk("feDisplacementMap");
      disp.setAttribute("in", "rainBase");
      disp.setAttribute("in2", "rainMap");
      disp.setAttribute("scale", "8");
      disp.setAttribute("xChannelSelector", "R");
      disp.setAttribute("yChannelSelector", "G");
      f.append(flood, merge, disp);
      pass = [flood, merge, disp];
      tiles.forEach((im) => im.remove());
      // tiles must precede the merge that names them
      tiles.forEach((im) => f.insertBefore(im, merge));
      f.insertBefore(flood, tiles[0] ?? merge);
    }
  };

  const draw = () => {
    drops.forEach((d, i) => {
      if (nodes[i]) {
        const n = nodes[i];
        n.style.cssText = `position:absolute;left:0;top:0;width:${d.r * 2}px;height:${d.r * 2}px;border-radius:50%;` +
          `background:radial-gradient(circle at 35% 35%, rgb(255 255 255 / 0.35), rgb(255 255 255 / 0.06) 60%, transparent 70%);` +
          `box-shadow:0 0 0 0.5px rgb(255 255 255 / 0.22);transform:translate(${d.x - d.r}px,${d.y - d.r}px)`;
      } else if (tiles[i]) {
        tiles[i].setAttribute("x", String(d.x - d.r));
        tiles[i].setAttribute("y", String(d.y - d.r));
        tiles[i].setAttribute("width", String(d.r * 2));
        tiles[i].setAttribute("height", String(d.r * 2));
      }
    });
  };

  const frame = (now: number) => {
    raf = requestAnimationFrame(frame);
    const dt = Math.min(0.1, (now - last) / 1000);
    last = now;
    acc += dt;
    if (acc < 1 / 30 || !visible) return; // 30 fps
    const b = bounds();
    drops = drops.map((d) => rainStep(d, acc, b, rand));
    acc = 0;
    draw();
  };

  const io = typeof IntersectionObserver === "function" ? new IntersectionObserver(([e]) => { visible = e.isIntersecting; }) : null;
  io?.observe(host);

  const stop = () => {
    active = false;
    cancelAnimationFrame(raf);
    layer.remove();
    pass.forEach((n) => n.remove());
    tiles.forEach((n) => n.remove());
    pass = []; tiles = []; nodes = []; drops = [];
    layer.replaceChildren();
  };

  return {
    /** Start or stop the rain. Off under reduced motion and solid glass. */
    setActive(on: boolean) {
      const solid = document.documentElement.dataset.solid === "on" || host.hasAttribute("data-forced-solid");
      if (on && !active && !isGlassReduced() && !solid) {
        active = true;
        host.appendChild(layer);
        build();
        last = performance.now();
        raf = requestAnimationFrame(frame);
      } else if (!on && active) stop();
    },
    destroy() { io?.disconnect(); stop(); },
  };
}
