#!/bin/bash
# Run the connector test suites against one or more ClickHouse instances.
#
# The suites execute via PQTest on a Windows machine reached over SSH, targeting ClickHouse
# instances reachable from that machine. Machine-specific values (SSH destination, paths,
# host address) come from Tests/run-tests.env — copy run-tests.env.example and adjust.
#
# Usage:
#   ./run-tests.sh --local                      # today's setup: the locally running server (flight 9007)
#   ./run-tests.sh --versions "26.8 latest"     # docker compose matrix (profiles from docker/docker-compose.yml)
#   ./run-tests.sh --versions all               # every version in the compose file
# Options:
#   --keep        leave matrix containers running afterwards
#   --host H      Windows-visible host of the ClickHouse instances (overrides run-tests.env)
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
[ -f "$SCRIPT_DIR/run-tests.env" ] && . "$SCRIPT_DIR/run-tests.env"
DOCKER="${DOCKER:-docker}"
: "${VM_SSH_DEST:?set VM_SSH_DEST (user@host) in Tests/run-tests.env}"
VM_SSH_PORT="${VM_SSH_PORT:-22}"
VM_SSH_KEY="${VM_SSH_KEY:-}"
KEYOPT=(); [ -n "$VM_SSH_KEY" ] && KEYOPT=(-i "$VM_SSH_KEY")
SSH_OPTS=("${KEYOPT[@]}" -p "$VM_SSH_PORT" "$VM_SSH_DEST")
: "${VM_TESTS:?set VM_TESTS (Windows path of the test workspace) in Tests/run-tests.env}"
: "${PQTEST:?set PQTEST (Windows path of PQTest.exe) in Tests/run-tests.env}"
HOST="${CH_HOST:?set CH_HOST (ClickHouse host as seen from the Windows machine) in Tests/run-tests.env}"

MODE=""; VERSIONS=""; KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --local) MODE=local ;;
    --versions) MODE=matrix; VERSIONS="$2"; shift ;;
    --keep) KEEP=1 ;;
    --host) HOST="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$MODE" ] || { echo "need --local or --versions"; exit 2; }

flight_port_for() {
  case "$1" in
    26.5) echo 9105 ;; 26.6) echo 9106 ;; 26.8) echo 9108 ;; latest) echo 9110 ;;
    *) echo "unknown version $1" >&2; exit 2 ;;
  esac
}

build_and_push_mez() {
  "$REPO_DIR/build-mez.sh" > /dev/null
  scp -q "${KEYOPT[@]}" -P "$VM_SSH_PORT" "$SCRIPT_DIR/docker/run-suites.ps1" "$VM_SSH_DEST:$VM_TESTS/run-suites.ps1"
  scp -q "${KEYOPT[@]}" -P "$VM_SSH_PORT" "$REPO_DIR/ClickHouse.mez" "$VM_SSH_DEST:$VM_TESTS/ClickHouse.mez"
  # sync test files (queries + snapshots; the repo is the source of truth, snapshots are
  # compared, not regenerated, on CI-style runs)
  for d in Sanity Folding KnownIssues Functions; do
    scp -q "${KEYOPT[@]}" -P "$VM_SSH_PORT" "$SCRIPT_DIR/TestSuites/$d/"*.query.pq "$SCRIPT_DIR/TestSuites/$d/"*.pqout "$VM_SSH_DEST:$VM_TESTS/Tests/TestSuites/$d/" 2>/dev/null || true
  done
}

run_target() { # $1 = label, $2 = flight port
  local label="$1" port="$2"
  echo "=== [$label] flight $HOST:$port"
  ssh "${SSH_OPTS[@]}" "powershell -NoProfile -ExecutionPolicy Bypass -File $VM_TESTS/run-suites.ps1 -TargetHost $HOST -Port $port -Label $label -PqTest \"$PQTEST\" -TestsRoot \"$VM_TESTS\"" 2>/dev/null
}

build_and_push_mez

if [ "$MODE" = local ]; then
  run_target "local" 9007
else
  [ "$VERSIONS" = all ] && VERSIONS="26.5 26.6 26.8 latest"
  cd "$SCRIPT_DIR/docker"
  for v in $VERSIONS; do
    "$DOCKER" compose --profile "$v" up -d --wait --quiet-pull
    svc="ch-$(echo "$v" | tr . -)"
    "$DOCKER" compose --profile "$v" exec -T "$svc" clickhouse-client --password clickhouse --multiquery < "$SCRIPT_DIR/Fixtures/seed.sql"
    echo "[$v] seeded"
  done
  rc=0
  for v in $VERSIONS; do run_target "$v" "$(flight_port_for "$v")" || rc=1; done
  if [ "$KEEP" = 0 ]; then for v in $VERSIONS; do "$DOCKER" compose --profile "$v" down -v > /dev/null; done; fi
  exit $rc
fi
