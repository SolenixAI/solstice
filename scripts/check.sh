#!/usr/bin/env bash
# TypeScript only. Fails on any .js, .mjs or .cjs file that scripts/js-allowlist.txt does not name,
# and on any allowlist entry whose file no longer exists. CI runs it: .github/workflows/js-allowlist.yml.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

allow="$(grep -v -E '^[[:space:]]*(#|$)' scripts/js-allowlist.txt)"
status=0

offenders="$(git ls-files -co --exclude-standard | grep -E '\.(js|mjs|cjs)$' | grep -vxF "$allow" || true)"
if [ -n "$offenders" ]; then
  while IFS= read -r file; do
    echo "check: JavaScript file $file is not on scripts/js-allowlist.txt (the repo is TypeScript)"
  done <<< "$offenders"
  status=1
fi

while IFS= read -r entry; do
  [ -e "$entry" ] || { echo "check: scripts/js-allowlist.txt lists $entry, which does not exist (remove the line)"; status=1; }
done <<< "$allow"

if [ "$status" -eq 0 ]; then
  echo "check: JavaScript files ok ($(printf '%s\n' "$allow" | grep -c .) allowlisted)"
fi
exit "$status"
