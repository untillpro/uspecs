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
#   1. Read current version from version.txt
#   2. Validate version format
#   3. Create release version (remove pre-release identifier)
#   4. Create and push git tag
#   5. Create version branch
#   6. Bump to next development version
#   7. Commit and create PR

error() {
    echo "Error: $1" >&2
    exit 1
}

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-a\.[0-9]+)?$ ]]; then
        error "Invalid version format: $version (expected X.Y.Z or X.Y.Z-a.N)"
    fi
}

get_release_version() {
    local version="$1"
    echo "$version" | sed 's/-a\.[0-9]*$//'
}

get_next_dev_version() {
    local version="$1"
    local release_version
    release_version=$(get_release_version "$version")

    local major minor patch
    IFS='.' read -r major minor patch <<< "$release_version"

    minor=$((minor + 1))
    echo "${major}.${minor}.0-a.0"
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

# Create and push tag
echo "Creating tag $RELEASE_VERSION..."
git tag -a "$RELEASE_VERSION" -m "Release $RELEASE_VERSION"
git push origin "$RELEASE_VERSION"
echo "Tag pushed successfully"
echo ""

# Create version branch
BRANCH_NAME="version $RELEASE_VERSION"
echo "Creating branch $BRANCH_NAME..."
git checkout -b "$BRANCH_NAME"
echo ""

# Update version file
echo "Updating version to $NEXT_DEV_VERSION..."
echo -n "$NEXT_DEV_VERSION" > "$VERSION_FILE"

# Commit changes
COMMIT_MSG="Bump version to $NEXT_DEV_VERSION for next development cycle"
git add "$VERSION_FILE"
git commit -m "$COMMIT_MSG"
git push origin "$BRANCH_NAME"
echo "Changes committed and pushed"
echo ""

# Create PR
echo "Creating pull request..."
PR_URL=$(gh pr create --base main --head "$BRANCH_NAME" --title "$COMMIT_MSG" --body "Automated version bump after release $RELEASE_VERSION")
echo "Pull request created: $PR_URL"
echo ""

# Switch back to main
git checkout main

echo "Release $RELEASE_VERSION completed successfully!"
echo "PR: $PR_URL"

