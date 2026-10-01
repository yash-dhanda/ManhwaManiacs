#version 460 core
#include <flutter/runtime_effect.glsl>

// Rain on glass (glass 9.4.2): up to 10 droplets refract the backdrop of a reader capsule. Used as `ImageFilter.shader` inside a
// `BackdropFilter`, so the first uniform is the size of the filter input (set by the engine) and the first sampler receives it.
//
// Uniform order matters (the Dart side sets floats by index):
//   0-1   uSize    the filter input in device pixels (engine)
//   2     uTime    seconds, a faint shimmer on the specular dots
//   3-32  uDrops   10 x (x, y, radius) in the same device-pixel space as FlutterFragCoord; radius 0 means no drop
//   33    uLight   the live light angle in radians (glass 2.1.9): where each drop's specular dot sits
uniform vec2 uSize;
uniform float uTime;
uniform vec3 uDrops[10];
uniform float uLight;
uniform sampler2D uBackdrop;

out vec4 fragColor;

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 offset = vec2(0.0);
  float spec = 0.0;
  // The light angle is measured counter-clockwise from +x with y up, so the screen y is flipped.
  vec2 toLight = vec2(cos(uLight), -sin(uLight));
  for (int i = 0; i < 10; i++) {
    vec3 d = uDrops[i];
    if (d.z <= 0.0) {
      continue;
    }
    vec2 p = frag - d.xy;
    float r = length(p);
    if (r < d.z) {
      // A hemispherical lens: the displacement is 3 px at the centre and falls to 0 at the rim.
      float t = r / d.z;
      vec2 dir = r > 0.001 ? -p / r : vec2(0.0, 1.0);
      offset += dir * 3.0 * (1.0 - t);
    }
    // A 1 px rgba(255,255,255,0.35) dot on the rim at the light's side.
    float dot1 = length(frag - (d.xy + toLight * d.z * 0.6));
    spec = max(spec, 0.35 * (1.0 - smoothstep(0.5, 1.5, dot1)));
  }
  vec2 uv = (frag + offset) / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  vec4 c = texture(uBackdrop, uv);
  spec *= 0.92 + 0.08 * sin(uTime * 2.0);
  fragColor = vec4(c.rgb + vec3(spec) * c.a, c.a);
}
