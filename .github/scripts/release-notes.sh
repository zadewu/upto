#!/usr/bin/env bash
# Prints Markdown release notes for <tag>, built from conventional commit subjects
# since the previous tag (or the first commit). Usage: release-notes.sh <tag> [repo-slug]
set -euo pipefail

tag="${1:?usage: release-notes.sh <tag> [owner/repo]}"
repo="${2:-${GITHUB_REPOSITORY:-}}"

prev="$(git describe --tags --abbrev=0 "${tag}^" 2>/dev/null || true)"
range="${prev:+${prev}..}${tag}"

# section <title> <type-regex>: list matching commits with the type prefix stripped.
section() {
  local lines
  lines="$(git log --no-merges --format='%s (%h)' "$range" |
    { grep -E "^($2)(\([^)]*\))?!?: " || true; } |
    sed -E "s/^($2)(\([^)]*\))?!?: /- /")"
  [ -n "$lines" ] && printf '### %s\n\n%s\n\n' "$1" "$lines"
  return 0
}

section "Features" "feat"
section "Bug Fixes" "fix"
section "Performance" "perf"
section "Maintenance" "refactor|test|ci|docs|build|chore|style"

if [ -n "$repo" ]; then
  if [ -n "$prev" ]; then
    echo "**Full changelog**: https://github.com/${repo}/compare/${prev}...${tag}"
  else
    echo "**Full changelog**: https://github.com/${repo}/commits/${tag}"
  fi
fi
