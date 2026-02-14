#!/usr/bin/env bash
set -Eeuo pipefail

# release.sh
#
# Description:
#   Creates a release by tagging the current version and preparing the next development cycle.
#
# Usage:
#   ./release.sh
#
# Prerequisites:
#   - Git repository
#   - GitHub CLI (gh) installed and authenticated
#   - version.txt file at repository root
#
# Workflow:
#   Phase 1: Create release tag
#     1. Read current version from version.txt (X.Y.Z-aN)
#     2. Create temporary branch with version.txt set to X.Y.Z
#     3. Create and push tag vX.Y.Z
#     4. Delete temporary branch
#   Phase 2: Create version bump PR
#     5. Create branch with version.txt set to X.Y+1.0-a0
#     6. Create PR to main

error() {
    echo "Error: $1" >&2
    exit 1
}

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-a[0-9]+)?$ ]]; then
        error "Invalid version format: $version (expected X.Y.Z or X.Y.Z-aN)"
    fi
}

get_release_version() {
    local version="$1"
    echo "${version%-a*}"
}

get_next_dev_version() {
    local version="$1"
    local release_version
    release_version=$(get_release_version "$version")

    local major minor _patch
    IFS='.' read -r major minor _patch <<< "$release_version"

    minor=$((minor + 1))
    echo "${major}.${minor}.0-a0"
}

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
    fi
    
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI is not authenticated. Run 'gh auth login'"
    fi
}

check_git_clean() {
    if [[ -n "$(git status --porcelain)" ]]; then
        error "Working directory has uncommitted changes. Commit or stash them first"
    fi
}

# Main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$REPO_ROOT/version.txt"

# Check prerequisites
check_gh_cli
check_git_clean

# Read current version
if [[ ! -f "$VERSION_FILE" ]]; then
    error "version.txt not found at repository root"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")
validate_version "$CURRENT_VERSION"

# Calculate versions
RELEASE_VERSION=$(get_release_version "$CURRENT_VERSION")
NEXT_DEV_VERSION=$(get_next_dev_version "$CURRENT_VERSION")

echo "Current version: $CURRENT_VERSION"
echo "Release version: $RELEASE_VERSION"
echo "Next dev version: $NEXT_DEV_VERSION"
echo ""

# Phase 1: Create release tag
echo "=== Phase 1: Creating release tag ==="
echo ""

# Create temporary branch for release
RELEASE_BRANCH="$RELEASE_VERSION"
echo "Creating temporary branch $RELEASE_BRANCH..."
git checkout -b "$RELEASE_BRANCH"

# Update version.txt to release version
echo "Setting version.txt to $RELEASE_VERSION..."
echo -n "$RELEASE_VERSION" > "$VERSION_FILE"
git add "$VERSION_FILE"
git commit -m "$RELEASE_VERSION"

# Create and push tag
TAG_NAME="v$RELEASE_VERSION"
echo "Creating tag $TAG_NAME..."
git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
echo "Pushing tag $TAG_NAME..."
git push origin "$TAG_NAME"
echo "Tag pushed successfully"
echo ""

# Delete temporary branch
echo "Deleting temporary branch $RELEASE_BRANCH..."
git checkout main
git branch -D "$RELEASE_BRANCH"
echo ""

# Phase 2: Create version bump PR
echo "=== Phase 2: Creating version bump PR ==="
echo ""

# Create branch for version bump
VERSION_BUMP_BRANCH="$NEXT_DEV_VERSION"
echo "Creating branch $VERSION_BUMP_BRANCH..."
git checkout -b "$VERSION_BUMP_BRANCH"

# Update version.txt to next dev version
echo "Setting version.txt to $NEXT_DEV_VERSION..."
echo -n "$NEXT_DEV_VERSION" > "$VERSION_FILE"
git add "$VERSION_FILE"
git commit -m "$NEXT_DEV_VERSION"
git push origin "$VERSION_BUMP_BRANCH"
echo "Changes committed and pushed"
echo ""

# Create PR
echo "Creating pull request..."
PR_URL=$(gh pr create --base main --head "$VERSION_BUMP_BRANCH" --title "$NEXT_DEV_VERSION" --body "Automated version bump after release $RELEASE_VERSION")
echo "Pull request created: $PR_URL"
echo ""

# Switch back to main
git checkout main

echo "Release $RELEASE_VERSION completed successfully!"
echo "Tag: $TAG_NAME"
echo "PR: $PR_URL"

