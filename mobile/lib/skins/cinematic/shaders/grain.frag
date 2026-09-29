#version 460 core
#include <flutter/runtime_effect.glsl>

// Per-pixel Gaussian luminance noise on a 256 px tile (cinematic 15.2, 15.3).
// uOpacity folds the grain opacity into the alpha so it does not depend on how a
// backend treats Paint.color alpha for runtime-effect shaders.
uniform vec2 uSize;
uniform vec2 uOffset;
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

void main() {
  vec2 p = mod(floor(FlutterFragCoord().xy + uOffset), 256.0);
  float u1 = max(hash(p), 1e-4);
  float u2 = hash(p + vec2(17.0, 43.0));
  float n = clamp(0.5 + 0.25 * sqrt(-2.0 * log(u1)) * cos(6.28318530718 * u2), 0.0, 1.0);
  fragColor = vec4(n, n, n, 1.0) * uOpacity;
}
