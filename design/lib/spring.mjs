// Stdlib port of Motion's visual-duration spring (motion-dom 12.42.2: getSpringOptions, spring,
// generateLinearEasing; cinematic/DESIGN.md §2.8.4, §15.10 S13). The arithmetic follows motion-dom
// step for step so the output matches spring(ms / 1000, bounce).toString() byte for byte.
// Time t is in ms, as Motion's generator takes it.

function generator(ms, bounce) {
  const root = (2 * Math.PI) / ((ms / 1000) * 1.2);
  const stiffness = root * root;
  const damping = 2 * Math.min(1, Math.max(0.05, 1 - bounce)) * Math.sqrt(stiffness);
  const zeta = damping / (2 * Math.sqrt(stiffness));
  const w = Math.sqrt(stiffness) / 1000; // per ms
  let position, velocity; // velocity in units per second
  if (zeta < 1) {
    const wd = w * Math.sqrt(1 - zeta * zeta);
    const A = (zeta * w) / wd;
    const sinCoeff = zeta * w * A + wd;
    const cosCoeff = zeta * w - A * wd;
    position = (t) => 1 - Math.exp(-zeta * w * t) * (A * Math.sin(wd * t) + Math.cos(wd * t));
    velocity = (t) => Math.exp(-zeta * w * t) * (sinCoeff * Math.sin(wd * t) + cosCoeff * Math.cos(wd * t)) * 1000;
  } else {
    position = (t) => 1 - Math.exp(-w * t) * (1 + w * t);
    velocity = (t) => Math.exp(-w * t) * (w * w * t) * 1000;
  }
  // Motion's granular rest thresholds; at rest the generator returns the target exactly.
  return (t) => {
    const x = position(t);
    const done = Math.abs(velocity(t)) <= 0.01 && Math.abs(1 - x) <= 0.005;
    return { done, value: done ? 1 : x };
  };
}

export function springCss(ms, bounce) {
  const next = generator(ms, bounce);
  let T = 0;
  while (!next(T).done && T < 20000) T += 50;
  const n = Math.max(Math.round(T / 30), 2);
  const points = [];
  for (let i = 0; i < n; i++) points.push(Math.round(next(T * (i / (n - 1))).value * 10000) / 10000);
  return { ms: T, easing: `linear(${points.join(", ")})` };
}

export const motionSpring = (ms, bounce) => {
  const { ms: T, easing } = springCss(ms, bounce);
  return `${T}ms ${easing}`;
};
