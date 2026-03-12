#!/usr/bin/env bash
set -Eeuo pipefail

# uspecs automation
#
# Usage:
#   uspecs change new <change-name> [--issue-url <url>] [--no-branch] [--branch]
#   uspecs change archive <change-folder-name> [-d] | --all
#   uspecs pr preflight
#   uspecs pr create --title <title> [--body <body>]
#   uspecs diff specs
#
# change new:
#   Creates Change Folder and change.md with frontmatter:
#     - Folder: <changes_folder from conf.md>/ymdHM-<change-name>
#     - registered_at: YYYY-MM-DDTHH:MM:SSZ
#     - change_id: ymdHM-<change-name>
#     - baseline: <commit-hash> (if git repository)
#     - issue_url: <url> (if --issue-url provided)
#   Creates git branch by default (skip with --no-branch; --branch forces creation explicitly)
#   Prints: <relative-path-to-change-folder> (e.g. uspecs/changes/2602201746-my-change)
#
# change archive [-d] [--all]:
#   Archives change folder to <changes-folder>/archive/yymm/ymdHM-<change-name>
#   Adds archived_at metadata and updates folder date prefix
#   -d: commit and push staged changes, checkout default branch, delete branch and refs
#       Requires git repository, clean working tree, PR branch (ending with --pr)
#   --all: archive all change folders with modifications vs pr_remote/default_branch
#          No change-folder-name needed; mutually exclusive with -d
#
# pr preflight --change-folder <path>:
#   Checks for uncompleted todo items in Change Folder, then validates preconditions, fetches
#   pr_remote/default_branch, and merges it into the current branch.
#   On success outputs: change_branch=<name>, default_branch=<name>, change_branch_head=<sha>
#
# pr create --title <title> --body <body>:
#   Creates a PR from the current change branch (delegates to _lib/pr.sh changepr).
#   Body can be passed via --body or piped via stdin.
#   Literal \n sequences in --body are decoded to actual newlines.
#
# diff specs:
#   Outputs git diff of the specs folder between HEAD and pr_remote/default_branch.

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_baseline() {
    local project_dir="$1"
    if is_git_repo "$project_dir"; then
        (cd "$project_dir" && git rev-parse HEAD 2>/dev/null) || echo ""
    else
        echo ""
    fi
}

get_folder_name() {
    local path="$1"
    basename "$path"
}

