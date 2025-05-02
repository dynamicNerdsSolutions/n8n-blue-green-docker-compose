#!/bin/bash

STATE_FILE=".n8n_active_stack.json"
THRESHOLD_SECONDS=60
CADDYFILE_PATH="/etc/caddy/Caddyfile"

ACTIVE_STACK=$(jq -r '.active_stack' "$STATE_FILE")
if [[ "$ACTIVE_STACK" == "blue" ]]; then
  FROM="blue"
  TO="green"
else
  FROM="green"
  TO="blue"
fi

echo "🔁 Switching from $FROM to $TO"

# Step 1: Start target stack
echo "🚀 Starting $TO stack..."
docker-compose -f docker-compose.base.yml -f docker-compose.$TO.yml up -d

# Step 2: Wait for main to be ready
until curl -s http://n8n-$TO-main:5678/healthz | grep -q '"status":"ok"'; do
  echo "⏳ Waiting for n8n-$TO-main to be ready..."
  sleep 1
done

# Step 3: TODO: Add optional scheduled task check

# Step 4: Switch Caddy
echo "🔀 Updating Caddy to point to n8n-$TO-main..."
sed -i "s/n8n-$FROM-main/n8n-$TO-main/" "$CADDYFILE_PATH"
sudo caddy reload --config "$CADDYFILE_PATH"

# Step 5: Update state file
jq --arg to "$TO" '.active_stack = $to | .last_switch = now' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"

# Step 6: Stop previous main
echo "🛑 Stopping n8n-$FROM-main..."
docker-compose -f docker-compose.base.yml -f docker-compose.$FROM.yml stop n8n-$FROM-main

# Step 7: Wait for executions to finish (optional) then stop worker
# echo "⏳ Waiting for active jobs to complete in $FROM... (TODO)"
# docker-compose -f docker-compose.base.yml -f docker-compose.$FROM.yml stop n8n-$FROM-worker

echo "✅ Stack switched from $FROM to $TO successfully."
