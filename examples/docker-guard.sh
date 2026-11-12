#!/usr/bin/env bash
# docker-guard.sh: a wrapper placed in front of `docker` on the PATH of a run
# that executes machine-written code. It refuses any `docker run` that could
# reach the network, the home folder or a credential, and logs every call.
#
# This is a generic example written for this repository. It is not the file
# that ran in the trial, and it has been tested only with the self-test below
# (argument checks, no container started). Read it before you rely on it.
#
# Required environment:
#   GUARD_RUN_DIR    the one folder a container may write to
#   GUARD_DATA_DIR   the one folder a container may read (mounted read-only)
#   GUARD_LOG        the audit log file
#   GUARD_REAL_DOCKER  path of the real docker binary
#
# Usage: put a link named `docker` to this script first on PATH.
# Self-test: bash docker-guard.sh --self-test
set -u

refuse() { echo "$(date -u +%FT%TZ) REFUSED: $1 :: $ARGS" >> "$GUARD_LOG"; echo "docker-guard: refused: $1" >&2; exit 97; }

check_mount() {  # $1 = host path, $2 = options
  case "$1" in
    "$GUARD_RUN_DIR"|"$GUARD_RUN_DIR"/*) ;;
    "$GUARD_DATA_DIR"|"$GUARD_DATA_DIR"/*)
      case ",$2," in *,ro,*) ;; *) refuse "data mount is not read-only: $1" ;; esac ;;
    *) refuse "mount outside the run and data folders: $1" ;;
  esac
}

guard() {
  ARGS="$*"
  [ "${1:-}" = "run" ] || { echo "$(date -u +%FT%TZ) PASS (not run): $ARGS" >> "$GUARD_LOG"; return 0; }
  shift
  local net_none=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --network=none) net_none=1 ;;
      --network|--net) [ "${2:-}" = "none" ] && net_none=1 || refuse "network is not none"; shift ;;
      --network=*|--net=*) refuse "network is not none" ;;
      --privileged|--privileged=*) refuse "privileged" ;;
      # exact match on purpose: a glob such as --pid* would also refuse --pids-limit
      --pid|--pid=*) refuse "host pid namespace" ;;
      --cap-add|--cap-add=*|--device|--device=*|--ipc=host|--userns=host|--uts=host) refuse "extra privilege: $1" ;;
      -e|--env) case "${2:-}" in *TOKEN*|*KEY*|*SECRET*|*PASSWORD*) refuse "credential variable" ;; esac; shift ;;
      --env=*|-e*) case "$1" in *TOKEN*|*KEY*|*SECRET*|*PASSWORD*) refuse "credential variable" ;; esac ;;
      --env-file|--env-file=*) refuse "env file" ;;
      -v|--volume) IFS=: read -r src _dst opts <<< "${2:-}"; check_mount "$src" "${opts:-}"; shift ;;
      --volume=*) IFS=: read -r src _dst opts <<< "${1#--volume=}"; check_mount "$src" "${opts:-}" ;;
      --mount|--mount=*) refuse "--mount form is not parsed; use -v" ;;
      --) break ;;
      -*) ;;          # other flags pass (memory limits, --pids-limit, --rm, ...)
      *) break ;;     # first non-flag word is the image
    esac
    shift
  done
  [ "$net_none" = 1 ] || refuse "no --network none"
  echo "$(date -u +%FT%TZ) PASS: $ARGS" >> "$GUARD_LOG"
}

self_test() {
  local t; t=$(mktemp -d "${TMPDIR:-/tmp}/guard.XXXXXX") || return 1; export GUARD_RUN_DIR="$t/run" GUARD_DATA_DIR="$t/data" GUARD_LOG="$t/log"
  mkdir -p "$GUARD_RUN_DIR" "$GUARD_DATA_DIR"
  local fail=0
  expect() {  # $1 = pass|refuse, rest = docker args
    local want=$1; shift
    if ( guard "$@" ) 2>/dev/null; then got=pass; else got=refuse; fi
    [ "$got" = "$want" ] && echo "ok   $want: $*" || { echo "FAIL want $want got $got: $*"; fail=1; }
  }
  expect pass   run --rm --network none --memory 8g --pids-limit=512 -v "$GUARD_RUN_DIR:/work" -v "$GUARD_DATA_DIR:/data:ro" img python main.py
  expect refuse run --rm -v "$GUARD_RUN_DIR:/work" img
  expect refuse run --network host -v "$GUARD_RUN_DIR:/work" img
  expect refuse run --network none -v "$HOME:/home" img
  expect refuse run --network none -v "$GUARD_DATA_DIR:/data" img
  expect refuse run --network none --privileged img
  expect refuse run --network none --pid=host img
  expect refuse run --network none --pid host img
  expect refuse run --network none -e HF_TOKEN=x img
  expect refuse run --network none --mount type=bind,src=/,dst=/host img
  expect pass   ps
  rm -rf "$t"; return $fail
}

if [ "${1:-}" = "--self-test" ]; then self_test; exit $?; fi
: "${GUARD_RUN_DIR:?}" "${GUARD_DATA_DIR:?}" "${GUARD_LOG:?}" "${GUARD_REAL_DOCKER:?}"
guard "$@"
exec "$GUARD_REAL_DOCKER" "$@"