count_uncompleted_items() {
    local folder="$1"
    local count
    count=$(grep -r "^[[:space:]]*-[[:space:]]*\[ \]" "$folder"/*.md 2>/dev/null | wc -l)
    echo "${count:-0}" | tr -d ' '
}

extract_change_name() {
    local folder_name="$1"
    echo "$folder_name" | sed 's/^[0-9]\{10\}-//'
}

move_folder() {
    local source="$1"
    local destination="$2"
    local project_dir="${3:-}"
    local check_dir="${project_dir:-$PWD}"
    if is_git_repo "$check_dir"; then
        if [[ -n "$project_dir" ]]; then
            local rel_src="${source#"$project_dir/"}"
            local rel_dst="${destination#"$project_dir/"}"
            (cd "$project_dir" && git mv "$rel_src" "$rel_dst" 2>/dev/null) || mv "$source" "$destination"
        else
            git mv "$source" "$destination" 2>/dev/null || mv "$source" "$destination"
        fi
    else
        mv "$source" "$destination"
    fi
}

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# shellcheck source=_lib/utils.sh
source "$(get_script_dir)/_lib/utils.sh"

get_project_dir() {
    local script_dir
    script_dir=$(get_script_dir)
    # scripts/ -> u/ -> uspecs/ -> project root
    cd "$script_dir/../../.." && pwd
}

cmd_status_ispr() {
    local project_dir
    project_dir=$(get_project_dir)
    if ! is_git_repo "$project_dir"; then
        return 0
    fi
    local branch
    branch=$(cd "$project_dir" && git branch --show-current 2>&1)
    if [[ "$branch" == *"--pr" ]]; then
        echo "yes"
    fi
}

read_conf_param() {
    local param_name="$1"
    local conf_file
    conf_file="$(get_project_dir)/uspecs/u/conf.md"

    if [ ! -f "$conf_file" ]; then
        error "conf.md not found: $conf_file"
    fi

    local line raw
    line=$(grep -E "^- ${param_name}:" "$conf_file" | head -1 || true)
    raw="${line#*: }"

    if [ -z "$raw" ]; then
        error "Parameter '${param_name}' not found in conf.md"
    fi

    # trim leading/trailing whitespace and surrounding backticks
    local value
    value=$(echo "$raw" | sed 's/^[[:space:]`]*//' | sed 's/[[:space:]`]*$//')

    echo "$value"
}

cmd_change_new() {
    local change_name=""
    local issue_url=""
    local opt_branch=""
    local opt_no_branch=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --issue-url)
                if [[ $# -lt 2 || -z "$2" ]]; then
                    error "--issue-url requires a URL argument"
                fi
                issue_url="$2"
                shift 2
                ;;
            --branch)
                opt_branch="1"
                shift
                ;;
            --no-branch)
                opt_no_branch="1"
                shift
                ;;
            *)
                if [ -z "$change_name" ]; then
                    change_name="$1"
                    shift
                else
                    error "Unknown argument: $1"
                fi
                ;;
        esac
    done

    if [ -n "$opt_branch" ] && [ -n "$opt_no_branch" ]; then
        error "--branch and --no-branch are mutually exclusive"
    fi

    local is_new_branch="1"
    if [ -n "$opt_no_branch" ]; then
        is_new_branch=""
    fi

    if [ -z "$change_name" ]; then
        error "change-name is required"
    fi

    if [[ ! "$change_name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
        error "change-name must be kebab-case (lowercase letters, numbers, hyphens): $change_name"
    fi

    local changes_folder_rel
    changes_folder_rel=$(read_conf_param "changes_folder")

    local project_dir
    project_dir=$(get_project_dir)

    local changes_folder="$project_dir/$changes_folder_rel"

    if [ ! -d "$changes_folder" ]; then
        error "Changes folder not found: $changes_folder"
    fi

    local timestamp
    timestamp=$(date -u +"%y%m%d%H%M")

    local folder_name="${timestamp}-${change_name}"
    local change_folder="$changes_folder/$folder_name"

    if [ -d "$change_folder" ]; then
        error "Change folder already exists: $change_folder"
    fi

    mkdir -p "$change_folder"

    local registered_at baseline
    registered_at=$(get_timestamp)
    baseline=$(get_baseline "$project_dir")

    local frontmatter="---"$'\n'
    frontmatter+="registered_at: $registered_at"$'\n'
    frontmatter+="change_id: $folder_name"$'\n'

    if [ -n "$baseline" ]; then
        frontmatter+="baseline: $baseline"$'\n'
    fi

    if [ -n "$issue_url" ]; then
        frontmatter+="issue_url: $issue_url"$'\n'
    fi

    frontmatter+="---"

    printf '%s\n' "$frontmatter" > "$change_folder/change.md"

    if [ -n "$is_new_branch" ]; then
        if is_git_repo "$project_dir"; then
            if ! (cd "$project_dir" && git checkout -b "$change_name"); then
                echo "Warning: Failed to create branch '$change_name'" >&2
            fi
        else
            echo "Warning: Not a git repository, cannot create branch" >&2
        fi
    fi

    echo "$changes_folder_rel/$folder_name"
}

convert_links_to_relative() {
    local folder="$1"

    if [ -z "$folder" ]; then
        error "folder path is required for convert_links_to_relative"
    fi

    if [ ! -d "$folder" ]; then
        error "Folder not found: $folder"
    fi

    # Find all .md files in the folder
    local md_files
    md_files=$(find "$folder" -maxdepth 1 -name "*.md" -type f)

    if [ -z "$md_files" ]; then
        # No markdown files to process, return success
        return 0
    fi

    # Process each markdown file
    while IFS= read -r file; do
        # Archive moves folder 2 levels deeper (changes/ -> changes/archive/yymm/)
        # Only paths starting with ../ need adjustment - add ../../ prefix
        #
        # Example: ](../foo) -> ](../../../foo)
        #
        # Skip (do not modify):
        # - http://, https:// (absolute URLs)
        # - # (anchors)
        # - / (absolute paths)
        # - ./ (current directory - stays in same folder)
        # - filename.ext (same folder files like impl.md, issue.md)

        # Add ../../ prefix to paths starting with ../
        # ](../ -> ](../../../
        if ! sed_inplace "$file" -E 's#\]\(\.\./#](../../../#g'; then
            error "Failed to convert links in file: $file"
        fi
    done <<< "$md_files"

    return 0
}

cmd_pr_preflight() {
    local change_folder_path=""
    local preflight_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --change-folder) change_folder_path="$2"; shift 2 ;;
            *) preflight_args+=("$1"); shift ;;
        esac
    done
    if [ -z "$change_folder_path" ]; then
        error "pr preflight requires --change-folder <path>"
    fi
    if [ ! -d "$change_folder_path" ]; then
        error "Change folder not found: $change_folder_path"
    fi
    local uncompleted_count
    uncompleted_count=$(count_uncompleted_items "$change_folder_path")
    if [ "$uncompleted_count" -gt 0 ]; then
        echo "Cannot create PR: $uncompleted_count uncompleted todo item(s) found"
        echo ""
        echo "Uncompleted items:"
        grep -rn "^[[:space:]]*-[[:space:]]*\[ \]" "$change_folder_path"/*.md 2>/dev/null | sed 's/^/  /'
        echo ""
        echo "Complete or cancel todo items before creating a PR"
        exit 1
    fi
    local lib_dir
    lib_dir="$(get_script_dir)/_lib"
    "$lib_dir/pr.sh" mergedef "${preflight_args[@]+"${preflight_args[@]}"}"
}

cmd_change_archiveall() {
    if [ $# -gt 0 ]; then
        error "change archiveall takes no arguments"
    fi

    local changes_folder_rel
    changes_folder_rel=$(read_conf_param "changes_folder")

    local project_dir
    project_dir=$(get_project_dir)

    if ! is_git_repo "$project_dir"; then
        error "change archiveall requires a git repository"
    fi

    local pr_sh
    pr_sh="$(get_script_dir)/_lib/pr.sh"
    local -A pr_info
    if ! get_pr_info "$pr_sh" pr_info "$project_dir"; then
        error "change archiveall requires remote info to be available (remote reachable?)"
    fi
    local default_branch="${pr_info[default_branch]:-}"
    local pr_remote="${pr_info[pr_remote]:-}"

    local changes_folder="$project_dir/$changes_folder_rel"

    echo "Fetching ${pr_remote}/${default_branch}..."
    (cd "$project_dir" && git fetch "$pr_remote" "$default_branch" 2>&1)

    if [ ! -d "$changes_folder" ]; then
        error "Changes folder not found: $changes_folder"
    fi

    local archived=0 unchanged=0 failed=0
    local script_path
    script_path="$(get_script_dir)/uspecs.sh"

    for folder_path in "$changes_folder"/*/; do
        [ -d "$folder_path" ] || continue
        local fname
        fname=$(basename "$folder_path")
        [ "$fname" = "archive" ] && continue

        local rel_folder="$changes_folder_rel/$fname"
        local diff_output
        diff_output=$(cd "$project_dir" && git diff --name-only "${pr_remote}/${default_branch}" HEAD -- "$rel_folder")
        if [ -z "$diff_output" ]; then
            unchanged=$((unchanged + 1))
            continue
        fi

        if bash "$script_path" change archive "$fname"; then
            archived=$((archived + 1))
        else
            echo "Warning: could not archive $fname" >&2
            failed=$((failed + 1))
        fi
    done

    echo "Done: $archived archived, $unchanged unchanged, $failed failed"
}

cmd_change_archive() {
    local folder_name=""
    local delete_branch=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)
                delete_branch="1"
                shift
                ;;
            *)
                if [ -z "$folder_name" ]; then
                    folder_name="$1"
                    shift
                else
                    error "Unknown argument: $1"
                fi
                ;;
        esac
    done

    if [ -z "$folder_name" ]; then
        error "change-folder-name is required"
    fi

    local changes_folder_rel
    changes_folder_rel=$(read_conf_param "changes_folder")

    local project_dir
    project_dir=$(get_project_dir)

    local is_git=""
    if is_git_repo "$project_dir"; then
        is_git="1"
    fi

    if [ -n "$delete_branch" ] && [ -z "$is_git" ]; then
        error "-d requires a git repository"
    fi

    local changes_folder="$project_dir/$changes_folder_rel"

    local path_to_change_folder="$changes_folder/$folder_name"

    if [ ! -d "$path_to_change_folder" ]; then
        error "Folder not found: $path_to_change_folder"
    fi

    local change_file="$path_to_change_folder/change.md"
    if [ ! -f "$change_file" ]; then
        error "change.md not found in folder: $path_to_change_folder"
    fi

    if [[ "$folder_name" == archive/* ]]; then
        error "Folder is already in archive: $folder_name"
    fi

    local uncompleted_count
    uncompleted_count=$(count_uncompleted_items "$path_to_change_folder")

    if [ "$uncompleted_count" -gt 0 ]; then
        echo "Cannot archive: $uncompleted_count uncompleted todo item(s) found"
        echo ""
        echo "Uncompleted items:"
        grep -rn "^[[:space:]]*-[[:space:]]*\[ \]" "$path_to_change_folder"/*.md 2>/dev/null | sed 's/^/  /'
        echo ""
        echo "Complete or cancel todo items before archiving"
        exit 1
    fi

    local change_name
    change_name=$(extract_change_name "$folder_name")

    if [ -n "$delete_branch" ] && [ -n "$is_git" ]; then
        local branch_name
        branch_name=$(cd "$project_dir" && git symbolic-ref --short HEAD 2>/dev/null || echo "")
        if [ -z "$branch_name" ]; then
            error "-d requires a named branch (HEAD is detached)"
        fi

        local -A pr_info
        local pr_sh
        pr_sh="$(get_script_dir)/_lib/pr.sh"
        if ! get_pr_info "$pr_sh" pr_info; then
            error "-d requires pr.sh info to be available (remote reachable?)"
        fi
        local default_branch="${pr_info[default_branch]:-}"
        local pr_remote="${pr_info[pr_remote]:-}"

        # a) no uncommitted changes
        local git_status
        git_status=$(cd "$project_dir" && git status --porcelain)
        if [ -n "$git_status" ]; then
            error "-d requires a clean working tree (uncommitted changes found)"
        fi

        # b) branch must not be the default branch
        if [ "$branch_name" = "$default_branch" ]; then
            error "-d cannot be used on the default branch '$default_branch'"
        fi

        # c) check whether the remote branch actually exists
        # exit non-zero means remote unreachable/auth failed -- treat as hard error, not as "branch gone"
        local remote_exists
        if ! remote_exists=$(cd "$project_dir" && git ls-remote --heads "${pr_remote:-origin}" "$branch_name"); then
            error "Cannot reach remote '${pr_remote:-origin}'. Check connectivity and authentication."
        fi

        # d) no divergence (skip when remote branch is already gone)
        if [ -n "$remote_exists" ]; then
            (cd "$project_dir" && git fetch "${pr_remote:-origin}" "$branch_name" 2>&1)
            local behind
            behind=$(cd "$project_dir" && git rev-list --count "HEAD..${pr_remote:-origin}/$branch_name")
            if [ "$behind" -gt 0 ]; then
                error "Branch '$branch_name' is behind ${pr_remote:-origin} by $behind commit(s). Pull or rebase first."
            fi
        fi

        # e) branch must be a PR branch
        if [[ "$branch_name" != *--pr ]]; then
            error "-d can only be used on a PR branch (must end with '--pr'): '$branch_name'"
        fi

        # f) PR branch with remote gone: skip archive, just refresh default and switch
        if [ -z "$remote_exists" ]; then
            echo "Remote branch '${pr_remote:-origin}/$branch_name' no longer exists; skipping archive."
            echo "Switching to $default_branch..."
            if ! (cd "$project_dir" && git checkout "$default_branch" 2>&1); then
                error "Failed to checkout '$default_branch'. Resolve manually."
            fi

            local deleted_branch_hash=""
            if (cd "$project_dir" && git show-ref --verify --quiet "refs/heads/$branch_name"); then
                deleted_branch_hash=$(cd "$project_dir" && git rev-parse "refs/heads/$branch_name")
                (cd "$project_dir" && git branch -D "$branch_name" 2>&1)
            fi
            (cd "$project_dir" && git branch -dr "${pr_remote:-origin}/$branch_name") 2>/dev/null || true

            if [ -n "$deleted_branch_hash" ]; then
                echo "Deleted branch: $branch_name ($deleted_branch_hash)"
                echo "To restore: git branch $branch_name $deleted_branch_hash"
            fi

            echo "Updating local $default_branch from ${pr_remote:-origin}/$default_branch..."
            (cd "$project_dir" && git fetch "${pr_remote:-origin}" "$default_branch" 2>&1)
            if ! (cd "$project_dir" && git merge --ff-only "${pr_remote:-origin}/$default_branch" 2>&1); then
                error "Cannot fast-forward '$default_branch' to '${pr_remote:-origin}/$default_branch' (branches have diverged). Run 'git rebase' or resolve manually."
            fi

            echo "Done: skipped archive (remote branch gone), switched to $default_branch"
            return 0
        fi
    fi

    local timestamp
    timestamp=$(get_timestamp)

    # Insert archived_at into YAML front matter (before closing ---)
    local temp_file
    temp_file=$(mktemp)
    awk -v ts="$timestamp" '
        /^---$/ {
            if (count == 0) {
                print
                count++
            } else {
                print "archived_at: " ts
                print
            }
            next
        }
        /^archived_at:/ { next }
        { print }
    ' "$change_file" > "$temp_file"
    if cat "$temp_file" > "$change_file"; then
        :  # Success, continue
    else
        return 1
    fi

    # Add ../ prefix to relative links for archive folder depth
    if ! convert_links_to_relative "$path_to_change_folder"; then
        error "Failed to convert links to relative paths"
    fi

    local archive_folder="$changes_folder/archive"

    local date_prefix
    date_prefix=$(date -u +"%y%m%d%H%M")

    # Extract yymm for subfolder
    local yymm_prefix="${date_prefix:0:4}"

    local archive_subfolder="$archive_folder/$yymm_prefix"
    mkdir -p "$archive_subfolder"

    local archive_path="$archive_subfolder/${date_prefix}-${change_name}"

    if [ -d "$archive_path" ]; then
        error "Archive folder already exists: $archive_path"
    fi

    if [ -n "$is_git" ]; then
        local rel_change_folder="${path_to_change_folder#"$project_dir/"}"
        (cd "$project_dir" && git add "$rel_change_folder")
    fi

    move_folder "$path_to_change_folder" "$archive_path" "$project_dir"

    if [ -n "$is_git" ]; then
        local rel_archive_path="${archive_path#"$project_dir/"}"
        (cd "$project_dir" && git add "$rel_archive_path")
    fi

    if [ -n "$delete_branch" ] && [ -n "$is_git" ]; then
        (cd "$project_dir" && git commit -m "archive $rel_change_folder to $rel_archive_path" 2>&1)
        if [ -n "$remote_exists" ]; then
            if ! (cd "$project_dir" && git push 2>&1); then
                local archive_commit
                archive_commit=$(cd "$project_dir" && git rev-parse HEAD)
                error "Push to '${pr_remote:-origin}/$branch_name' failed. Branch '$branch_name' preserved (archive commit: $archive_commit). Resolve the push issue and re-run the archive command."
            fi
        else
            echo "Remote branch '${pr_remote:-origin}/$branch_name' no longer exists; skipping push."
        fi

        if ! (cd "$project_dir" && git checkout "$default_branch" 2>&1); then
            error "Failed to checkout '$default_branch'. Resolve manually."
        fi

        local deleted_branch_hash=""
        if (cd "$project_dir" && git show-ref --verify --quiet "refs/heads/$branch_name"); then
            deleted_branch_hash=$(cd "$project_dir" && git rev-parse "refs/heads/$branch_name")
            (cd "$project_dir" && git branch -D "$branch_name" 2>&1)
        else
            echo "Warning: branch '$branch_name' not found, skipping branch deletion" >&2
        fi
        (cd "$project_dir" && git branch -dr "${pr_remote:-origin}/$branch_name") 2>/dev/null || true

        if [ -n "$deleted_branch_hash" ]; then
            echo "Deleted branch: $branch_name ($deleted_branch_hash)"
            echo "To restore: git branch $branch_name $deleted_branch_hash"
        fi

        echo "Updating local $default_branch from ${pr_remote:-origin}/$default_branch..."
        (cd "$project_dir" && git fetch "${pr_remote:-origin}" "$default_branch" 2>&1)
        if ! (cd "$project_dir" && git merge --ff-only "${pr_remote:-origin}/$default_branch" 2>&1); then
            error "Cannot fast-forward '$default_branch' to '${pr_remote:-origin}/$default_branch' (branches have diverged). Run 'git rebase' or resolve manually."
        fi
    fi

    echo "Archived change: $changes_folder_rel/archive/$yymm_prefix/${date_prefix}-${change_name}"
}

main() {
    git_path

    if [ $# -lt 1 ]; then
        error "Usage: uspecs <command> [args...]"
    fi

    local command="$1"
    shift

    local lib_dir
    lib_dir="$(get_script_dir)/_lib"

    case "$command" in
        change)
            if [ $# -lt 1 ]; then
                error "Usage: uspecs change <subcommand> [args...]"
            fi
            local subcommand="$1"
            shift

            case "$subcommand" in
                new)
                    cmd_change_new "$@"
                    ;;
                archive)
                    cmd_change_archive "$@"
                    ;;
                archiveall)
                    cmd_change_archiveall "$@"
                    ;;
                *)
                    error "Unknown change subcommand: $subcommand. Available: new, archive, archiveall"
                    ;;
            esac
            ;;
        pr)
            if [ $# -lt 1 ]; then
                error "Usage: uspecs pr <subcommand> [args...]"
            fi
            local subcommand="$1"
            shift

            case "$subcommand" in
                preflight)
                    cmd_pr_preflight "$@"
                    ;;
                create)
                    "$lib_dir/pr.sh" changepr "$@"
                    ;;
                *)
                    error "Unknown pr subcommand: $subcommand. Available: preflight, create"
                    ;;
            esac
            ;;
        diff)
            if [ $# -lt 1 ]; then
                error "Usage: uspecs diff <target>"
            fi
            local target="$1"
            shift

            case "$target" in
                specs)
                    "$lib_dir/pr.sh" diff specs "$@"
                    ;;
                *)
                    error "Unknown diff target: $target. Available: specs"
                    ;;
            esac
            ;;
        status)
            if [ $# -lt 1 ]; then
                error "Usage: uspecs status <subcommand> [args...]"
            fi
            local subcommand="$1"
            shift

            case "$subcommand" in
                ispr)
                    cmd_status_ispr "$@"
                    ;;
                *)
                    error "Unknown status subcommand: $subcommand. Available: ispr"
                    ;;
            esac
            ;;
        *)
            error "Unknown command: $command"
            ;;
    esac
}

main "$@"
