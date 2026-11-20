#!/usr/bin/env bash
# Validates content package JSON files for the Godot client.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="${1:-}"
if [[ -z "$VER" ]]; then
  VER="$(python3 -c "import json; print(json.load(open('$ROOT/content/packages/active.json'))['version'])")"
fi
DIR="$ROOT/content/packages/$VER"
echo "Validating package $VER at $DIR"
test -d "$DIR"
for f in manifest.json hub.json campaign.json heroes.json battle_modes.json features.json; do
  test -f "$DIR/$f"
  python3 -c "import json; json.load(open('$DIR/$f')); print(' OK', '$f')"
done
python3 - <<PY
import json
from pathlib import Path
d = Path("$DIR")
hub = json.loads((d/"hub.json").read_text())
camp = json.loads((d/"campaign.json").read_text())
heroes = json.loads((d/"heroes.json").read_text())
modes = json.loads((d/"battle_modes.json").read_text())
feat = json.loads((d/"features.json").read_text())
assert hub.get("buildings"), "hub.buildings required"
assert camp.get("stages"), "campaign.stages required"
assert heroes.get("heroes"), "heroes.heroes required"
assert modes.get("portals"), "battle_modes.portals required"
assert "shop_offers" in feat
print("Semantic checks OK")
PY
echo "PASS $VER"
