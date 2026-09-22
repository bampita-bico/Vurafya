#!/usr/bin/env bash
# Quick API smoke test — run while API is on :8000
set -euo pipefail
BASE="${1:-http://127.0.0.1:8000/api/v1}"

pass() { echo "  OK  $1"; }
fail() { echo "  FAIL $1"; exit 1; }

echo "=== Vurafya API smoke test ==="
echo "Base: $BASE"
echo

code=$(curl -s -o /tmp/vf_health.json -w "%{http_code}" "${BASE%/api/v1}/health")
[[ "$code" == "200" ]] && pass "health ($code)" || fail "health ($code)"

code=$(curl -s -o /tmp/vf_demo.json -w "%{http_code}" -X POST "$BASE/auth/demo-login" -H 'Content-Type: application/json')
[[ "$code" == "200" ]] && pass "demo-login ($code)" || fail "demo-login ($code)"

TOKEN=$(python3 -c "import json; print(json.load(open('/tmp/vf_demo.json'))['access_token'])")

code=$(curl -s -o /tmp/vf_me.json -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE/users/me")
[[ "$code" == "200" ]] && pass "users/me ($code)" || fail "users/me ($code)"

code=$(curl -s -o /tmp/vf_food.json -w "%{http_code}" "$BASE/nutrition/foods/search?q=matoke")
[[ "$code" == "200" ]] && pass "food search ($code)" || fail "food search ($code)"

code=$(curl -s -o /tmp/vf_dash.json -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE/nutrition/dashboard/daily")
[[ "$code" == "200" ]] && pass "nutrition dashboard ($code)" || fail "nutrition dashboard ($code)"

FOOD_ID=$(python3 -c "import json; print(json.load(open('/tmp/vf_food.json'))['items'][0]['id'])")
code=$(curl -s -o /tmp/vf_meal.json -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  "$BASE/nutrition/meals" -d "{\"meal_type\":\"lunch\",\"components\":[{\"food_id\":$FOOD_ID,\"quantity_grams\":100}]}")
[[ "$code" == "200" ]] && pass "log meal ($code)" || fail "log meal ($code)"

code=$(curl -s -o /tmp/vf_stab.json -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE/engine/stability")
[[ "$code" == "200" ]] && pass "engine stability ($code)" || fail "engine stability ($code)"

echo
echo "All checks passed."
