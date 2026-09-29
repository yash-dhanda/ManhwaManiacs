// One naming function per target (shared/00 "Naming"). Keys are dotted token keys; a "_" part
// names the value of a key that also has children and drops out of every name.

const parts = (key) => key.split(".").filter((p) => p !== "_");
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);
const camel = (ps) => ps.flatMap((p) => p.split(/[_-]/)).filter(Boolean).map((w, i) => (i ? cap(w) : w.charAt(0).toLowerCase() + w.slice(1))).join("");

// Dart reserved words, built-in identifiers and contextual keywords (Dart 3 language spec).
export const DART_RESERVED = new Set(("abstract as assert async await base break case catch class const continue covariant default deferred do dynamic else enum export extends extension external factory false final finally for Function get hide if implements import in interface is late library mixin new null of on operator part required rethrow return sealed set show static super switch sync this throw true try type typedef var void when while with yield").split(" ").filter((w) => w !== "type"));

// Reserved words proper: illegal as any identifier (built-in identifiers such as `library` are fine
// as enum values and members).
export const DART_RESERVED_WORDS = new Set("assert break case catch class const continue default do else enum extends false final finally for if in is new null rethrow return super switch this throw true try var void while with".split(" "));

export const cssName = (key) => "--mm-" + parts(key).join("-").replace(/_/g, "-").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
export const twName = (key) => cssName(key).replace(/^--mm-/, "--");
export const dartField = (key) => camel(parts(key));
export const tsMember = (key) => camel(parts(key).slice(1));
export function dartStatic(key) {
  const name = camel(parts(key).slice(1));
  if (/^\d+$/.test(name)) return "s" + name;
  return DART_RESERVED.has(name) ? dartField(key) : name;
}
// Enum value for a dotted or kebab id (`tap.primary` → tapPrimary, `reading-manga` → readingManga).
export const enumName = (id) => camel(id.split("."));

// Leaves of a nested token group as [dottedKey, value]; isLeaf decides where to stop.
export function leaves(obj, isLeaf, prefix) {
  const out = [];
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith("_") && k !== "_") continue; // _comment
    const key = k === "_" ? prefix : `${prefix}.${k}`;
    if (isLeaf(v)) out.push([key, v]);
    else out.push(...leaves(v, isLeaf, key));
  }
  return out;
}
