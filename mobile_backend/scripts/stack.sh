#!/usr/bin/env bash
# Control the mobile_backend Docker Compose stack (Postgres, Redis, API, worker).
# Requires LF line endings (see repo .gitattributes).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: scripts/stack.sh <command>

Commands:
  up        Start all services (detached)
  stop      Stop all services (containers kept, data preserved)
  restart   Restart all services
  down      Stop and remove containers (named volumes kept)
  ps        Show service status
  logs      Follow logs — optional service name, e.g. logs backend
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  up)
    docker compose up -d
    ;;
  stop)
    docker compose stop
    ;;
  restart)
    docker compose restart
    ;;
  down)
    docker compose down
    ;;
  ps)
    docker compose ps
    ;;
  logs)
    if [[ $# -gt 0 ]]; then
      docker compose logs -f "$@"
    else
      docker compose logs -f
    fi
    ;;
  -h | --help | help | "")
    usage
    exit 0
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
