#!/bin/bash
# ─────────────────────────────────────────────────────────────
# init-worktree.sh — Prepare a git worktree for FORGE story work
# ─────────────────────────────────────────────────────────────
#
# Usage:
#   .forge/init-worktree.sh <project-name> <story-id> <slug>
#
# Example:
#   .forge/init-worktree.sh citizen-report-api US-07-01 list-reports
#
# What it does:
#   1. Sources .forge/config.env for author, branch, and secret file settings
#   2. Creates a git worktree at solutions/worktrees/<project>/<story-id>/
#   3. Sets git author on the worktree
#   4. Copies untracked secret/config files from the main project checkout
#
# Run this BEFORE starting any story implementation in a worktree.
# ─────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Load config ───────────────────────────────────────
if [ -f "$REPO_ROOT/.forge/config.env" ]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.forge/config.env"
else
  echo "⚠ WARNING: .forge/config.env not found. Using git config defaults."
fi

AUTHOR_NAME="${FORGE_AUTHOR_NAME:-$(git config user.name)}"
AUTHOR_EMAIL="${FORGE_AUTHOR_EMAIL:-$(git config user.email)}"
BASE_BRANCH="${FORGE_BASE_BRANCH:-develop}"
SECRET_FILES="${FORGE_SECRET_FILES:-src/main/resources/application-default.properties,src/main/resources/application-local.properties,.env,.env.local,.env.development.local}"

# ─── Parse arguments ────────────────────────────────────
if [ $# -lt 2 ]; then
  echo "Usage: $0 <project-name> <story-id> [slug]"
  echo "Example: $0 citizen-report-api US-07-01 list-reports"
  exit 1
fi

PROJECT="$1"
STORY_ID="$2"
SLUG="${3:-}"
BRANCH_NAME="feature/${STORY_ID}${SLUG:+-$SLUG}"

PROJECT_DIR="$REPO_ROOT/solutions/$PROJECT"
WORKTREE_DIR="$REPO_ROOT/solutions/worktrees/$PROJECT/$STORY_ID"

# ─── Validate project ──────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ ERROR: Project directory not found: $PROJECT_DIR"
  echo "Available projects:"
  ls -d "$REPO_ROOT/solutions"/*/ 2>/dev/null | xargs -I{} basename {} | grep -v worktrees
  exit 1
fi

if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ ERROR: $PROJECT_DIR is not a git repository"
  exit 1
fi

# ─── Ensure base branch exists ─────────────────────────
if ! git -C "$PROJECT_DIR" rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
  echo "⚠ Base branch '$BASE_BRANCH' not found in $PROJECT. Creating from main..."
  git -C "$PROJECT_DIR" branch "$BASE_BRANCH" main 2>/dev/null || {
    echo "❌ ERROR: Cannot create '$BASE_BRANCH' branch. Ensure 'main' exists."
    exit 1
  }
fi

# ─── Create worktree ────────────────────────────────────
if [ -d "$WORKTREE_DIR" ]; then
  echo "⚠ Worktree already exists at $WORKTREE_DIR — skipping creation."
else
  echo "📁 Creating worktree: $WORKTREE_DIR"
  echo "   Branch: $BRANCH_NAME (from $BASE_BRANCH)"
  git -C "$PROJECT_DIR" worktree add \
    "$WORKTREE_DIR" \
    -b "$BRANCH_NAME" "$BASE_BRANCH" 2>&1
fi

# ─── Set git author ─────────────────────────────────────
if [ -n "$AUTHOR_NAME" ] && [ -n "$AUTHOR_EMAIL" ]; then
  git -C "$WORKTREE_DIR" config user.name "$AUTHOR_NAME"
  git -C "$WORKTREE_DIR" config user.email "$AUTHOR_EMAIL"
  echo "👤 Author: $AUTHOR_NAME <$AUTHOR_EMAIL>"
else
  echo "⚠ WARNING: No git author configured. Set FORGE_AUTHOR_NAME/EMAIL in .forge/config.env"
fi

# ─── Copy secret/config files ──────────────────────────
echo "📋 Copying untracked config files..."
IFS=',' read -ra FILES <<< "$SECRET_FILES"
COPIED=0
for pattern in "${FILES[@]}"; do
  pattern="$(echo "$pattern" | xargs)"  # trim whitespace
  SRC="$PROJECT_DIR/$pattern"
  DEST="$WORKTREE_DIR/$pattern"
  if [ -f "$SRC" ]; then
    mkdir -p "$(dirname "$DEST")"
    cp "$SRC" "$DEST"
    echo "   ✓ $pattern"
    COPIED=$((COPIED + 1))
  fi
done

if [ "$COPIED" -eq 0 ]; then
  echo "   (no secret files found to copy)"
fi

# ─── Summary ────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo "  ✅ Worktree ready: $WORKTREE_DIR"
echo "  Branch:  $BRANCH_NAME"
echo "  Base:    $BASE_BRANCH"
echo "  Author:  $AUTHOR_NAME <$AUTHOR_EMAIL>"
echo "  Files:   $COPIED secret file(s) copied"
echo "════════════════════════════════════════════════════"
echo ""
echo "Next: cd $WORKTREE_DIR && start implementing"
