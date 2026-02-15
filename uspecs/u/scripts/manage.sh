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
#   manage.sh apply <install|update|upgrade> --project-dir <dir> --version <ver> --ref <ref> [flags...]


REPO_OWNER="untillpro"
REPO_NAME="uspecs"
MAIN_BRANCH="${USPECS_MAIN_BRANCH:-main}"
GITHUB_API="https://api.github.com"
GITHUB_RAW="https://raw.githubusercontent.com"

error() {
    echo "Error: $1" >&2
    exit 1
}

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
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

check_git_repository() {
    if ! find_git_root > /dev/null 2>&1; then
        error "No git repository found"
    fi
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
    response=$(curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$MAIN_BRANCH")
    local sha
    sha=$(echo "$response" | grep '"sha":' | head -n 1 | sed 's/.*"sha": *"\([^"]*\)".*/\1/')
    local commit_date
    commit_date=$(echo "$response" | grep '"date":' | head -n 1 | sed 's/.*"date": *"\([^"]*\)".*/\1/')
    echo "$sha $commit_date"
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
    if [[ "$version" == "alpha" ]]; then
        echo "$commit"
    else
        echo "v$version"
    fi
}

format_version_string() {
    local version="$1"
    local commit="${2:-}"
    local commit_timestamp="${3:-}"

    if [[ "$version" == "alpha" ]]; then
        # Format: alpha-YYYYMMDDHHmm-{first-8-chars-of-commit}
        local timestamp_compact
        timestamp_compact=$(echo "$commit_timestamp" | sed 's/[-:TZ]//g' | cut -c1-12)
        local commit_short="${commit:0:8}"
        echo "alpha-${timestamp_compact}-${commit_short}"
    else
        echo "$version"
    fi
}

validate_pr_prerequisites() {
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
    fi

    # Check origin remote
    if ! git remote | grep -q '^origin$'; then
        error "'origin' remote does not exist"
    fi

    # Check working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        error "Working directory has uncommitted changes. Commit or stash changes before using --pr flag"
    fi
}

determine_pr_remote() {
    if git remote | grep -q '^upstream$'; then
        echo "upstream"
    else
        echo "origin"
    fi
}

setup_pr_branch() {
    local pr_remote
    pr_remote=$(determine_pr_remote)

    echo "Switching to $MAIN_BRANCH branch..."
    git checkout "$MAIN_BRANCH"

    echo "Updating $MAIN_BRANCH from $pr_remote..."
    git fetch "$pr_remote"
    git rebase "$pr_remote/$MAIN_BRANCH"

    echo "Pushing updated $MAIN_BRANCH to origin..."
    git push origin "$MAIN_BRANCH"
}

pr_branch_name() {
    local command_name="$1"
    local version_string="$2"
    echo "${command_name}-uspecs-${version_string}"
}

create_pr_branch() {
    local command_name="$1"
    local version_string="$2"

    local branch_name
    branch_name=$(pr_branch_name "$command_name" "$version_string")

    echo "Creating branch: $branch_name"
    git checkout -b "$branch_name"
}

finalize_pr() {
    local command_name="$1"
    local version_string="$2"

    local branch_name
    branch_name=$(pr_branch_name "$command_name" "$version_string")

    # Check if there are any changes to commit
    if [[ -z $(git status --porcelain) ]]; then
        echo "No changes to commit. Cleaning up..."
        git checkout "$MAIN_BRANCH"
        git branch -d "$branch_name"
        echo "No updates were needed."
        return 0
    fi

    local pr_remote
    pr_remote=$(determine_pr_remote)

    # Commit changes
    echo "Committing changes..."
    git add -A
    git commit -m "${command_name^} uspecs to ${version_string}"

    # Push to origin
    echo "Pushing branch to origin..."
    git push -u origin "$branch_name"

    # Create PR using GitHub CLI
    echo "Creating pull request to $pr_remote..."
    local pr_repo
    pr_repo="$(git remote get-url "$pr_remote" | sed -E 's#.*github.com[:/]##; s#\.git$##')"
    local pr_body="${command_name^} uspecs to version ${version_string}"
    local pr_args=('--repo' "$pr_repo" '--base' "$MAIN_BRANCH" '--title' "${command_name^} uspecs to ${version_string}" '--body' "$pr_body")

    if [[ "$pr_remote" == "upstream" ]]; then
        # PR from fork to upstream
        local origin_owner
        origin_owner="$(git remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##; s#/.*##')"
        gh pr create "${pr_args[@]}" --head "${origin_owner}:${branch_name}"
    else
        # PR within same repo (origin)
        gh pr create "${pr_args[@]}" --head "$branch_name"
    fi
    echo "Pull request created successfully!"

    # Clean up local branch (remote branch remains for PR)
    echo "Cleaning up local branch..."
    git checkout "$MAIN_BRANCH"
    git branch -d "$branch_name"
}

_TEMP_DIRS=()

cleanup_temp_dirs() {
    if [[ ${#_TEMP_DIRS[@]} -gt 0 ]]; then
        for dir in "${_TEMP_DIRS[@]}"; do
            rm -rf "$dir"
        done
    fi
}
trap cleanup_temp_dirs EXIT

create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d)
    _TEMP_DIRS+=("$temp_dir")
    echo "$temp_dir"
}

confirm_action() {
    local action="$1"
    echo ""
    read -p "Proceed with $action? (y/n) " -n 1 -r
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

download_target_manage_sh() {
    local target_ref="$1"
    local temp_dir="$2"
    echo "Downloading manage.sh for target version..."
    local manage_url="$GITHUB_RAW/$REPO_OWNER/$REPO_NAME/$target_ref/uspecs/u/scripts/manage.sh"
    curl -fsSL "$manage_url" -o "$temp_dir/manage.sh"
    chmod +x "$temp_dir/manage.sh"
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
    temp_extract=$(mktemp)
    sed -n "/$begin_marker/,/$end_marker/p" "$source_file" > "$temp_extract"

    if [[ ! -s "$temp_extract" ]]; then
        echo "Warning: No triggering instructions found in $source_file" >&2
        rm -f "$temp_extract"
        return 1
    fi

    if [[ ! -f "$target_file" ]]; then
        {
            echo "# Agents instructions"
            echo ""
            cat "$temp_extract"
        } > "$target_file"
        rm -f "$temp_extract"
        return 0
    fi

    if ! grep -q "$begin_marker" "$target_file" || ! grep -q "$end_marker" "$target_file"; then
        {
            echo ""
            cat "$temp_extract"
        } >> "$target_file"
        rm -f "$temp_extract"
        return 0
    fi

    local temp_output
    temp_output=$(mktemp)
    sed "/$begin_marker/,\$d" "$target_file" > "$temp_output"
    cat "$temp_extract" >> "$temp_output"
    sed "1,/$end_marker/d" "$target_file" >> "$temp_output"
    mv "$temp_output" "$target_file"
    rm -f "$temp_extract"
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
    temp_output=$(mktemp)
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
            echo "# Commit info for alpha versions"
            echo "commit: $commit"
            echo "commit_timestamp: $commit_timestamp"
        fi
    } > "$metadata_file"
}

# Re-invoked by install/update/upgrade commands via target version's manage.sh
cmd_apply() {
    if [[ $# -lt 1 ]]; then
        error "Usage: manage.sh apply <install|update|upgrade> [flags...]"
    fi

    local command_name="$1"
    shift

    local project_dir="" version="" ref="" commit="" commit_timestamp="" pr_flag=false
    local invocation_types=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-dir) project_dir="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            --ref) ref="$2"; shift 2 ;;
            --commit) commit="$2"; shift 2 ;;
            --commit-timestamp) commit_timestamp="$2"; shift 2 ;;
            --pr) pr_flag=true; shift ;;
            --nlia) invocation_types+=("nlia"); shift ;;
            --nlic) invocation_types+=("nlic"); shift ;;
            *) error "Unknown flag: $1" ;;
        esac
    done

    [[ -z "$project_dir" ]] && error "--project-dir is required"
    [[ -z "$version" ]] && error "--version is required"
    [[ -z "$ref" ]] && error "--ref is required"
    [[ ! -d "$project_dir" ]] && error "Project directory not found: $project_dir"

    local version_string
    version_string=$(format_version_string "$version" "$commit" "$commit_timestamp")

    # PR: create branch before making changes
    if [[ "$pr_flag" == "true" ]]; then
        create_pr_branch "$command_name" "$version_string"
    fi

    # Save existing metadata for update/upgrade
    local invocation_types_str="" installed_at=""
    local metadata_file="$project_dir/uspecs/u/uspecs.yml"

    if [[ "$command_name" != "install" ]]; then
        [[ ! -f "$metadata_file" ]] && error "Installation metadata file not found: $metadata_file"
        invocation_types_str=$(grep "^invocation_types:" "$metadata_file" | sed 's/^invocation_types: *\[//' | sed 's/\]$//')
        installed_at=$(grep "^installed_at:" "$metadata_file" | sed 's/^installed_at: *//')
    else
        invocation_types_str=$(IFS=', '; echo "${invocation_types[*]}")
    fi

    # Download and install files
    local temp_dir
    temp_dir=$(create_temp_dir)

    echo "Downloading uspecs..."
    download_archive "$ref" "$temp_dir"

    if [[ "$command_name" == "install" ]]; then
        rm -f "$temp_dir/uspecs/u/uspecs.yml"
        echo "Installing uspecs/u..."
        mkdir -p "$project_dir/uspecs"
        cp -r "$temp_dir/uspecs/u" "$project_dir/uspecs/"
    else
        replace_uspecs_u "$temp_dir" "$project_dir"
    fi

    # Write metadata
    echo "Writing installation metadata..."
    write_metadata "$project_dir" "$version" "$invocation_types_str" "$commit" "$commit_timestamp" "$installed_at"

    # Inject NLI instructions (install only)
    if [[ "$command_name" == "install" ]]; then
        echo "Injecting instructions..."
        for type in "${invocation_types[@]}"; do
            local file
            file=$(get_nli_file "$type") || continue
            inject_instructions "$temp_dir/$file" "$project_dir/$file"
            echo "  - $file"
        done
    fi

    # PR: finalize
    if [[ "$pr_flag" == "true" ]]; then
        finalize_pr "$command_name" "$version_string"
    fi

    echo ""
    echo "${command_name^} completed successfully!"
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

    check_git_repository
    check_not_installed "$project_dir"

    if [[ "$pr_flag" == "true" ]]; then
        validate_pr_prerequisites
        setup_pr_branch
    fi

    local ref version commit="" commit_timestamp=""
    if [[ "$alpha" == "true" ]]; then
        echo "Installing alpha version..."
        read -r commit commit_timestamp <<< "$(get_latest_commit_info)"
        ref="$commit"
        version="alpha"
        echo "Endpoint: $GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$MAIN_BRANCH"
        echo "Latest commit: $commit"
        echo "Commit timestamp: $commit_timestamp"
    else
        echo "Installing stable version..."
        version=$(get_latest_tag)
        ref="v$version"
        echo "Latest version: $version"
    fi

    local temp_dir
    temp_dir=$(create_temp_dir)

    download_target_manage_sh "$ref" "$temp_dir"

    local apply_args=("install" "--project-dir" "$project_dir" "--version" "$version" "--ref" "$ref")
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
    bash "$temp_dir/manage.sh" apply "${apply_args[@]}"
}

