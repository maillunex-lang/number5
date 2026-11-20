#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

base=/opt/lunex-afk
web=/var/www/rikagro-game/afkgame
state="$base/main-deploy"
repo="$state/source.git"
slug=maillunex-lang/number5
godot=/opt/game-tools/godot/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64
android_tools=/opt/android-sdk/build-tools/36.1.0

install -d -m 0700 "$state"
exec 9>"$state/deploy.lock"
flock -n 9 || exit 0
if [[ ! -d "$repo" ]]; then
    git init --bare "$repo"
fi
git --git-dir="$repo" fetch -q --no-tags "https://github.com/$slug.git" refs/heads/main:refs/heads/main
sha=$(git --git-dir="$repo" rev-parse refs/heads/main)
if [[ -f "$state/current" && $(cat "$state/current") == "$sha" ]]; then
    exit 0
fi
runs=$(runuser -u gamedev -- gh api "repos/$slug/actions/workflows/content-and-studio.yml/runs?branch=main&event=push&head_sha=$sha&per_page=1" --jq '.workflow_runs[0] | .conclusion // empty')
if [[ "$runs" != success ]]; then
    echo "Waiting for successful main checks for $sha (status: ${runs:-pending})"
    exit 0
fi

stage=$(mktemp -d "$state/stage.XXXXXXXX")
swaps=()
timer_paused=0
success=0
swap() {
    mv --exchange --no-copy -T "$1" "$2"
    swaps+=("$1" "$2")
}
finish() {
    local result=$?
    trap - EXIT
    set +e
    if (( ! success && timer_paused )); then
        for (( index=${#swaps[@]}-2; index>=0; index-=2 )); do
            mv --exchange --no-copy -T "${swaps[index]}" "${swaps[index+1]}" || result=1
        done
        systemctl restart lunex-afk-api.service lunex-afk-studio.service || result=1
    fi
    if (( timer_paused )); then
        systemctl start lunex-afk-cdn-sync.timer || result=1
    fi
    if (( ${#swaps[@]} == 0 )); then
        rm -rf -- "$stage"
    fi
    exit "$result"
}
trap finish EXIT

echo "Building $sha"
mkdir "$stage/app" "$stage/public-admin" "$stage/public-cdn"
git --git-dir="$repo" archive "$sha" | tar -x -C "$stage/app"
app="$stage/app"
cd "$app"
bash tools/verify_project.sh
(cd server && go build -o "$stage/lunex-api" ./cmd/api)
(cd admin-studio && npm ci --ignore-scripts --no-audit --no-fund && npm run build)
rsync -a admin-studio/dist/ "$stage/public-admin/"
version=$(python3 -c 'import json; print(json.load(open("content/packages/active.json"))["version"])')
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
apk_code=$((26 + $(git --git-dir="$repo" rev-list --first-parent --count "$sha")))
export GODOT_SILENCE_ROOT_WARNING=1
# Keep the preset version as a floor if the Android release version is bumped in Git.
apk_version=$(python3 - "$apk_code" <<'PY'
from pathlib import Path
import re, sys
p = Path("export_presets.cfg")
s = p.read_text()
m = re.search(r"^version/code=(\d+)$", s, re.M)
assert m
code = max(int(sys.argv[1]), int(m[1]))
p.write_text(s[:m.start(1)] + str(code) + s[m.end(1):])
print(re.search(r'^version/name="([^"]+)"$', s, re.M)[1])
PY
)
"$godot" --headless --editor --import >"$stage/godot-import.log" 2>&1
"$godot" --headless --path . --export-debug Android "$stage/latest.apk" >"$stage/android.log" 2>&1
if grep -E 'SCRIPT ERROR|Parse Error|(^| )ERROR:' "$stage/godot-import.log" "$stage/android.log"; then exit 1; fi
previous_apk="$web/download/latest.apk"
[[ -f "$previous_apk" ]] || previous_apk="$web/download/lunex-afk-online-v0.5.5-debug.apk"
signer() { "$android_tools/apksigner" verify --print-certs "$1" | awk '/certificate SHA-256 digest:/ { print $NF }'; }
old_signer=$(signer "$previous_apk")
[[ -n "$old_signer" && $(signer "$stage/latest.apk") == "$old_signer" ]]
"$android_tools/aapt2" dump badging "$stage/latest.apk" >"$stage/apk-metadata.txt" 2>/dev/null
new_code=$(sed -nE "s/^package:.*versionCode='([0-9]+)'.*/\1/p" "$stage/apk-metadata.txt")
old_code=$("$android_tools/aapt2" dump badging "$previous_apk" 2>/dev/null | sed -nE "s/^package:.*versionCode='([0-9]+)'.*/\1/p")
[[ "$new_code" =~ ^[0-9]+$ && "$old_code" =~ ^[0-9]+$ ]]
(( new_code > old_code ))

# Ignore a build superseded while compilation was running.
latest=$(git ls-remote "https://github.com/$slug.git" refs/heads/main | cut -f1)
[[ "$latest" == "$sha" ]] || exit 0

systemctl start lunex-afk-backup.service
systemctl stop lunex-afk-cdn-sync.timer
timer_paused=1
systemctl stop lunex-afk-cdn-sync.service
if [[ -f "$base/app/content/packages/publish_history.json" ]]; then
    cp -p "$base/app/content/packages/publish_history.json" "$app/content/packages/"
fi
rsync -a "$web/cdn/" "$stage/public-cdn/"
rsync -a --delete "$app/content/packages/$version/" "$stage/public-cdn/$version/"
cp "$app/content/packages/active.json" "$stage/public-cdn/active.json"
chmod -R a+rX "$stage/public-admin" "$stage/public-cdn"
cd "$base"
swap "$stage/app" "$base/app"
swap "$stage/lunex-api" "$base/lunex-api"
systemctl restart lunex-afk-api.service lunex-afk-studio.service
curl -fsS --retry 6 --retry-connrefused --retry-delay 1 --max-time 5 http://127.0.0.1:18084/api/v1/health | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] and d["store"]=="postgres" and d["db"]'
curl -fsS --retry 6 --retry-connrefused --retry-delay 1 --max-time 5 http://127.0.0.1:18788/api/health >/dev/null
swap "$stage/public-admin" "$web/admin"
swap "$stage/public-cdn" "$web/cdn"
curl -fsS --max-time 5 https://rikagro.ru/afkgame/cdn/active.json | python3 -c 'import json,sys; assert json.load(sys.stdin)["version"]==sys.argv[1]' "$version"
chmod 0644 "$stage/latest.apk"
if [[ -f "$web/download/latest.apk" ]]; then
    swap "$stage/latest.apk" "$web/download/latest.apk"
else
    mv -T "$stage/latest.apk" "$web/download/latest.apk"
fi
printf '%s\n' "$sha" >"$state/current.new"
mv -T "$state/current.new" "$state/current"
success=1
printf 'Published %s, APK %s (%s), content %s\n' "$sha" "$apk_version" "$new_code" "$version"

# Keep the original deployment and the latest rollback snapshot.
rollback="$state/rollback"
if [[ -d "$rollback" && ! -d "$state/original" ]]; then
    mv -T "$rollback" "$state/original"
elif [[ -d "$rollback" ]]; then
    rm -rf -- "$rollback"
fi
mv -T "$stage" "$rollback"
