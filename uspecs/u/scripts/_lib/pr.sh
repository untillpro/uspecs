#!/usr/bin/env bash
set -Eeuo pipefail

# pr.sh -- Git branch and pull request automation
#
# Provides reusable commands for the PR workflow: branch creation from a
# remote default branch, and PR submission via GitHub CLI.
#
# Concepts:
#   pr_remote   The remote that owns the target branch for PRs.
#               "upstream" when a fork setup is detected, otherwise "origin".
#
# Usage:
#   pr.sh info
#       Output PR configuration in key=value format:
#         pr_remote=<upstream|origin>
#         main_branch=<branch-name>
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

determine_pr_remote() {
    if git remote | grep -q '^upstream$'; then
        echo "upstream"
    else
        echo "origin"
    fi
}

main_branch_name() {
    local branch
    branch=$(git ls-remote --symref origin HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}') || {
        error "Cannot determine the default branch from remote"
    }
    if [[ -z "$branch" ]]; then
        error "Cannot determine the default branch from remote"
    fi
    echo "$branch"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_info() {
    local pr_remote main_branch
    pr_remote=$(determine_pr_remote)
    main_branch=$(main_branch_name)
    echo "pr_remote=$pr_remote"
    echo "main_branch=$main_branch"
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

    local pr_url
    if [[ "$pr_remote" == "upstream" ]]; then
        local origin_owner
        origin_owner="$(git remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##; s#/.*##')"
        pr_url=$(gh pr create "${pr_args[@]}" --head "${origin_owner}:${branch_name}")
    else
        pr_url=$(gh pr create "${pr_args[@]}" --head "$branch_name")
    fi
    echo "Pull request created successfully!"

    echo "Switching to $next_branch..."
    git checkout "$next_branch"
    if [[ "$delete_branch" == "true" ]]; then
        echo "Deleting local branch $branch_name..."
        git branch -d "$branch_name"
        echo "Deleting local reference to remote branch..."
        git branch -dr "origin/$branch_name"
    fi

    # Output PR info for caller to parse (to stderr so it doesn't interfere with normal output)
    echo "PR_URL=$pr_url" >&2
    echo "PR_BRANCH=$branch_name" >&2
    echo "PR_BASE=$main_branch" >&2
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    error "Usage: pr.sh <info|prbranch|pr> [args...]"
fi

command="$1"; shift
case "$command" in
    info)     cmd_info "$@" ;;
    prbranch) cmd_prbranch "$@" ;;
    pr)       cmd_pr "$@" ;;
    *)        error "Unknown command: $command. Available: info, prbranch, pr" ;;
esac
