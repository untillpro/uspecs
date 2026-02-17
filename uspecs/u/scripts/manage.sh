#!/usr/bin/env bash
set -Eeuo pipefail

# manage.sh
#
# Description:
#   Manages uspecs lifecycle: install, update, upgrade, and invocation type configuration
#
# Usage:
#   manage.sh install --nlia [--alpha] [--pr]
#   manage.sh update [--pr]
#   manage.sh upgrade [--pr]
#   manage.sh it --add nlia
#   manage.sh it --remove nlic
#
# Internal commands (not for direct use):
#   manage.sh apply <install|update|upgrade> --project-dir <dir> --version <ver> [--current-version <ver>] [flags...]


REPO_OWNER="untillpro"
REPO_NAME="uspecs"
ALPHA_BRANCH="${USPECS_ALPHA_BRANCH:-main}"
GITHUB_API="https://api.github.com"
GITHUB_RAW="https://raw.githubusercontent.com"

case "$OSTYPE" in
    msys*|cygwin*) _TMP_BASE=$(cygpath -w "$TEMP") ;;
    *)             _TMP_BASE="/tmp" ;;
esac

_TEMP_DIRS=()
_TEMP_FILES=()

error() {
    echo "Error: $1" >&2
    exit 1
}

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_project_dir() {
    local script_path="${BASH_SOURCE[0]}"
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        error "Cannot determine project directory: script path is not available"
    fi
    local script_dir
    script_dir=$(cd "$(dirname "$script_path")" && pwd)
    # Go up 3 levels: scripts -> u -> uspecs -> project_dir
    local project_dir
    project_dir=$(cd "$script_dir/../../.." && pwd)
    echo "$project_dir"
}

check_not_installed() {
    local project_dir="$1"
    if [[ -f "$project_dir/uspecs/u/uspecs.yml" ]]; then
        error "uspecs is already installed, use update instead"
    fi
}

check_installed() {
    local project_dir
    project_dir=$(get_project_dir)
    if [[ ! -f "$project_dir/uspecs/u/uspecs.yml" ]]; then
        error "uspecs is not installed"
    fi
}

check_pr_prerequisites() {
    # Check if git repository exists
    local dir="$PWD"
    local found_git=false
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            found_git=true
            break
        fi
        dir=$(dirname "$dir")
    done
    if [[ "$found_git" == "false" ]]; then
        error "No git repository found"
    fi

    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
    fi

    # Check if origin remote exists
    if ! git remote | grep -q '^origin$'; then
        error "'origin' remote does not exist"
    fi

    # Check if working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        error "Working directory has uncommitted changes. Commit or stash changes first"
    fi
}

read_config() {
    local project_dir
    project_dir=$(get_project_dir)
    local metadata_file="$project_dir/uspecs/u/uspecs.yml"

    if [[ ! -f "$metadata_file" ]]; then
        error "Installation metadata file not found: $metadata_file"
    fi

    cat "$metadata_file"
}

get_config_value() {
    local key="$1"
    local config
    config=$(read_config)
    echo "$config" | grep "^$key:" | sed "s/^$key: *//" | sed 's/^"\(.*\)"$/\1/' | sed 's/^\[\(.*\)\]$/\1/'
}

