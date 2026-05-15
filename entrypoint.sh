#!/bin/bash
set -e

# Sync config and identity files into the persistent volume (always overwrite from image)
cp /root/.hermes-config/config.yaml /root/.hermes/config.yaml
cp /root/.hermes-config/SOUL.md /root/.hermes/SOUL.md

# MEMORY.md only copy if not present (agent updates it over time)
if [ ! -f /root/.hermes/MEMORY.md ]; then
  cp /root/.hermes-config/MEMORY.md /root/.hermes/MEMORY.md
fi

# Create cron jobs (idempotent — checks if they exist first)
EXISTING=$(hermes cron list 2>/dev/null | grep -c "morning-brief" || true)
if [ "$EXISTING" -eq "0" ]; then
  echo "[entrypoint] Creating cron jobs..."

  hermes cron create "0 8 * * *" \
    "You are Nilanjan's technical mentor. Use your browser to check recent activity on github.com/facebookincubator/velox, github.com/apache/spark, and github.com/apache/arrow. Send a morning brief with: 1) A side project idea related to data platforms or query engines that would make a good OSS contribution. 2) One interesting open issue or PR you found from those repos that matches a 3-year-exp engineer learning C++. 3) A concept to study today with a specific link. Keep it actionable and under 300 words." \
    --name "morning-brief" --deliver "telegram:${TELEGRAM_CHAT_ID}"

  hermes cron create "0 14 * * *" \
    "You are Nilanjan's technical mentor. Send ONE deep-dive learning nugget. Pick a topic from: distributed systems internals, query engine design (Velox/Gluten/Spark/Arrow), database storage engines, AI inference optimization, or data platform architecture. Go DEEP on one specific concept — explain the 'why' behind the design, not just the 'what'. Include: 1) The core insight (2-3 sentences), 2) Where to see it in code (specific repo, file, function — use your browser to verify the link works), 3) One small experiment to solidify understanding. Under 250 words." \
    --name "daily-deep-dive" --deliver "telegram:${TELEGRAM_CHAT_ID}"

  hermes cron create "0 20 * * 5" \
    "You are Nilanjan's technical mentor. It's Friday evening — send a weekend project challenge. Use your browser to find a real, specific problem to solve. Pick ONE: build a tiny query engine component, implement a distributed systems paper concept, write a Spark plugin, or build an AI agent tool. Include: what to build, why it's valuable, key repos/files to reference (verify links with browser), and definition of done. Completable in a weekend. Under 400 words." \
    --name "weekend-challenge" --deliver "telegram:${TELEGRAM_CHAT_ID}"

  echo "[entrypoint] Cron jobs created."
else
  echo "[entrypoint] Cron jobs already exist, skipping."
fi

# Start the gateway
exec hermes gateway run
