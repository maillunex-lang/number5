#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="${1:-}"
if [[ -z "$VER" ]]; then
  VER="$(python3 -c "import json; print(json.load(open('$ROOT/content/packages/active.json'))['version'])")"
fi
DIR="$ROOT/content/packages/$VER"
echo "Validating package $VER at $DIR"
test -d "$DIR"
REQUIRED=(manifest.json hub.json campaign.json heroes.json battle_modes.json features.json theme.json shell.json strings.json motion.json assets.json)
for f in "${REQUIRED[@]}"; do
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
theme = json.loads((d/"theme.json").read_text())
shell = json.loads((d/"shell.json").read_text())
strings = json.loads((d/"strings.json").read_text())
motion = json.loads((d/"motion.json").read_text())
assets = json.loads((d/"assets.json").read_text())
assert hub.get("buildings"), "hub.buildings required"
assert camp.get("stages"), "campaign.stages required"
assert heroes.get("heroes"), "heroes.heroes required"
assert modes.get("portals"), "battle_modes.portals required"
assert "shop_offers" in feat
assert theme.get("palette"), "theme.palette required"
assert shell.get("bottom_nav", {}).get("tabs"), "shell tabs required"
assert strings.get("entries"), "strings.entries required"
assert "transition_ms" in motion
assert isinstance(assets.get("items"), list)
print("Semantic checks OK (schema 2 combine)")
PY
echo "PASS $VER"
