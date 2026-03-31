#!/bin/bash
#
# mongodump-by-db.sh
# Dumps each MongoDB database individually, connecting directly to rs0-0.
# Designed to run inside the mongodb-logic-backup pod in cryoem-logbook namespace.
#
# Usage:
#   ./mongodump-by-db.sh                          # dump all user databases
#   ./mongodump-by-db.sh mydb1 mydb2              # dump only specific databases
#
# Environment variables (override defaults):
#   MONGO_HOST    mongo host     (default: mongo-rs0-0.mongo-rs0)
#   MONGO_PORT    mongo port     (default: 27017)
#   MONGO_USER    username       (default: backup)
#   MONGO_PASS    password       (required)
#   MONGO_AUTH_DB auth database  (default: admin)
#   DUMP_ROOT     output dir     (default: /data/mongodump)
#   RETAIN_DAYS   days to keep   (default: 14)
#   GZIP          gzip output    (default: true)
#   PARALLEL      parallel cols  (default: 4)
#   VERBOSE       verbose output (default: true)

set -euo pipefail

# --- configuration -----------------------------------------------------------
MONGO_HOST="${MONGO_HOST:-mongo-rs0-0.mongo-rs0}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-backup}"
MONGO_PASS="${MONGO_PASS:-}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"
DUMP_ROOT="${DUMP_ROOT:-/data/mongodump}"
RETAIN_DAYS="${RETAIN_DAYS:-14}"
GZIP="${GZIP:-true}"
PARALLEL="${PARALLEL:-4}"
VERBOSE="${VERBOSE:-true}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DUMP_DIR="${DUMP_ROOT}/${TIMESTAMP}"

SKIP_DBS="admin|config|local"

# --- helpers ------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

# --- banner -------------------------------------------------------------------
log "========== mongodump-by-db starting =========="
log "  Host     : ${MONGO_HOST}:${MONGO_PORT}"
log "  User     : ${MONGO_USER}"
log "  Auth DB  : ${MONGO_AUTH_DB}"
log "  Dump root: ${DUMP_ROOT}"
log "  Retain   : ${RETAIN_DAYS} days"
log "  Gzip     : ${GZIP}"
log "  Parallel : ${PARALLEL}"
log "  Verbose  : ${VERBOSE}"
log "==============================================="

# --- pre-flight checks -------------------------------------------------------
log "Checking tools..."
command -v mongodump >/dev/null 2>&1 \
  && log "  mongodump: $(mongodump --version 2>&1 | head -1)" \
  || die "mongodump not found in PATH"

if command -v mongo >/dev/null 2>&1; then
  MONGOSH="mongo"
  log "  shell: $(mongo --version 2>&1 | head -1)"
else
  die "mongo shell not found in PATH"
fi

# --- password resolution ------------------------------------------------------
if [[ -z "${MONGO_PASS}" ]]; then
  die "MONGO_PASS not set. Run: env MONGO_PASS=xxx bash $0"
fi

# --- connection args (simple flag format) ------------------------------------
CONN_ARGS=(
  -u "${MONGO_USER}"
  -p "${MONGO_PASS}"
  --authenticationDatabase="${MONGO_AUTH_DB}"
  --host "${MONGO_HOST}"
  --port "${MONGO_PORT}"
)

# --- test connectivity --------------------------------------------------------
log "Testing TCP connectivity to ${MONGO_HOST}:${MONGO_PORT} ..."
if nc -z -w5 "${MONGO_HOST}" "${MONGO_PORT}" 2>/dev/null; then
  log "  TCP: OK"
else
  warn "  TCP: FAILED — host may be unreachable"
fi

log "Testing MongoDB authentication..."
AUTH_TEST=$("${MONGOSH}" "${CONN_ARGS[@]}" --quiet \
  --eval 'rs.slaveOk(); db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers' \
  2>&1) || true
log "  Auth result: ${AUTH_TEST}"

if echo "${AUTH_TEST}" | grep -qi "error\|failed\|refused\|closed"; then
  die "Authentication failed. Check MONGO_USER and MONGO_PASS."
fi

