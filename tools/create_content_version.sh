#!/usr/bin/env bash
# Clone an existing content package version to a new semver folder.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FROM="${1:-}"
TO="${2:-}"
if [[ -z "$FROM" || -z "$TO" ]]; then
  echo "Usage: $0 <from-version> <to-version>"
  echo "Example: $0 0.1.0 0.1.1"
  exit 1
fi
if [[ ! "$TO" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "to-version must be semver like 0.1.1"
  exit 1
fi
SRC="$ROOT/content/packages/$FROM"
DST="$ROOT/content/packages/$TO"
test -d "$SRC"
if [[ -e "$DST" ]]; then
  echo "Already exists: $DST"
  exit 1
fi
mkdir -p "$DST"
cp -a "$SRC"/. "$DST"/
python3 - <<PY
import json, datetime
from pathlib import Path
p = Path("$DST") / "manifest.json"
m = json.loads(p.read_text())
m["version"] = "$TO"
m["created_at"] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
m["updated_at"] = m["created_at"]
p.write_text(json.dumps(m, ensure_ascii=False, indent=2) + "\n")
print("Created", p.parent)
PY
echo "Next: edit JSON under $DST, then publish via Admin Studio or update active.json"