resolve_update_version() {
    local current_version="$1"

    if [[ "$current_version" == "alpha" ]]; then
        echo "Checking for alpha updates..."
        local current_commit current_commit_timestamp
        current_commit=$(get_config_value "commit")
        current_commit_timestamp=$(get_config_value "commit_timestamp")
        read -r commit commit_timestamp <<< "$(get_latest_commit_info)"

        if [[ "$current_commit" == "$commit" ]]; then
            echo "Already on the latest alpha version"
            echo "  Commit: $commit"
            echo "  Timestamp: $current_commit_timestamp"
            return 1
        fi
        target_version="alpha"
        target_ref="$commit"
        echo "New alpha version available:"
        echo "  Endpoint: $GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$MAIN_BRANCH"
        echo "  Current commit: $current_commit"
        echo "  Current timestamp: $current_commit_timestamp"
        echo "  Latest commit: $commit"
        echo "  Latest timestamp: $commit_timestamp"
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
        echo "New version available:"
        echo "  Endpoint: $GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$MAIN_BRANCH"
        echo "  Current: $current_version"
        echo "  Latest: $target_version"
    fi
    return 0
}

resolve_upgrade_version() {
    local current_version="$1"

    if [[ "$current_version" == "alpha" ]]; then
        error "Only applicable for stable versions. Alpha versions always track the latest commit from $MAIN_BRANCH branch, use update instead"
    fi

    echo "Checking for major upgrades..."
    target_version=$(get_latest_major_tag)

    if [[ "$target_version" == "$current_version" ]]; then
        echo "Already on the latest major version: $current_version"
        return 1
    fi

    target_ref="v$target_version"
    echo "New major version available:"
    echo "  Endpoint: $GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$MAIN_BRANCH"
    echo "  Current: $current_version"
    echo "  Latest: $target_version"
    return 0
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

    # If --pr flag is provided, validate prerequisites and setup PR workflow
    if [[ "$pr_flag" == "true" ]]; then
        validate_pr_prerequisites
        setup_pr_branch
    fi

    check_installed

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

    confirm_action "$command_name" || return 0

    local temp_dir
    temp_dir=$(create_temp_dir)

    download_target_manage_sh "$target_ref" "$temp_dir"

    local apply_args=("$command_name" "--project-dir" "$project_dir" "--version" "$target_version" "--ref" "$target_ref")
    if [[ -n "${commit:-}" ]]; then
        apply_args+=("--commit" "$commit" "--commit-timestamp" "$commit_timestamp")
    fi
    if [[ "$pr_flag" == "true" ]]; then
        apply_args+=("--pr")
    fi

    echo "Running ${command_name}..."
    bash "$temp_dir/manage.sh" apply "${apply_args[@]}"
}

