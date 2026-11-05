#!/usr/bin/env sh
# Runs inside a downstream repository on the sync branch.
# usage: sync-subtree.sh <ai-rules-repo-url> <ai-rules-commit>
set -eu

repo_url="$1"
commit="$2"
prefix="docs/common"
version_file="$prefix/.ai-rules-sync.json"

git remote add ai-rules "$repo_url" 2>/dev/null || git remote set-url ai-rules "$repo_url"
git fetch --no-tags ai-rules "$commit"

if [ -n "$(git log -1 --format=%H --grep="^git-subtree-dir: $prefix\$")" ]; then
  git subtree merge --prefix="$prefix" --squash "$commit"
else
  git subtree add --prefix="$prefix" --squash "$commit"
fi

printf '{"sourceRepository":"%s","sourceCommit":"%s"}\n' "$repo_url" "$commit" > "$version_file"
git add "$version_file"
git commit -m "chore(ai-rules): record sync $commit"
