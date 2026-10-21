#!/bin/bash
# Gaia Family server: run one Lua self-test on a Linux test server (2026-10-21).
#
# Usage:  tools/family/selftest.sh <test.lua> [timeout-seconds]
#
# Copies <test.lua> to data/scripts/zz_selftest.lua, writes a temporary
# config.lua (config.lua.dist + family/config.family.lua + the test database),
# starts the server, waits for the line "[Selftest] DONE" (or a Lua error, or
# the timeout), stops the server and prints the self-test lines, Lua errors and
# warnings. config.lua and zz_selftest.lua are always deleted afterwards; never
# commit them. Start from tools/family/selftest_template.lua.
#
# Needs the Linux build of the pinned Canary (v3.6.1) and MariaDB:
#   CANARY_BIN       path to the Linux canary binary (required)
#   FAMILY_TEST_DIR  folder for logs and the test database
#                    (default /tmp/family-selftest; database in db/, socket my.sock)
#   TEST_DB_PORT     default 3307   TEST_DB_NAME default canary
#   TEST_DB_USER     default canary TEST_DB_PASS default test (a local throwaway)
# The database is created on first use (mariadb-install-db, then schema.sql).
#
# Exit code: 0 = DONE reached, no Lua errors and no "FAIL" check,
# 1 = otherwise, 2 = usage.

set -u
TEST_FILE=${1:-}
TIMEOUT=${2:-300}
if [ -z "$TEST_FILE" ] || [ ! -f "$TEST_FILE" ]; then
	echo "usage: $0 <test.lua> [timeout-seconds]" >&2
	exit 2
fi
TEST_FILE=$(readlink -f "$TEST_FILE")
: "${CANARY_BIN:?set CANARY_BIN to the Linux canary binary}"
CANARY_BIN=$(readlink -f "$CANARY_BIN")
DIR=${FAMILY_TEST_DIR:-/tmp/family-selftest}
PORT=${TEST_DB_PORT:-3307}
DB_NAME=${TEST_DB_NAME:-canary}
DB_USER=${TEST_DB_USER:-canary}
DB_PASS=${TEST_DB_PASS:-test}
SOCK=$DIR/my.sock
MARK="-- FAMILY SELFTEST CONFIG (temporary, made by tools/family/selftest.sh)"

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT" || exit 2
mkdir -p "$DIR"

if [ -f config.lua ] && ! head -1 config.lua | grep -qF "$MARK"; then
	echo "config.lua exists and was not made by this script; move it away first" >&2
	exit 2
fi

cleanup() {
	pkill -INT -f "^$CANARY_BIN" 2>/dev/null
	sleep 3
	pkill -9 -f "^$CANARY_BIN" 2>/dev/null
	rm -f config.lua data/scripts/zz_selftest.lua
}
trap cleanup EXIT

# Database: start it, and create it the first time.
if ! mysqladmin --socket="$SOCK" ping >/dev/null 2>&1; then
	FRESH=0
	if [ ! -d "$DIR/db/mysql" ]; then
		mariadb-install-db --user=root --datadir="$DIR/db" --auth-root-authentication-method=socket >"$DIR/db-install.log" 2>&1 || { echo "mariadb-install-db failed, see $DIR/db-install.log" >&2; exit 1; }
		FRESH=1
	fi
	setsid nohup /usr/sbin/mariadbd --user=root --datadir="$DIR/db" --socket="$SOCK" --port="$PORT" --bind-address=127.0.0.1 >"$DIR/db.log" 2>&1 </dev/null &
	for _ in $(seq 1 30); do mysqladmin --socket="$SOCK" ping >/dev/null 2>&1 && break; sleep 1; done
	if [ "$FRESH" = 1 ]; then
		mysql --socket="$SOCK" -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`; CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL ON \`$DB_NAME\`.* TO '$DB_USER'@'%'; GRANT ALL ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;" || exit 1
		mysql --socket="$SOCK" -u root "$DB_NAME" <schema.sql || exit 1
		echo "test database created in $DIR/db"
	fi
fi

# Temporary config and the test script.
{
	echo "$MARK"
	cat config.lua.dist
	cat family/config.family.lua
	printf '\nmysqlHost = "127.0.0.1"\nmysqlUser = "%s"\nmysqlPass = "%s"\nmysqlDatabase = "%s"\nmysqlPort = %s\n' "$DB_USER" "$DB_PASS" "$DB_NAME" "$PORT"
} >config.lua
cp "$TEST_FILE" data/scripts/zz_selftest.lua

NAME=$(basename "$TEST_FILE" .lua)
LOG=$DIR/$NAME.log
pkill -9 -f "^$CANARY_BIN" 2>/dev/null
setsid nohup "$CANARY_BIN" >"$LOG" 2>&1 </dev/null &
for _ in $(seq 1 "$TIMEOUT"); do
	grep -q "\[Selftest\] DONE" "$LOG" && break
	if grep -q "Lua Script Error\|Failed to connect" "$LOG"; then sleep 3; break; fi
	sleep 1
done
cleanup
trap - EXIT

echo "== log: $LOG"
grep -n "\[Selftest\]" "$LOG" | sed 's/^\([0-9]*\):\[[^]]*\] \[info\] /\1: /'
ERRORS=$(grep -c "Lua Script Error\|\[error\]" "$LOG")
if [ "$ERRORS" -gt 0 ]; then
	echo "== errors:"
	grep -n -A8 "Lua Script Error\|\[error\]" "$LOG" | head -60
fi
WARN=$(grep -n "\[warning\]" "$LOG" | grep -v "executed as root user")
[ -n "$WARN" ] && { echo "== warnings:"; echo "$WARN" | head -20; }
grep -q "Segmentation fault" "$LOG" && echo "== note: the server crashed while stopping (usually caused by fake players left over by the test)"
if grep -q "\[Selftest\] DONE" "$LOG" && [ "$ERRORS" -eq 0 ] && ! grep -q "\[Selftest\] FAIL" "$LOG"; then
	exit 0
fi
echo "== FAILED (no DONE line, Lua errors or failed checks)"
exit 1
