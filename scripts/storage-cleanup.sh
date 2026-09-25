#!/bin/bash
# Storage watchdog for the $HERMES_HOME volume (/opt/data in production).
# Alerts if >80%, auto-cleans safe/regenerable targets.
#
# Deployed via cont-init.d/03-hermes-mentor-setup, which copies this from
# the image's staging dir onto the volume (root-owned scripts/ elsewhere
# in the image are NOT writable by the hermes user at runtime, so this
# file must live under $HERMES_HOME to ever be edited from inside a
# running Hermes session).

MOUNT="${HERMES_HOME:-/opt/data}"
THRESHOLD=80

usage=$(df "$MOUNT" | awk 'NR==2 {gsub(/%/,""); print $5}')

if [ "$usage" -lt "$THRESHOLD" ]; then
  # Silent when healthy (watchdog pattern)
  exit 0
fi

# Over threshold — clean in priority order
cleaned=""

# 1. pnpm store (biggest, fully regenerable)
if [ -d "$MOUNT/.pnpm-store" ]; then
  size=$(du -sh "$MOUNT/.pnpm-store" | cut -f1)
  rm -rf "$MOUNT/.pnpm-store"
  cleaned="$cleaned\n- .pnpm-store ($size)"
fi

# 2. node_modules in repos
for nm in "$MOUNT"/repos/*/node_modules; do
  if [ -d "$nm" ]; then
    size=$(du -sh "$nm" | cut -f1)
    rm -rf "$nm"
    cleaned="$cleaned\n- $nm ($size)"
  fi
done

# 3. .venv in repos
for venv in "$MOUNT"/repos/*/.venv; do
  if [ -d "$venv" ]; then
    size=$(du -sh "$venv" | cut -f1)
    rm -rf "$venv"
    cleaned="$cleaned\n- $venv ($size)"
  fi
done

# 4. LSP node_modules
if [ -d "$MOUNT/lsp/node_modules" ]; then
  size=$(du -sh "$MOUNT/lsp/node_modules" | cut -f1)
  rm -rf "$MOUNT/lsp/node_modules"
  cleaned="$cleaned\n- lsp/node_modules ($size)"
fi

# 5. Sessions older than 7 days (by filename date)
cutoff=$(date -d '7 days ago' +%Y%m%d)
session_count=0
for f in "$MOUNT"/sessions/session_202*.json "$MOUNT"/sessions/session_cron_*.json; do
  [ -f "$f" ] || continue
  date_part=$(basename "$f" | grep -oP '20\d{6}')
  if [ -n "$date_part" ] && [ "$date_part" -lt "$cutoff" ]; then
    rm -f "$f"
    session_count=$((session_count + 1))
  fi
done
for f in "$MOUNT"/sessions/202*.jsonl; do
  [ -f "$f" ] || continue
  date_part=$(basename "$f" | grep -oP '20\d{6}')
  if [ -n "$date_part" ] && [ "$date_part" -lt "$cutoff" ]; then
    rm -f "$f"
  fi
done
[ "$session_count" -gt 0 ] && cleaned="$cleaned\n- $session_count old sessions"

# Report
new_usage=$(df "$MOUNT" | awk 'NR==2 {gsub(/%/,""); print $5}')
echo "⚠️ Storage watchdog triggered (was ${usage}%, now ${new_usage}%)"
echo ""
echo "Cleaned:"
echo -e "$cleaned"
echo ""
echo "Current: $(df -h "$MOUNT" | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')"
