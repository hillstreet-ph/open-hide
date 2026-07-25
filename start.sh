#!/bin/sh
# =============================================================================
# AnythingMCP — Unified container startup script
# Runs NestJS backend and Next.js frontend in the same container.
# =============================================================================

# Trap to clean up child processes on exit
cleanup() {
  echo "==> Shutting down..."
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
  wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
  exit 0
}
trap cleanup TERM INT

echo "==> Running database migrations..."
cd /app/backend
npx prisma migrate deploy

echo "==> Starting backend (port 4000)..."
# Cap the V8 heap so a runaway allocation fails *this* process (caught by the
# liveness loop below → container restart) instead of OOM-killing the whole host.
# Override via NODE_MAX_OLD_SPACE_MB; default 2048 suits a ~4GB host.
# Force PORT=4000 so the backend never conflicts with the frontend (which
# listens on Railway's $PORT, defaulting to 3000).
PORT=4000 node --max-old-space-size="${NODE_MAX_OLD_SPACE_MB:-2048}" dist/src/main.js &
BACKEND_PID=$!

echo "==> Starting frontend (port 3000)..."
# Next.js standalone in a monorepo preserves the workspace directory structure
cd /app/frontend/packages/frontend
HOSTNAME=0.0.0.0 PORT="${PORT:-3000}" node server.js &
FRONTEND_PID=$!

echo "==> AnythingMCP running — backend PID=$BACKEND_PID, frontend PID=$FRONTEND_PID"

# If EITHER process dies (e.g. the backend is OOM-killed), exit so Docker's
# `restart: unless-stopped` brings the container back — instead of leaving a
# half-broken container up (a dead backend behind a live frontend serving 502s,
# which previously needed a manual restart). POSIX `wait pid1 pid2` waits for
# BOTH to exit, so we poll liveness instead.
while kill -0 "$BACKEND_PID" 2>/dev/null && kill -0 "$FRONTEND_PID" 2>/dev/null; do
  sleep 5
done
echo "==> A process exited unexpectedly, shutting down so the container restarts..."
cleanup
