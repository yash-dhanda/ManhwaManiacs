import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "../../design/tokens");
export function token(skin, key) {
  let n = JSON.parse(readFileSync(join(root, `${skin}.json`), "utf8"));
  for (const part of key.split(".")) {
    if (n == null || typeof n !== "object" || !(part in n)) throw new Error(`token ${skin}:${key} missing`);
    n = n[part];
  }
  if (n && typeof n === "object") {
    if (!("_" in n)) throw new Error(`token ${skin}:${key} has no _ value`);
    n = n._;
  }
  return n;
}
