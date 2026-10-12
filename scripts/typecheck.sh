#!/usr/bin/env bash
# Typecheck every package with a tsconfig: the apps and the two shared libraries.
#   bash scripts/typecheck.sh             check all packages (CI: pnpm run typecheck)
#   bash scripts/typecheck.sh --changed   check only the packages that the staged files touch (pre-commit)
# A change under libraries/, or to a root config, checks all packages, because the apps import the libraries.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

ALL="apps/backend/tsconfig.json apps/orchestrator/tsconfig.json apps/commands/tsconfig.json apps/extension/tsconfig.json apps/frontend/tsconfig.json apps/sdk/tsconfig.json libraries/nestjs-libraries/tsconfig.lib.json libraries/react-shared-libraries/tsconfig.lib.json"

if [ "${1:-}" = "--changed" ]; then
  picked=""
  while IFS= read -r file; do
    case "$file" in
      libraries/*|package.json|pnpm-lock.yaml|tsconfig*.json|scripts/typecheck.sh) picked="$ALL" ;;
      apps/backend/*) picked="$picked apps/backend/tsconfig.json" ;;
      apps/orchestrator/*) picked="$picked apps/orchestrator/tsconfig.json" ;;
      apps/commands/*) picked="$picked apps/commands/tsconfig.json" ;;
      apps/extension/*) picked="$picked apps/extension/tsconfig.json" ;;
      apps/frontend/*) picked="$picked apps/frontend/tsconfig.json" ;;
      apps/sdk/*) picked="$picked apps/sdk/tsconfig.json" ;;
    esac
  done < <(git diff --cached --name-only)
  configs="$(printf '%s\n' $picked | sort -u)"
  if [ -z "$configs" ]; then
    echo "typecheck: no TypeScript package has staged changes"
    exit 0
  fi
else
  configs="$(printf '%s\n' $ALL | sort -u)"
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "typecheck: pnpm is required (see packageManager in package.json)"
  exit 1
fi

status=0
for config in $configs; do
  if pnpm exec tsc --noEmit -p "$config"; then
    echo "typecheck ok: $config"
  else
    echo "typecheck FAILED: $config"
    status=1
  fi
done
exit $status
