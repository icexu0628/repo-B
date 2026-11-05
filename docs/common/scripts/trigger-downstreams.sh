#!/usr/bin/env sh
# usage: trigger-downstreams.sh <target-commit> <ai-rules-repo-url> <owner/repo,owner/repo,...>
set -eu

commit="$1"
repo_url="$2"
repos="$3"

for r in $(printf '%s' "$repos" | tr ',' ' '); do
  gh api --method POST "repos/$r/dispatches" \
    -f event_type=ai-rules-sync \
    -f "client_payload[commit]=$commit" \
    -f "client_payload[repository]=$repo_url"
  echo "dispatched $r <- $commit"
done
