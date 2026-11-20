#!/usr/bin/env bash
# Quick quality gate wrapper (no new dependencies).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== check_repo_refs =="
python3 tools/check_repo_refs.py

VER="${1:-}"
if [[ -z "$VER" ]]; then
  VER="$(python3 -c "import json; print(json.load(open('content/packages/active.json'))['version'])")"
fi
echo "== validate_content_package $VER =="
tools/validate_content_package.sh "$VER"

echo "== go test =="
(cd server && go test ./...)

echo "OK: verify_project passed"
