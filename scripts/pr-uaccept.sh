#!/usr/bin/env bash
set -Eeuo pipefail

# pr-uaccept.sh
#
# Description:
#   Handles "uaccept" PR comment automation:
#     1. Archives all active change requests via uspecs archiveall
#     2. Merges the pull request using squash option
#
# Usage:
#   PR_NUMBER=<number> ./scripts/pr-uaccept.sh
#
# Prerequisites:
#   - Git repository with GitHub remote
#   - GitHub CLI (gh) installed and authenticated via GH_TOKEN
#   - uspecs tooling available at uspecs/u/scripts/uspecs.sh
#
# Environment variables:
#   PR_NUMBER   - Pull request number to merge
#   COMMENT_ID  - ID of the "uaccept" comment to react to
#   GH_TOKEN    - GitHub token (used by gh CLI)

error() {
    echo "Error: $1" >&2
    exit 1
}

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
    fi

    if ! gh auth status &> /dev/null; then
        error "GitHub CLI is not authenticated. Run 'gh auth login' or set GH_TOKEN"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
USPECS_SH="$REPO_ROOT/uspecs/u/scripts/uspecs.sh"

# Validate prerequisites
check_gh_cli

if [[ -z "${PR_NUMBER:-}" ]]; then
    error "PR_NUMBER environment variable is required"
fi

if [[ -z "${COMMENT_ID:-}" ]]; then
    error "COMMENT_ID environment variable is required"
fi

if [[ ! -f "$USPECS_SH" ]]; then
    error "uspecs script not found at $USPECS_SH"
fi

echo "=== Step 1: React to uaccept comment ==="
gh api "repos/{owner}/{repo}/issues/comments/$COMMENT_ID/reactions" \
    -f content="+1" --silent
echo "Reaction added"
echo ""

echo "=== Step 2: Archive all active change requests ==="
bash "$USPECS_SH" change archiveall
echo "archiveall completed"
echo ""

echo "=== Step 2b: Commit archived changes ==="
cd "$REPO_ROOT"
if ! git diff --cached --quiet; then
    git commit -m "archive active changes before merge"
    git push
    echo "Archived changes committed and pushed"
else
    echo "No changes to commit"
fi
echo ""

echo "=== Step 3: Merge pull request #$PR_NUMBER with squash ==="
gh pr merge "$PR_NUMBER" --squash --auto --delete-branch
echo "Pull request #$PR_NUMBER queued for auto-merge"
echo ""

echo "=== Step 4: Post summary comment ==="
gh pr comment "$PR_NUMBER" --body "uaccept received: active changes archived, PR queued for squash merge, remote branch will be deleted after merge. Run \`uarchive\` locally to remove your local PR branch."
echo "Comment posted"

