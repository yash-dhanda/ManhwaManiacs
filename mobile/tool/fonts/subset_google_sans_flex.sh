#!/usr/bin/env bash
# Builds mobile/assets/fonts/GoogleSansFlexMM.ttf from GoogleSansFlex[GRAD,ROND,opsz,slnt,wdth,wght].ttf (glass §3.1).
# Usage: subset_google_sans_flex.sh <path to the source TTF>. Needs fonttools 4.66.0 in the venv below.
set -euo pipefail
SRC=${1:?usage: $0 <GoogleSansFlex[...].ttf>}
VENV=${FONTTOOLS_VENV:-/srv/manhwamaniacs/dev/design-ref/.venv-fonttools}
export PATH="$VENV/bin:$PATH"
OUT="$(cd "$(dirname "$0")/../.." && pwd)/assets/fonts/GoogleSansFlexMM.ttf"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
LIMIT=737280
fonttools varLib.instancer "$SRC" slnt=0 wdth=100 -o "$TMP/gsf.ttf"
BASE="U+0020-007E,U+00A0-00FF"
REST="U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212"
build() { pyftsubset "$TMP/gsf.ttf" --unicodes="$1" --layout-features='*' --output-file="$OUT"; }
build "$BASE,U+0100-017F,$REST"
if [ "$(stat -c %s "$OUT")" -gt "$LIMIT" ]; then
  echo "over budget with Latin Extended-A, dropping it" >&2
  build "$BASE,$REST"
fi
SIZE=$(stat -c %s "$OUT")
[ "$SIZE" -le "$LIMIT" ] || { echo "GoogleSansFlexMM.ttf is $SIZE bytes, over $LIMIT" >&2; exit 1; }
python3 - "$OUT" <<'PY'
import sys
from fontTools.ttLib import TTFont
f = TTFont(sys.argv[1])
axes = {a.axisTag for a in f["fvar"].axes}
assert axes == {"wght", "opsz", "ROND", "GRAD"}, axes
print("axes", sorted(axes))
PY
echo "GoogleSansFlexMM.ttf $SIZE bytes"