get_latest_tag() {
    curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/tags" | \
        grep '"name":' | \
        sed 's/.*"name": *"v\?\([^"]*\)".*/\1/' | \
        head -n 1
}

get_latest_minor_tag() {
    local current_version="$1"
    local major minor
    IFS='.' read -r major minor _ <<< "$current_version"

    curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/tags" | \
        grep '"name":' | \
        sed 's/.*"name": *"v\?\([^"]*\)".*/\1/' | \
        grep "^$major\.$minor\." | \
        head -n 1
}

get_latest_major_tag() {
    get_latest_tag
}

get_latest_commit_info() {
    local response
    response=$(curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$ALPHA_BRANCH")
    local sha
    sha=$(echo "$response" | grep '"sha":' | head -n 1 | sed 's/.*"sha": *"\([^"]*\)".*/\1/')
    local commit_date
    commit_date=$(echo "$response" | grep '"date":' | head -n 1 | sed 's/.*"date": *"\([^"]*\)".*/\1/')
    echo "$sha $commit_date"
}

get_alpha_version() {
    curl -fsSL "$GITHUB_RAW/$REPO_OWNER/$REPO_NAME/$ALPHA_BRANCH/version.txt" | tr -d '[:space:]'
}

is_alpha_version() {
    [[ "$1" == *-a* ]]
}

download_archive() {
    local ref="$1"
    local temp_dir="$2"

    local archive_url="https://github.com/$REPO_OWNER/$REPO_NAME/archive/$ref.tar.gz"
    curl -fsSL "$archive_url" | tar -xz -C "$temp_dir" --strip-components=1
}

get_nli_file() {
    local type="$1"
    case "$type" in
        nlia) echo "AGENTS.md" ;;
        nlic) echo "CLAUDE.md" ;;
        *)
            echo "Warning: Unknown NLI type: $type" >&2
            return 1
            ;;
    esac
}

resolve_version_ref() {
    local version="$1"
    local commit="${2:-}"
    if is_alpha_version "$version"; then
        echo "$commit"
    else
        echo "v$version"
    fi
}

format_version_string() {
    local version="$1"
    local commit="$2"
    local commit_timestamp="$3"

    if [[ -n "$commit_timestamp" ]]; then
        # Extract YYYY-MM-DDTHH:MMZ from timestamp (remove seconds)
        local short_timestamp="${commit_timestamp%:*}Z"
        echo "${version}, ${short_timestamp}"
    else
        echo "$version"
    fi
}

format_version_string_branch() {
    local version="$1"
    local commit="$2"
    local commit_timestamp="$3"

    if [[ -n "$commit_timestamp" ]]; then
        # Extract YYYY-MM-DDTHH-MMZ (replace colons with hyphens for git branch name)
        local short_timestamp="${commit_timestamp%:*}Z"
        short_timestamp="${short_timestamp//:/-}"
        echo "${version}-${short_timestamp}"
    else
        echo "$version"
    fi
}

cleanup_temp() {
    if [[ ${#_TEMP_FILES[@]} -gt 0 ]]; then
        for file in "${_TEMP_FILES[@]}"; do
            rm -f "$file"
        done
    fi
    if [[ ${#_TEMP_DIRS[@]} -gt 0 ]]; then
        for dir in "${_TEMP_DIRS[@]}"; do
            rm -rf "$dir"
        done
    fi
}
trap cleanup_temp EXIT

create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d "$_TMP_BASE/uspecs.XXXXXX")
    _TEMP_DIRS+=("$temp_dir")
    echo "$temp_dir"
}

create_temp_file() {
    local temp_file
    temp_file=$(mktemp "$_TMP_BASE/uspecs.XXXXXX")
    _TEMP_FILES+=("$temp_file")
    echo "$temp_file"
}

show_operation_plan() {
    local operation="$1"
    local current_version="${2:-}"
    local target_version="$3"
    local commit="${4:-}"
    local commit_timestamp="${5:-}"
    local invocation_types="${6:-}"
    local pr_flag="${7:-false}"
    local project_dir="${8:-}"
    local script_dir="${9:-}"

    echo ""
    echo "=========================================="
    echo "Operation: $operation"
    echo "=========================================="

    # From (Source)
    echo "From:"
    if [[ "$operation" != "install" && -n "$current_version" ]]; then
        echo "  Version: $current_version"
        if is_alpha_version "$current_version"; then
            local metadata_file="$project_dir/uspecs/u/uspecs.yml"
            if [[ -f "$metadata_file" ]]; then
                local current_commit current_commit_timestamp
                current_commit=$(grep "^commit:" "$metadata_file" | sed 's/^commit: *//')
                current_commit_timestamp=$(grep "^commit_timestamp:" "$metadata_file" | sed 's/^commit_timestamp: *//')
                if [[ -n "$current_commit" ]]; then
                    echo "  Commit: $current_commit"
                    echo "  Timestamp: $current_commit_timestamp"
                fi
            fi
        fi
    fi
    echo "  Endpoint: $GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$ALPHA_BRANCH"

    echo ""

    # To (Destination)
    echo "To:"
    echo "  Version: $target_version"
    if is_alpha_version "$target_version" && [[ -n "$commit" ]]; then
        echo "  Commit: $commit"
        echo "  Timestamp: $commit_timestamp"
    fi

    echo "  Project folder: $project_dir"
    echo "  uspecs core: uspecs/u"

    if [[ -n "$invocation_types" ]]; then
        echo "  Natural language invocation files:"
        IFS=',' read -ra types_array <<< "$invocation_types"
        for type in "${types_array[@]}"; do
            type=$(echo "$type" | xargs)
            local file
            file=$(get_nli_file "$type") 2>/dev/null || continue
            echo "    - $file"
        done
    fi

    # Pull request (if enabled)
    if [[ "$pr_flag" == "true" && -n "$script_dir" ]]; then
        echo ""
        echo "Pull request:"

        # Get PR info from pr.sh
        local pr_output pr_remote main_branch target_repo_url pr_branch
        if pr_output=$(bash "$script_dir/_lib/pr.sh" info 2>&1); then
            pr_remote=$(echo "$pr_output" | grep '^pr_remote=' | cut -d= -f2)
            main_branch=$(echo "$pr_output" | grep '^main_branch=' | cut -d= -f2)
            target_repo_url=$(git remote get-url "$pr_remote" 2>/dev/null)
            pr_branch="${operation}-uspecs-${target_version}"

            echo "  Target remote: $pr_remote"
            echo "  Target repo: $target_repo_url"
            echo "  Base branch: $main_branch"
            echo "  PR branch: $pr_branch"
        else
            echo "  Failed to determine PR details:"
            echo "$pr_output" | sed 's/^/    /'
        fi
    fi
    echo "=========================================="
}

confirm_action() {
    local action="$1"

    echo ""

    # Try to read from /dev/tty (works even when stdin is piped)
    if [ -e /dev/tty ]; then
        read -p "Proceed with $action? (y/n) " -n 1 -r < /dev/tty
    elif [[ -t 0 ]]; then
        # Stdin is a terminal (not piped)
        read -p "Proceed with $action? (y/n) " -n 1 -r
    else
        # Non-interactive (CI, containers), auto-accept
        return 0
    fi

    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "${action^} cancelled"
        return 1
    fi
}

replace_uspecs_u() {
    local source_dir="$1"
    local project_dir="$2"
    echo "Removing installation metadata file from archive..."
    rm -f "$source_dir/uspecs/u/uspecs.yml"
    echo "Removing old uspecs/u files..."
    find "$project_dir/uspecs/u" -type f -delete
    echo "Installing new uspecs/u..."
    cp -r "$source_dir/uspecs/u" "$project_dir/uspecs/"
}

inject_instructions() {
    local source_file="$1"
    local target_file="$2"

    local begin_marker="<!-- uspecs:triggering_instructions:begin -->"
    local end_marker="<!-- uspecs:triggering_instructions:end -->"

    if [[ ! -f "$source_file" ]]; then
        echo "Warning: Source file not found: $source_file" >&2
        return 1
    fi

    local temp_extract
    temp_extract=$(create_temp_file)
    sed -n "/$begin_marker/,/$end_marker/p" "$source_file" > "$temp_extract"

    if [[ ! -s "$temp_extract" ]]; then
        echo "Warning: No triggering instructions found in $source_file" >&2
        return 1
    fi

    if [[ ! -f "$target_file" ]]; then
        {
            echo "# Agents instructions"
            echo ""
            cat "$temp_extract"
        } > "$target_file"
        return 0
    fi

    if ! grep -q "$begin_marker" "$target_file" || ! grep -q "$end_marker" "$target_file"; then
        {
            echo ""
            cat "$temp_extract"
        } >> "$target_file"
        return 0
    fi

    local temp_output
    temp_output=$(create_temp_file)
    sed "/$begin_marker/,\$d" "$target_file" > "$temp_output"
    cat "$temp_extract" >> "$temp_output"
    sed "1,/$end_marker/d" "$target_file" >> "$temp_output"
    mv "$temp_output" "$target_file"
}

remove_instructions() {
    local target_file="$1"

    if [[ ! -f "$target_file" ]]; then
        return 0
    fi

    local begin_marker="<!-- uspecs:triggering_instructions:begin -->"
    local end_marker="<!-- uspecs:triggering_instructions:end -->"

    if ! grep -q "$begin_marker" "$target_file" || ! grep -q "$end_marker" "$target_file"; then
        return 0
    fi

    local temp_output
    temp_output=$(create_temp_file)
    sed "/$begin_marker/,/$end_marker/d" "$target_file" > "$temp_output"
    mv "$temp_output" "$target_file"
}

write_metadata() {
    local project_dir="$1"
    local version="$2"
    local invocation_types="$3"
    local commit="${4:-}"
    local commit_timestamp="${5:-}"
    local installed_at="${6:-}"

    local metadata_file="$project_dir/uspecs/u/uspecs.yml"
    local timestamp
    timestamp=$(get_timestamp)

    if [[ -z "$installed_at" ]]; then
        installed_at="$timestamp"
    fi

    {
        echo "# uspecs installation metadata"
        echo "# DO NOT EDIT - managed by uspecs"
        echo "version: $version"
        echo "invocation_types: [$invocation_types]"
        echo "installed_at: $installed_at"
        echo "modified_at: $timestamp"
        if [[ -n "$commit" ]]; then
            echo "commit: $commit"
            echo "commit_timestamp: $commit_timestamp"
        fi
    } > "$metadata_file"
}

resolve_update_version() {
    local current_version="$1"

    if is_alpha_version "$current_version"; then
        echo "Checking for alpha updates..."
        local current_commit current_commit_timestamp
        current_commit=$(get_config_value "commit")
        current_commit_timestamp=$(get_config_value "commit_timestamp")
        read -r commit commit_timestamp <<< "$(get_latest_commit_info)"

        if [[ "$current_commit" == "$commit" ]]; then
            echo "Already on the latest alpha version: $current_version"
            echo "  Commit: $commit"
            echo "  Timestamp: $current_commit_timestamp"
            return 1
        fi
        target_version=$(get_alpha_version)
        target_ref="$commit"
    else
        echo "Checking for stable updates..."
        target_version=$(get_latest_minor_tag "$current_version")

        if [[ "$target_version" == "$current_version" ]]; then
            echo "Already on the latest stable minor version: $current_version"

            local latest_major
            latest_major=$(get_latest_major_tag)
            if [[ "$latest_major" != "$current_version" ]]; then
                echo ""
                echo "Upgrade available to version $latest_major"
                echo "Use 'manage.sh upgrade' command"
            fi
            return 1
        fi

        target_ref="v$target_version"
    fi
    return 0
}

resolve_upgrade_version() {
    local current_version="$1"

    if is_alpha_version "$current_version"; then
        error "Only applicable for stable versions. Alpha versions always track the latest commit from $ALPHA_BRANCH branch, use update instead"
    fi

    echo "Checking for major upgrades..."
    target_version=$(get_latest_major_tag)

    if [[ "$target_version" == "$current_version" ]]; then
        echo "Already on the latest major version: $current_version"
        return 1
    fi

    target_ref="v$target_version"
    return 0
}

# Re-invoked by install/update/upgrade commands via target version's manage.sh
cmd_apply() {
    if [[ $# -lt 1 ]]; then
        error "Usage: manage.sh apply <install|update|upgrade> [flags...]"
    fi

    local command_name="$1"
    shift

    local project_dir="" version="" commit="" commit_timestamp="" pr_flag=false
    local current_version=""
    local invocation_types=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-dir) project_dir="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            --commit) commit="$2"; shift 2 ;;
            --commit-timestamp) commit_timestamp="$2"; shift 2 ;;
            --current-version) current_version="$2"; shift 2 ;;
            --pr) pr_flag=true; shift ;;
            --nlia) invocation_types+=("nlia"); shift ;;
            --nlic) invocation_types+=("nlic"); shift ;;
            *) error "Unknown flag: $1" ;;
        esac
    done

    [[ -z "$project_dir" ]] && error "--project-dir is required"
    [[ -z "$version" ]] && error "--version is required"
    [[ ! -d "$project_dir" ]] && error "Project directory not found: $project_dir"

    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local source_dir
    source_dir=$(cd "$script_dir/../../.." && pwd)

    local version_string
    version_string=$(format_version_string "$version" "$commit" "$commit_timestamp")

    local version_string_branch
    version_string_branch=$(format_version_string_branch "$version" "$commit" "$commit_timestamp")

    local metadata_file="$project_dir/uspecs/u/uspecs.yml"

    # Determine invocation types string for plan display
    local plan_invocation_types_str=""
    if [[ "$command_name" == "install" ]]; then
        plan_invocation_types_str=$(IFS=', '; echo "${invocation_types[*]}")
    elif [[ -f "$metadata_file" ]]; then
        plan_invocation_types_str=$(grep "^invocation_types:" "$metadata_file" | sed 's/^invocation_types: *\[//' | sed 's/\]$//')
    fi

    # Show operation plan and confirm
    show_operation_plan "$command_name" "$current_version" "$version" "$commit" "$commit_timestamp" "$plan_invocation_types_str" "$pr_flag" "$project_dir" "$script_dir"
    confirm_action "$command_name" || return 0

    # PR: capture current branch, then create feature branch
    local branch_name="${command_name}-uspecs-${version_string_branch}"
    local prev_branch=""
    if [[ "$pr_flag" == "true" ]]; then
        prev_branch=$(git symbolic-ref --short HEAD)
        bash "$script_dir/_lib/pr.sh" prbranch "$branch_name"
    fi

    # Save existing metadata for update/upgrade
    local invocation_types_str="" installed_at=""

    if [[ "$command_name" != "install" ]]; then
        [[ ! -f "$metadata_file" ]] && error "Installation metadata file not found: $metadata_file"
        invocation_types_str=$(grep "^invocation_types:" "$metadata_file" | sed 's/^invocation_types: *\[//' | sed 's/\]$//')
        installed_at=$(grep "^installed_at:" "$metadata_file" | sed 's/^installed_at: *//')
    else
        invocation_types_str=$(IFS=', '; echo "${invocation_types[*]}")
    fi

    if [[ "$command_name" == "install" ]]; then
        rm -f "$source_dir/uspecs/u/uspecs.yml"
        echo "Installing uspecs/u..."
        mkdir -p "$project_dir/uspecs"
        cp -r "$source_dir/uspecs/u" "$project_dir/uspecs/"
    else
        replace_uspecs_u "$source_dir" "$project_dir"
    fi

    # Write metadata
    echo "Writing installation metadata..."
    write_metadata "$project_dir" "$version" "$invocation_types_str" "$commit" "$commit_timestamp" "$installed_at"

    # Inject NLI instructions
    echo "Injecting instructions..."
    IFS=',' read -ra inject_types <<< "$invocation_types_str"
    for type in "${inject_types[@]}"; do
        type=$(echo "$type" | xargs)
        local file
        file=$(get_nli_file "$type") || continue
        inject_instructions "$source_dir/$file" "$project_dir/$file"
        echo "  - $file"
    done

    # PR: commit, push, and create pull request
    local pr_url="" pr_branch="" pr_base=""
    if [[ "$pr_flag" == "true" ]]; then
        local pr_title="uspecs ${version_string}"
        local pr_body="$pr_title"
        local pr_info_file
        pr_info_file=$(create_temp_file)

        # Capture PR info from stderr while showing normal output
        bash "$script_dir/_lib/pr.sh" pr --title "$pr_title" --body "$pr_body" \
            --next-branch "$prev_branch" --delete-branch 2> "$pr_info_file"

        # Parse PR info from temp file
        pr_url=$(grep '^PR_URL=' "$pr_info_file" | cut -d= -f2-)
        pr_branch=$(grep '^PR_BRANCH=' "$pr_info_file" | cut -d= -f2)
        pr_base=$(grep '^PR_BASE=' "$pr_info_file" | cut -d= -f2)
    fi

    echo ""
    echo "${command_name^} completed successfully!"

    # Display PR summary if created
    if [[ "$pr_flag" == "true" && -n "$pr_url" ]]; then
        echo ""
        echo "=========================================="
        echo "Pull Request Created"
        echo "=========================================="
        echo "URL: $pr_url"
        echo "Branch: $pr_branch -> $pr_base"
        echo "=========================================="
    fi
}

cmd_install() {
    local alpha=false
    local pr_flag=false
    local invocation_types=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --alpha) alpha=true; shift ;;
            --pr) pr_flag=true; shift ;;
            --nlia) invocation_types+=("nlia"); shift ;;
            --nlic) invocation_types+=("nlic"); shift ;;
            *) error "Unknown flag: $1" ;;
        esac
    done

    if [[ ${#invocation_types[@]} -eq 0 ]]; then
        error "At least one invocation type (--nlia or --nlic) is required"
    fi

    local project_dir="$PWD"

    check_not_installed "$project_dir"

    if [[ "$pr_flag" == "true" ]]; then
        check_pr_prerequisites
    fi

    local ref version commit="" commit_timestamp=""
    if [[ "$alpha" == "true" ]]; then
        echo "Fetching latest alpha version..."
        version=$(get_alpha_version)
        read -r commit commit_timestamp <<< "$(get_latest_commit_info)"
        ref="$commit"
        echo "Latest alpha version: $version"
    else
        echo "Fetching latest stable version..."
        version=$(get_latest_tag)
        ref="v$version"
        echo "Latest version: $version"
    fi

    local temp_dir
    temp_dir=$(create_temp_dir)

    echo "Downloading uspecs..."
    download_archive "$ref" "$temp_dir"

    local apply_args=("install" "--project-dir" "$project_dir" "--version" "$version")
    for type in "${invocation_types[@]}"; do
        apply_args+=("--$type")
    done
    if [[ -n "$commit" ]]; then
        apply_args+=("--commit" "$commit" "--commit-timestamp" "$commit_timestamp")
    fi
    if [[ "$pr_flag" == "true" ]]; then
        apply_args+=("--pr")
    fi

    echo "Running install..."
    bash "$temp_dir/uspecs/u/scripts/manage.sh" apply "${apply_args[@]}"
}

cmd_update_or_upgrade() {
    local command_name="$1"
    shift

    local pr_flag=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pr)
                pr_flag=true
                shift
                ;;
            *)
                error "Unknown flag: $1"
                ;;
        esac
    done

    check_installed

    if [[ "$pr_flag" == "true" ]]; then
        check_pr_prerequisites
    fi

    local project_dir
    project_dir=$(get_project_dir)

    local current_version
    current_version=$(get_config_value "version")

    local target_version target_ref commit commit_timestamp
    if [[ "$command_name" == "update" ]]; then
        resolve_update_version "$current_version" || return 0
    else
        resolve_upgrade_version "$current_version" || return 0
    fi

    local temp_dir
    temp_dir=$(create_temp_dir)

    echo "Downloading uspecs..."
    download_archive "$target_ref" "$temp_dir"

    local apply_args=("$command_name" "--project-dir" "$project_dir" "--version" "$target_version")
    apply_args+=("--current-version" "$current_version")
    if [[ -n "${commit:-}" ]]; then
        apply_args+=("--commit" "$commit" "--commit-timestamp" "$commit_timestamp")
    fi
    if [[ "$pr_flag" == "true" ]]; then
        apply_args+=("--pr")
    fi

    echo "Running ${command_name}..."
    bash "$temp_dir/uspecs/u/scripts/manage.sh" apply "${apply_args[@]}"
}

