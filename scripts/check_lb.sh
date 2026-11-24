#!/usr/bin/env bash
# Hits the load balancer several times and shows which instance answered,
# proving traffic is spread across the Auto Scaling Group.
# Usage: ./scripts/check_lb.sh [count]
set -euo pipefail

cd "$(dirname "$0")/../envs/dev"
URL="$(terraform output -raw app_url)"
COUNT="${1:-10}"

echo "Calling $URL $COUNT times..."
for _ in $(seq 1 "$COUNT"); do
  curl -s "$URL" | grep -o 'i-[0-9a-f]*' | head -1
done | sort | uniq -c
