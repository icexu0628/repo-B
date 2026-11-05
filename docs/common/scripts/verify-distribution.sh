#!/usr/bin/env sh
# usage: verify-distribution.sh <target-commit> <owner/repo,owner/repo,...> [timeout-minutes]
# Success means: downstream main's docs/common/.ai-rules-sync.json sourceCommit == target.
set -eu

target="$1"
repos="$2"
timeout_min="${3:-10}"
deadline=$(( $(date +%s) + timeout_min * 60 ))

status_of() {
  r="$1"
  synced=$(gh api "repos/$r/contents/docs/common/.ai-rules-sync.json?ref=main" -q .content 2>/dev/null \
    | base64 -d 2>/dev/null | jq -r .sourceCommit 2>/dev/null || true)
  if [ "$synced" = "$target" ]; then echo "SUCCESS"; return; fi
  # A later release already landed; its content includes the target.
  if [ -n "$synced" ] && git merge-base --is-ancestor "$target" "$synced" 2>/dev/null; then
    echo "SUPERSEDED by $synced"; return
  fi

  pr=$(gh api "repos/$r/pulls?state=open&head=${r%%/*}:sync/ai-rules/$target" -q '.[0].html_url' 2>/dev/null || true)
  if [ -n "$pr" ]; then echo "PR_PENDING $pr"; return; fi

  run=$(gh api "repos/$r/actions/runs?event=repository_dispatch&per_page=20" \
    -q ".workflow_runs[] | select(.display_title | contains(\"$target\")) | \"\(.status) \(.conclusion) \(.html_url)\"" 2>/dev/null \
    | head -1 || true)
  if [ -z "$run" ]; then echo "NOT_TRIGGERED"; return; fi
  case "$run" in
    "completed success "*) echo "UNKNOWN ${run#completed success }" ;;
    completed*)            echo "FAILED ${run##* }" ;;
    *)                     echo "SYNCING ${run##* }" ;;
  esac
}

while :; do
  all_ok=1
  echo "== $(date -u +%FT%TZ) target=$target"
  for r in $(printf '%s' "$repos" | tr ',' ' '); do
    s=$(status_of "$r")
    echo "  $r: $s"
    case "$s" in SUCCESS|SUPERSEDED*) ;; *) all_ok=0 ;; esac
  done
  if [ "$all_ok" = 1 ]; then echo "ALL SUCCESS"; exit 0; fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "INCOMPLETE after ${timeout_min}m: manual intervention required (retry via workflow_dispatch with target_commit/target_repos)" >&2
    exit 1
  fi
  sleep 30
done
