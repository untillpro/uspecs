#!/usr/bin/env bash
set -Eeuo pipefail

# pr.sh -- Git branch and pull request automation
#
# Provides reusable commands for the PR workflow: prerequisite checks,
# branch creation from a remote default branch, and PR submission via
# GitHub CLI.
#
# Concepts:
#   pr_remote   The remote that owns the target branch for PRs.
#               "upstream" when a fork setup is detected, otherwise "origin".
#
# Usage:
#   pr.sh check
#       Validate prerequisites: git repository, GitHub CLI, origin remote,
#       and clean working directory.
#
#   pr.sh prbranch <name>
#       Fetch pr_remote and create a local branch from its default branch.
#
#   pr.sh pr --title <title> --body <body> --next-branch <branch> [--delete-branch]
#       Stage all changes, commit, push to origin, and open a PR against
#       pr_remote's default branch. Switch to --next-branch afterwards.
#       If --delete-branch is set, delete the current branch after switching.
#       If no changes exist, switch to --next-branch and exit cleanly.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

error() {
    echo "Error: $1" >&2
    exit 1
}

find_git_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

determine_pr_remote() {
    if git remote | grep -q '^upstream$'; then
        echo "upstream"
    else
        echo "origin"
    fi
}

main_branch_name() {
    local branch
    branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || {
        error "Cannot determine the default branch. Run: git remote set-head origin --auto"
    }
    echo "${branch#origin/}"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_check() {
    if ! find_git_root > /dev/null 2>&1; then
        error "No git repository found"
    fi
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
    fi
    if ! git remote | grep -q '^origin$'; then
        error "'origin' remote does not exist"
    fi
    if [[ -n $(git status --porcelain) ]]; then
        error "Working directory has uncommitted changes. Commit or stash changes first"
    fi
}

cmd_prbranch() {
    local name="${1:-}"
    [[ -z "$name" ]] && error "Usage: pr.sh prbranch <name>"

    local pr_remote main_branch
    pr_remote=$(determine_pr_remote)
    main_branch=$(main_branch_name)

    echo "Fetching $pr_remote..."
    git fetch "$pr_remote"

    echo "Creating branch: $name"
    git checkout -b "$name" "$pr_remote/$main_branch"
}

cmd_pr() {
    local title="" body="" next_branch="" delete_branch=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)         title="$2";       shift 2 ;;
            --body)          body="$2";        shift 2 ;;
            --next-branch)   next_branch="$2"; shift 2 ;;
            --delete-branch) delete_branch=true; shift ;;
            *) error "Unknown flag: $1" ;;
        esac
    done
    [[ -z "$title" ]]       && error "--title is required"
    [[ -z "$body" ]]        && error "--body is required"
    [[ -z "$next_branch" ]] && error "--next-branch is required"

    local main_branch branch_name
    main_branch=$(main_branch_name)
    branch_name=$(git symbolic-ref --short HEAD)

    if [[ "$delete_branch" == "true" && "$branch_name" == "$next_branch" ]]; then
        error "Cannot delete branch '$branch_name' because it is the same as --next-branch"
    fi

    # Nothing to commit -- switch to next branch and exit
    if [[ -z $(git status --porcelain) ]]; then
        echo "No changes to commit. Cleaning up..."
        git checkout "$next_branch"
        if [[ "$delete_branch" == "true" ]]; then
            git branch -d "$branch_name"
        fi
        echo "No updates were needed."
        return 0
    fi

    local pr_remote
    pr_remote=$(determine_pr_remote)

    echo "Committing changes..."
    git add -A
    git commit -m "$title"

    echo "Pushing branch to origin..."
    git push -u origin "$branch_name"

    echo "Creating pull request to $pr_remote..."
    local pr_repo
    pr_repo="$(git remote get-url "$pr_remote" | sed -E 's#.*github.com[:/]##; s#\.git$##')"
    local pr_args=('--repo' "$pr_repo" '--base' "$main_branch" '--title' "$title" '--body' "$body")

    if [[ "$pr_remote" == "upstream" ]]; then
        local origin_owner
        origin_owner="$(git remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##; s#/.*##')"
        gh pr create "${pr_args[@]}" --head "${origin_owner}:${branch_name}"
    else
        gh pr create "${pr_args[@]}" --head "$branch_name"
    fi
    echo "Pull request created successfully!"

    echo "Switching to $next_branch..."
    git checkout "$next_branch"
    if [[ "$delete_branch" == "true" ]]; then
        echo "Deleting local branch $branch_name..."
        git branch -d "$branch_name"
    fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    error "Usage: pr.sh <check|prbranch|pr> [args...]"
fi

command="$1"; shift
case "$command" in
    check)    cmd_check "$@" ;;
    prbranch) cmd_prbranch "$@" ;;
    pr)       cmd_pr "$@" ;;
    *)        error "Unknown command: $command. Available: check, prbranch, pr" ;;
esac
