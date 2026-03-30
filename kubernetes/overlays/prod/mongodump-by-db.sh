#!/bin/bash
#
# mongodump-by-db.sh
# Dumps each MongoDB database individually via mongos.
# Designed to run inside the "restore" pod in the cryoem-logbook namespace.
#
# Usage:
#   ./mongodump-by-db.sh                          # dump all user databases
#   ./mongodump-by-db.sh mydb1 mydb2              # dump only specific databases
#
# Environment variables (override defaults):
#   MONGO_HOST        mongos host          (default: mongo-mongos.cryoem-logbook.svc.cluster.local)
#   MONGO_PORT        mongos port          (default: 27017)
#   MONGO_USER        auth username         (default: admin)
#   MONGO_PASS        auth password         (read from secret file or set directly)
#   MONGO_AUTH_DB     auth database         (default: admin)
#   DUMP_ROOT         output directory      (default: /data/mongodump)
#   GZIP              enable gzip           (default: true)
#   PARALLEL          parallel collections  (default: 4)

set -euo pipefail

# --- configuration -----------------------------------------------------------
MONGO_HOST="${MONGO_HOST:-mongo-mongos.cryoem-logbook.svc.cluster.local}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-admin}"
MONGO_PASS="${MONGO_PASS:-}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"
DUMP_ROOT="${DUMP_ROOT:-/data/mongodump}"
GZIP="${GZIP:-true}"
PARALLEL="${PARALLEL:-4}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DUMP_DIR="${DUMP_ROOT}/${TIMESTAMP}"

# databases to skip (system databases)
SKIP_DBS="admin|config|local"

# --- helpers ------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die()  { log "ERROR: $*" >&2; exit 1; }

# --- pre-flight checks -------------------------------------------------------
command -v mongodump >/dev/null 2>&1 || die "mongodump not found in PATH"
command -v mongosh  >/dev/null 2>&1 || MONGOSH="mongo" || true
MONGOSH="${MONGOSH:-mongosh}"

if [[ -z "${MONGO_PASS}" ]]; then
  # try reading from the Percona-generated secret mounted path
  SECRET_FILE="/etc/mongodb-secrets/MONGODB_CLUSTER_ADMIN_PASSWORD"
  if [[ -f "${SECRET_FILE}" ]]; then
    MONGO_PASS="$(cat "${SECRET_FILE}")"
    log "Read password from ${SECRET_FILE}"
  else
    die "MONGO_PASS not set and ${SECRET_FILE} not found. Export MONGO_PASS or mount the secret."
  fi
fi

CONN_URI="mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:${MONGO_PORT}/?authSource=${MONGO_AUTH_DB}"

# --- resolve database list ----------------------------------------------------
if [[ $# -gt 0 ]]; then
  DATABASES=("$@")
  log "Dumping specified databases: ${DATABASES[*]}"
else
  log "Listing databases from ${MONGO_HOST}:${MONGO_PORT} ..."
  DB_LIST=$("${MONGOSH}" --quiet --eval '
    db.adminCommand({ listDatabases: 1, nameOnly: true })
      .databases.map(d => d.name).join("\n")
  ' "${CONN_URI}") || die "Failed to list databases"

  # filter out system dbs
  DATABASES=()
  while IFS= read -r db; do
    [[ -z "${db}" ]] && continue
    if echo "${db}" | grep -qwE "${SKIP_DBS}"; then
      log "  skipping system db: ${db}"
      continue
    fi
    DATABASES+=("${db}")
  done <<< "${DB_LIST}"

  if [[ ${#DATABASES[@]} -eq 0 ]]; then
    die "No user databases found to dump"
  fi
  log "Found ${#DATABASES[@]} databases: ${DATABASES[*]}"
fi

# --- dump each database -------------------------------------------------------
mkdir -p "${DUMP_DIR}"
FAILED=()
SUCCEEDED=()

for db in "${DATABASES[@]}"; do
  OUT_DIR="${DUMP_DIR}/${db}"
  log "Dumping '${db}' → ${OUT_DIR} ..."

  DUMP_ARGS=(
    --uri="${CONN_URI}"
    --db="${db}"
    --out="${OUT_DIR}"
    --numParallelCollections="${PARALLEL}"
    --readPreference=secondaryPreferred
  )

  if [[ "${GZIP}" == "true" ]]; then
    DUMP_ARGS+=(--gzip)
  fi

  if mongodump "${DUMP_ARGS[@]}" 2>&1 | tee "${OUT_DIR}.log"; then
    SUCCEEDED+=("${db}")
    log "  ✓ ${db} done"
  else
    FAILED+=("${db}")
    log "  ✗ ${db} FAILED (see ${OUT_DIR}.log)"
  fi
done

# --- summary ------------------------------------------------------------------
echo ""
log "========== DUMP SUMMARY =========="
log "  Timestamp : ${TIMESTAMP}"
log "  Output    : ${DUMP_DIR}"
log "  Succeeded : ${#SUCCEEDED[@]} — ${SUCCEEDED[*]:-none}"
log "  Failed    : ${#FAILED[@]} — ${FAILED[*]:-none}"
log "=================================="

if [[ ${#FAILED[@]} -gt 0 ]]; then
  exit 1
fi