# --- resolve database list ----------------------------------------------------
if [[ $# -gt 0 ]]; then
  DATABASES=()
  for db in "$@"; do
    if echo "${db}" | grep -qwE "${SKIP_DBS}"; then
      log "Skipping excluded db: ${db}"
    else
      DATABASES+=("${db}")
    fi
  done
  [[ ${#DATABASES[@]} -eq 0 ]] && die "No databases to dump after exclusions"
  log "Dumping specified databases: ${DATABASES[*]}"
else
  log "Listing all databases (this may take a while) ..."
  DB_LIST_RAW=$("${MONGOSH}" "${CONN_ARGS[@]}" --quiet --eval '
    try {
      rs.slaveOk();
      var r = db.adminCommand({ listDatabases: 1, nameOnly: true });
      if (r.ok) {
        print("DB_COUNT: " + r.databases.length);
        r.databases.forEach(function(d) { print(d.name); });
        print("DB_LIST_DONE");
      } else {
        print("CMD_ERROR: " + JSON.stringify(r));
      }
    } catch(e) { print("EXCEPTION: " + e.message); }
  ' 2>&1)

  log "  Raw output:"
  echo "${DB_LIST_RAW}" | while IFS= read -r line; do log "    | ${line}"; done

  if echo "${DB_LIST_RAW}" | grep -q "EXCEPTION\|CMD_ERROR\|Error"; then
    die "Failed to list databases."
  fi

  DATABASES=()
  while IFS= read -r db; do
    db="$(echo "${db}" | tr -d '[:space:]')"
    [[ -z "${db}" ]] && continue
    echo "${db}" | grep -qwE "${SKIP_DBS}" && { log "  Skipping: ${db}"; continue; }
    echo "${db}" | grep -qE "^DB_COUNT:|^DB_LIST_DONE$" && continue
    DATABASES+=("${db}")
  done <<< "${DB_LIST_RAW}"

  [[ ${#DATABASES[@]} -eq 0 ]] && die "No user databases found"
  log "Found ${#DATABASES[@]} databases: ${DATABASES[*]}"
fi

# --- dump each database -------------------------------------------------------
mkdir -p "${DUMP_DIR}"
log "Output directory: ${DUMP_DIR}"

FAILED=()
SUCCEEDED=()
TOTAL=${#DATABASES[@]}
COUNT=0

for db in "${DATABASES[@]}"; do
  COUNT=$((COUNT + 1))
  OUT_DIR="${DUMP_DIR}/${db}"
  LOG_FILE="${DUMP_DIR}/${db}.log"
  log ""
  log "[${COUNT}/${TOTAL}] Dumping '${db}' → ${OUT_DIR} ..."

  DUMP_ARGS=(
    "${CONN_ARGS[@]}"
    --db="${db}"
    --out="${OUT_DIR}"
    --numParallelCollections="${PARALLEL}"
    --readPreference=secondaryPreferred
  )
  [[ "${GZIP}"    == "true" ]] && DUMP_ARGS+=(--gzip)
  [[ "${VERBOSE}" == "true" ]] && DUMP_ARGS+=(-v)

  START_SEC=$(date +%s)
  if mongodump "${DUMP_ARGS[@]}" 2>&1 | tee "${LOG_FILE}"; then
    ELAPSED=$(( $(date +%s) - START_SEC ))
    DUMP_SIZE=$(du -sh "${OUT_DIR}" 2>/dev/null | cut -f1 || echo "unknown")
    SUCCEEDED+=("${db}")
    log "  OK  ${db} — ${ELAPSED}s, ${DUMP_SIZE}"
  else
    ELAPSED=$(( $(date +%s) - START_SEC ))
    FAILED+=("${db}")
    log "  FAIL  ${db} — ${ELAPSED}s (see ${LOG_FILE})"
  fi
done

# --- summary ------------------------------------------------------------------
log ""
log "========== DUMP SUMMARY =========="
log "  Timestamp : ${TIMESTAMP}"
log "  Output    : ${DUMP_DIR}"
log "  Total     : ${TOTAL}"
log "  Succeeded : ${#SUCCEEDED[@]} — ${SUCCEEDED[*]:-none}"
log "  Failed    : ${#FAILED[@]} — ${FAILED[*]:-none}"
log "  Total size: $(du -sh "${DUMP_DIR}" 2>/dev/null | cut -f1 || echo unknown)"
log "=================================="

# --- cleanup old dumps --------------------------------------------------------
log ""
log "Cleaning up dumps older than ${RETAIN_DAYS} days in ${DUMP_ROOT} ..."
OLD_DUMPS=$(find "${DUMP_ROOT}" -maxdepth 1 -mindepth 1 -type d -mtime "+${RETAIN_DAYS}" 2>/dev/null || true)
if [[ -z "${OLD_DUMPS}" ]]; then
  log "  Nothing to clean up."
else
  while IFS= read -r old_dir; do
    log "  Removing: ${old_dir}"
    rm -rf "${old_dir}"
  done <<< "${OLD_DUMPS}"
  log "  Cleanup done."
fi

[[ ${#FAILED[@]} -gt 0 ]] && exit 1 || exit 0