cmd_it() {
    local add_types=()
    local remove_types=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --add) add_types+=("$2"); shift 2 ;;
            --remove) remove_types+=("$2"); shift 2 ;;
            *) error "Unknown flag: $1" ;;
        esac
    done

    if [[ ${#add_types[@]} -eq 0 && ${#remove_types[@]} -eq 0 ]]; then
        error "At least one --add or --remove flag is required"
    fi

    check_installed

    local project_dir
    project_dir=$(get_project_dir)

    local current_types
    current_types=$(get_config_value "invocation_types")

    IFS=',' read -ra types_array <<< "$current_types"
    local -A types_map
    for type in "${types_array[@]}"; do
        type=$(echo "$type" | xargs)
        types_map["$type"]=1
    done

    local version
    version=$(get_config_value "version")

    local ref
    ref=$(resolve_version_ref "$version" "$(get_config_value "commit")")

    local temp_source=""
    if [[ ${#add_types[@]} -gt 0 ]]; then
        temp_source=$(create_temp_file)

        echo "Downloading source file for triggering instructions..."
        local source_url="$GITHUB_RAW/$REPO_OWNER/$REPO_NAME/$ref/AGENTS.md"
        if ! curl -fsSL "$source_url" -o "$temp_source"; then
            error "Failed to download source file from $source_url"
        fi
    fi

    for type in "${add_types[@]}"; do
        if [[ -n "${types_map[$type]:-}" ]]; then
            echo "Invocation type '$type' is already configured"
            continue
        fi

        local file
        file=$(get_nli_file "$type") || continue
        inject_instructions "$temp_source" "$project_dir/$file"
        echo "Added invocation type: $type ($file)"
        types_map["$type"]=1
    done

    for type in "${remove_types[@]}"; do
        if [[ -z "${types_map[$type]:-}" ]]; then
            echo "Invocation type '$type' is not configured"
            continue
        fi
        local file
        file=$(get_nli_file "$type") || continue
        remove_instructions "$project_dir/$file"
        echo "Removed invocation type: $type ($file)"
        unset "types_map[$type]"
    done

    # Build new types string preserving order from original
    local new_types_array=()
    for type in "${types_array[@]}"; do
        type=$(echo "$type" | xargs)
        if [[ -n "${types_map[$type]:-}" ]]; then
            new_types_array+=("$type")
        fi
    done
    # Add any new types that were successfully added (present in types_map)
    for type in "${add_types[@]}"; do
        if [[ -z "${types_map[$type]:-}" ]]; then
            continue
        fi
        local found=0
        for existing in "${new_types_array[@]}"; do
            if [[ "$existing" == "$type" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            new_types_array+=("$type")
        fi
    done

    local new_types_str
    new_types_str=$(IFS=', '; echo "${new_types_array[*]}")

    echo "Updating installation metadata..."
    local metadata_file="$project_dir/uspecs/u/uspecs.yml"
    local timestamp
    timestamp=$(get_timestamp)

    local temp_metadata
    temp_metadata=$(create_temp_file)
    sed "s/^invocation_types: .*/invocation_types: [$new_types_str]/" "$metadata_file" | \
        sed "s/^modified_at: .*/modified_at: $timestamp/" > "$temp_metadata"
    mv "$temp_metadata" "$metadata_file"

    echo ""
    echo "Invocation types updated successfully!"
}

main() {
    if [[ $# -lt 1 ]]; then
        error "Usage: manage.sh <command> [args...]"
    fi

    local command="$1"
    shift

    case "$command" in
        install)
            cmd_install "$@"
            ;;
        update)
            cmd_update_or_upgrade "update" "$@"
            ;;
        upgrade)
            cmd_update_or_upgrade "upgrade" "$@"
            ;;
        apply)
            cmd_apply "$@"
            ;;
        it)
            cmd_it "$@"
            ;;
        *)
            error "Unknown command: $command. Available: install, update, upgrade, apply, it"
            ;;
    esac
}

main "$@"
