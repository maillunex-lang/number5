#!/usr/bin/env bash
# H6 API contract check: start → GET reconnect → claim → claim replay → stage advance.
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
BASE="${BASE%/}"

echo "== health =="
curl -fsS "$BASE/api/v1/health" | tee /tmp/h6-health.json
python3 -c 'import json,sys; d=json.load(open("/tmp/h6-health.json")); assert d.get("ok") is True'

echo "== guest =="
TOK=$(curl -fsS -X POST "$BASE/api/v1/auth/guest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
AUTH="Authorization: Bearer $TOK"

echo "== battle start =="
BAT=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"stage_id":"CH01-01","idempotency_key":"h6-verify-start"}' \
  "$BASE/api/v1/battle/start")
echo "$BAT" | tee /tmp/h6-start.json >/dev/null
BID=$(python3 -c 'import json; d=json.load(open("/tmp/h6-start.json")); assert d.get("victory") is True; assert len(d.get("timeline") or [])>=3; print(d["battle_id"])')
echo "battle_id=$BID"

echo "== reconnect GET =="
GOT=$(curl -fsS -H "$AUTH" "$BASE/api/v1/battle/$BID")
python3 -c 'import json,sys; a=json.load(open("/tmp/h6-start.json")); b=json.loads(sys.argv[1]); assert a["battle_id"]==b["battle_id"]; assert len(a["timeline"])==len(b["timeline"])' "$GOT"

CLAIM_KEY="claim:$BID"
echo "== claim =="
C1=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
  -d "{\"idempotency_key\":\"$CLAIM_KEY\"}" \
  "$BASE/api/v1/battle/$BID/claim")
echo "$C1" | tee /tmp/h6-claim.json >/dev/null

echo "== claim replay =="
C2=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
  -d "{\"idempotency_key\":\"$CLAIM_KEY\"}" \
  "$BASE/api/v1/battle/$BID/claim")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d.get("replayed") is True' "$C2"

echo "== campaign =="
PROG=$(curl -fsS -H "$AUTH" "$BASE/api/v1/campaign/progress")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d.get("current_stage")!="CH01-01", d' "$PROG"

echo "H6_VERIFY_API_OK base=$BASE battle=$BID"
