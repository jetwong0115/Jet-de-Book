#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f package.json ]]; then
  exit 0
fi

if curl -sf --max-time 3 http://127.0.0.1:4000/ >/dev/null 2>&1; then
  exit 0
fi

exec npm run dev