cmd_update() {
    cmd_update_or_upgrade "update" "$@"
}

cmd_upgrade() {
    cmd_update_or_upgrade "upgrade" "$@"
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
        temp_source=$(mktemp)

        echo "Downloading source file for triggering instructions..."
        local source_url="$GITHUB_RAW/$REPO_OWNER/$REPO_NAME/$ref/AGENTS.md"
        if ! curl -fsSL "$source_url" -o "$temp_source"; then
            rm -f "$temp_source"
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

    if [[ -n "$temp_source" ]]; then
        rm -f "$temp_source"
    fi

    for type in "${remove_types[@]}"; do
        if [[ -z "${types_map[$type]:-}" ]]; then
            echo "Invocation type '$type' is not configured"
            continue
        fi
        local file
        file=$(get_nli_file "$type") || continue
        remove_instructions "$project_dir/$file"
        echo "Removed invocation type: $type ($file)"
        unset types_map["$type"]
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
    temp_metadata=$(mktemp)
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
            cmd_update "$@"
            ;;
        upgrade)
            cmd_upgrade "$@"
            ;;
        apply)
            cmd_apply "$@"
            ;;
        it)
            cmd_it "$@"
            ;;
        *)
            error "Unknown command: $command. Available: install, update, upgrade, it"
            ;;
    esac
}

main "$@"
