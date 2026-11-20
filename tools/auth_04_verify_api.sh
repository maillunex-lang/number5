#!/usr/bin/env bash
# AUTH-04 API: register → me → login → logout revoke → guest link → login linked
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
BASE="${BASE%/}"
EMAIL="auth04-$(date +%s)@example.com"
PASS="password-ok-12"

echo "== health =="
curl -fsS "$BASE/api/v1/health" | tee /tmp/auth04-health.json
python3 -c 'import json; d=json.load(open("/tmp/auth04-health.json")); assert d.get("ok") is True'

echo "== register =="
REG=$(curl -fsS -X POST -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  "$BASE/api/v1/auth/register")
echo "$REG" | tee /tmp/auth04-reg.json >/dev/null
TOK=$(python3 -c 'import json; d=json.load(open("/tmp/auth04-reg.json")); assert d.get("is_guest") is False; print(d["access_token"])')

echo "== me =="
ME=$(curl -fsS -H "Authorization: Bearer $TOK" "$BASE/api/v1/auth/me")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d.get("is_guest") is False; assert d.get("email")' "$ME"

echo "== login =="
LOGIN=$(curl -fsS -X POST -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  "$BASE/api/v1/auth/login")
TOK2=$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(d["access_token"])' "$LOGIN")

echo "== logout =="
curl -fsS -X POST -H "Authorization: Bearer $TOK2" "$BASE/api/v1/auth/logout" >/dev/null
CODE=$(curl -s -o /tmp/auth04-revoked.json -w "%{http_code}" -H "Authorization: Bearer $TOK2" "$BASE/api/v1/auth/me")
test "$CODE" = "401"

echo "== guest link =="
GTOK=$(curl -fsS -X POST "$BASE/api/v1/auth/guest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
LEMAIL="link-$(date +%s)@example.com"
curl -fsS -X POST -H "Authorization: Bearer $GTOK" -H "Content-Type: application/json" \
  -d "{\"email\":\"$LEMAIL\",\"password\":\"$PASS\"}" \
  "$BASE/api/v1/auth/link" >/dev/null
ME2=$(curl -fsS -H "Authorization: Bearer $GTOK" "$BASE/api/v1/auth/me")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d.get("is_guest") is False' "$ME2"
curl -fsS -X POST -H "Content-Type: application/json" \
  -d "{\"email\":\"$LEMAIL\",\"password\":\"$PASS\"}" \
  "$BASE/api/v1/auth/login" >/dev/null

echo "AUTH_04_VERIFY_API_OK base=$BASE email=$EMAIL"
