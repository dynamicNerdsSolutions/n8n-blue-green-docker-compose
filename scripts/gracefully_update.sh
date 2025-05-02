#!/bin/bash

IMAGE="docker.n8n.io/n8nio/n8n"
echo "🔍 Checking for N8N image updates..."

docker pull $IMAGE > /dev/null
LOCAL_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE)
REMOTE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE:latest)

if [[ "$LOCAL_DIGEST" == "$REMOTE_DIGEST" ]]; then
  echo "✅ N8N image already up to date."
  exit 0
else
  echo "⬆️ New image available. Proceeding to switch stack..."
  ./scripts/switch_stack.sh
fi