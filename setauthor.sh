#!/bin/bash
# ─────────────────────────────────────────────────────────────
# setauthor.sh — Set git author for all project repos and worktrees
# ─────────────────────────────────────────────────────────────
# Reads from .forge/config.env if it exists, otherwise uses git global config.
# Also ensures the FORGE_BASE_BRANCH exists in each project.

set -euo pipefail

if [ -f .forge/config.env ]; then
  # shellcheck disable=SC1091
  source .forge/config.env
fi

AUTHOR_NAME="${FORGE_AUTHOR_NAME:-$(git config user.name)}"
AUTHOR_EMAIL="${FORGE_AUTHOR_EMAIL:-$(git config user.email)}"
BASE_BRANCH="${FORGE_BASE_BRANCH:-develop}"

if [ -z "$AUTHOR_NAME" ] || [ -z "$AUTHOR_EMAIL" ]; then
  echo "❌ ERROR: No author configured. Set FORGE_AUTHOR_NAME and FORGE_AUTHOR_EMAIL in .forge/config.env"
  exit 1
fi

echo "Setting author: $AUTHOR_NAME <$AUTHOR_EMAIL>"
echo "Base branch: $BASE_BRANCH"
echo ""

# ─── Main project checkouts ─────────────────────────────
echo "── Project repositories ──"
for proj in solutions/*/; do
  [ "$proj" = "solutions/worktrees/" ] && continue
  if [ -d "$proj/.git" ] || git -C "$proj" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    git -C "$proj" config user.name "$AUTHOR_NAME"
    git -C "$proj" config user.email "$AUTHOR_EMAIL"
    # Ensure base branch exists
    if ! git -C "$proj" rev-parse --verify "$BASE_BRANCH" &>/dev/null 2>&1; then
      if git -C "$proj" rev-parse --verify main &>/dev/null 2>&1; then
        git -C "$proj" branch "$BASE_BRANCH" main 2>/dev/null && \
          echo "  ✓ $proj (created $BASE_BRANCH from main)" || \
          echo "  ✓ $proj"
      else
        echo "  ✓ $proj (⚠ no main branch — create $BASE_BRANCH manually)"
      fi
    else
      echo "  ✓ $proj"
    fi
  fi
done

# ─── Worktrees ──────────────────────────────────────────
if [ -d "solutions/worktrees" ]; then
  echo ""
  echo "── Worktrees ──"
  find solutions/worktrees -mindepth 2 -maxdepth 2 -type d | while read -r wt; do
    if git -C "$wt" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
      git -C "$wt" config user.name "$AUTHOR_NAME"
      git -C "$wt" config user.email "$AUTHOR_EMAIL"
      echo "  ✓ $wt"
    fi
  done
fi

echo ""
echo "✅ Done."