#!/usr/bin/env bash
# Block up to 560 s until every id is done, then report. Used by implement.workflow.js waits.
# Usage: wait-ledger.sh <id>...   ids are step ids (web/12) or "signoffs".
LEDGER=/srv/manhwamaniacs/dev/redesign-integrated.txt
SIGNOFFS=/srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/signoffs.md

have() {
  if [ "$1" = signoffs ]; then
    for k in S1 S11 G6 G14; do grep -qE "^$k " "$SIGNOFFS" 2>/dev/null || return 1; done
  else
    grep -qF "$1 " "$LEDGER" 2>/dev/null && grep -qE "^$1 " "$LEDGER"
  fi
}

end=$((SECONDS + 560))
while :; do
  missing=()
  for id in "$@"; do have "$id" || missing+=("$id"); done
  [ ${#missing[@]} -eq 0 ] && { echo READY; exit 0; }
  [ $SECONDS -ge $end ] && break
  sleep 30
done
for id in "${missing[@]}"; do echo "MISSING $id"; done
exit 1
