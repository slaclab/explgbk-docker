#!/bin/bash
# Smoke test for the dev logbook: replays the Airflow (cryo-daq) call sequence
# against a dedicated test experiment, writing only to cryoem-logbook-dev.
#
# Usage: bash smoke-test.sh [experiment_name]
# Needs the dev cryo-daq password in $CRYO_DAQ_PW_FILE (default ~/.cryoem-dev-cryo-daq.pw).
# The password is passed to curl on stdin (-K -), never on the command line.
set -u

BASE=${BASE:-https://cryoem-logbook-dev.slac.stanford.edu/cryoem-data}
EXP=${1:-$(date -u +%Y%m%d)-ZZSMOKE01}
RUN=FoilHole_smoke_Data_0001
INSTRUMENT=${INSTRUMENT:-TEM1}
PW=$(cat "${CRYO_DAQ_PW_FILE:-$HOME/.cryoem-dev-cryo-daq.pw}")

case "$BASE" in
  *cryoem-logbook-dev*) ;;
  *) echo "Refusing to run against $BASE (dev only)"; exit 1 ;;
esac

call() {
  local method=$1 path=$2 data=${3:-} args=()
  [ -n "$data" ] && args=(--data-binary "$data")
  echo "== $method $path"
  printf 'user = "cryo-daq:%s"\n' "$PW" \
    | curl -s -K - -X "$method" -H 'Content-Type: application/json' \
        "${args[@]}" "$BASE$path" | head -c 600
  echo
}

get() {
  printf 'user = "cryo-daq:%s"\n' "$PW" | curl -s -K - "$BASE$1"
}

NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
END=$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%S.000Z)

EXP_INFO=$(cat <<JSON
{"instrument": "$INSTRUMENT",
 "start_time": "$NOW",
 "end_time": "$END",
 "leader_account": "ryanw",
 "contact_info": "Ryan Waldheim (ryanw@slac.stanford.edu)",
 "description": "Dev smoke test of the prod-repro logbook. Safe to delete."}
JSON
)
# Build a sample that passes the site's sample modal_params: every required key
# present, numeric types numeric. Values are placeholders.
SAMPLE=$(get "/lgbk/get_modal_param_definitions?modal_type=samples" | python3 -c '
import json, sys
defs = json.load(sys.stdin).get("value") or {}
params = {}
for p in defs.get("params", []):
    if not p.get("required"):
        continue
    t = p.get("param_type", "string")
    if t in ("int", "float"):
        v = 0
    elif p.get("options"):
        v = p["options"][0]
    elif t == "bool":
        v = False
    else:
        v = "smoke"
    params[p["param_name"]] = v
print(json.dumps({"name": "smoke1", "description": "smoke test sample", "params": params}))
')
FILES="[{\"path\": \"/smoke/$RUN.tiff\", \"run_num\": \"$RUN\", \"size\": 0}]"

echo "Experiment: $EXP  run: $RUN  instrument: $INSTRUMENT"
call POST "/lgbk/ws/register_new_experiment?experiment_name=$EXP" "$EXP_INFO"
call POST "/lgbk/$EXP/ws/create_update_sample?sample_name=smoke1" "$SAMPLE"
call POST "/lgbk/$EXP/ws/make_sample_current?sample_name=smoke1"
call GET  "/lgbk/$EXP/ws/current_sample_name"
call GET  "/lgbk/$EXP/ws/samples"
call POST "/run_control/$EXP/ws/start_run?run_num=$RUN" "{\"start_time\": \"$NOW\"}"
call POST "/run_control/$EXP/ws/add_run_params?run_num=$RUN" '{"smoke_param": "1"}'
call POST "/run_control/$EXP/ws/end_run?run_num=$RUN" '{}'
call POST "/lgbk/$EXP/ws/register_file" "$FILES"
call GET  "/lgbk/$EXP/ws/runs"

# image_count stopgap: read-modify-write of the sample through create_update_sample.
# An update replaces the whole params object, so send back everything plus image_count.
# Drop "current", which get_samples adds and which would otherwise be saved.
UPDATE=$(get "/lgbk/$EXP/ws/samples" | python3 -c '
import json, sys
s = [x for x in json.load(sys.stdin)["value"] if x["name"] == "smoke1"][0]
s.pop("current", None)
s.setdefault("params", {})["image_count"] = 42
print(json.dumps(s))
')
call POST "/lgbk/$EXP/ws/create_update_sample?sample_name=smoke1" "$UPDATE"
echo "== image_count after update"
get "/lgbk/$EXP/ws/samples" | python3 -c '
import json, sys
s = [x for x in json.load(sys.stdin)["value"] if x["name"] == "smoke1"][0]
print("image_count =", s["params"].get("image_count"), " current =", s.get("current"))
'
