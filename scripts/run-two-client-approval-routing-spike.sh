#!/usr/bin/env bash
set -euo pipefail

PORT="${CODEX_APP_SERVER_PORT:-8794}"
HOST="${CODEX_APP_SERVER_HOST:-127.0.0.1}"
URL="ws://${HOST}:${PORT}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_BIN="${CODEX_BIN:-/Applications/Codex.app/Contents/Resources/codex}"
APP_SERVER_LOG="${CODEX_STATUS_RADAR_APP_SERVER_LOG:-/tmp/codex-status-radar-app-server.log}"

started_app_server_pid=""

is_listening() {
  lsof -nP -iTCP:"${PORT}" -sTCP:LISTEN >/dev/null 2>&1
}

cleanup() {
  if [[ -n "${started_app_server_pid}" ]]; then
    kill "${started_app_server_pid}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

if ! is_listening; then
  if [[ ! -x "${CODEX_BIN}" ]]; then
    echo "找不到可执行的 Codex CLI：${CODEX_BIN}" >&2
    exit 1
  fi

  "${CODEX_BIN}" app-server --listen "${URL}" >"${APP_SERVER_LOG}" 2>&1 &
  started_app_server_pid="$!"

  for _ in {1..50}; do
    if is_listening; then
      break
    fi
    sleep 0.1
  done
fi

if ! is_listening; then
  echo "Codex app-server 未能监听 ${URL}，日志：${APP_SERVER_LOG}" >&2
  exit 1
fi

CODEX_APP_SERVER_PORT="${PORT}" \
CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS="${CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS:-3000}" \
node "${ROOT_DIR}/prototypes/app-server-approval/two-client-routing-spike.mjs"
