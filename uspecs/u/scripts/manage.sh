#!/usr/bin/env bash
set -Eeuo pipefail

# manage.sh
#
# Description:
#   Manages uspecs lifecycle: install, update, upgrade, and invocation type configuration
#
# Usage:
#   manage.sh install --nlia
#   manage.sh update
#   manage.sh upgrade
#   manage.sh it --add nlia
#   manage.sh it --remove nlic

REPO_OWNER="untillpro"
REPO_NAME="uspecs"
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

get_latest_commit() {
    curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/main" | \
        grep '"sha":' | \
        head -n 1 | \
        sed 's/.*"sha": *"\([^"]*\)".*/\1/'
}

get_commit_timestamp() {
    local commit="$1"
    curl -fsSL "$GITHUB_API/repos/$REPO_OWNER/$REPO_NAME/commits/$commit" | \
        grep '"date":' | \
        head -n 1 | \
        sed 's/.*"date": *"\([^"]*\)".*/\1/'
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

_TEMP_DIRS=()

cleanup_temp_dirs() {
    for dir in "${_TEMP_DIRS[@]}"; do
        rm -rf "$dir"
    done
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
    find "$project_dir/uspecs/u" -depth -type d -empty -delete
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
    local is_new="${6:-false}"

    local metadata_file="$project_dir/uspecs/u/uspecs.yml"
    local timestamp
    timestamp=$(get_timestamp)

    {
        echo "# uspecs installation metadata"
        echo "# DO NOT EDIT - managed by uspecs"
        echo "version: $version"
        echo "invocation_types: [$invocation_types]"
        if [[ "$is_new" == "true" ]]; then
            echo "installed_at: $timestamp"
        else
            local installed_at
            installed_at=$(get_config_value "installed_at")
            echo "installed_at: $installed_at"
        fi
        echo "modified_at: $timestamp"
        if [[ -n "$commit" ]]; then
            echo "# Commit info for alpha versions"
            echo "commit: $commit"
            echo "commit_timestamp: $commit_timestamp"
        fi
    } > "$metadata_file"
}

cmd_install() {
    local alpha=false
    local invocation_types=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --alpha) alpha=true; shift ;;
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

    local ref version commit="" commit_timestamp=""
    if [[ "$alpha" == "true" ]]; then
        echo "Installing alpha version..."
        commit=$(get_latest_commit)
        commit_timestamp=$(get_commit_timestamp "$commit")
        ref="$commit"
        version="alpha"
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

    echo "Downloading uspecs..."
    download_archive "$ref" "$temp_dir"

    # Removing installation metadata file from archive...
    rm -f "$temp_dir/uspecs/u/uspecs.yml"

    echo "Installing $project_dir/uspecs/u..."
    mkdir -p "$project_dir/uspecs"
    cp -r "$temp_dir/uspecs/u" "$project_dir/uspecs/"

    local invocation_types_str
    invocation_types_str=$(IFS=', '; echo "${invocation_types[*]}")

    echo "Writing installation metadata..."
    write_metadata "$project_dir" "$version" "$invocation_types_str" "$commit" "$commit_timestamp" "true"

    echo "Injecting instructions..."
    for type in "${invocation_types[@]}"; do
        local file
        file=$(get_nli_file "$type") || continue
        inject_instructions "$temp_dir/$file" "$project_dir/$file"
        echo "  - $file"
    done

    echo ""
    echo "uspecs installed successfully!"
}

cmd_update() {
    local project_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-dir)
                project_dir="$2"
                shift 2
                ;;
            *)
                error "Unknown flag: $1"
                ;;
        esac
    done

    if [[ -n "$project_dir" ]]; then
        perform_update "$project_dir"
        return 0
    fi

    check_installed

    project_dir=$(get_project_dir)

    local current_version
    current_version=$(get_config_value "version")

    local target_version target_ref commit commit_timestamp
    if [[ "$current_version" == "alpha" ]]; then
        echo "Checking for alpha updates..."
        local current_commit current_commit_timestamp
        current_commit=$(get_config_value "commit")
        current_commit_timestamp=$(get_config_value "commit_timestamp")
        commit=$(get_latest_commit)

        if [[ "$current_commit" == "$commit" ]]; then
            echo "Already on the latest alpha version"
            echo "  Commit: $commit"
            echo "  Timestamp: $current_commit_timestamp"
            return 0
        fi

        commit_timestamp=$(get_commit_timestamp "$commit")
        target_version="alpha"
        target_ref="$commit"
        echo "New alpha version available:"
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
            return 0
        fi

        target_ref="v$target_version"
        echo "New version available:"
        echo "  Current: $current_version"
        echo "  Latest: $target_version"
    fi

    confirm_action "update" || return 0

    local temp_dir
    temp_dir=$(create_temp_dir)

    download_target_manage_sh "$target_ref" "$temp_dir"

    echo "Running update..."
    bash "$temp_dir/manage.sh" update --project-dir "$project_dir"
}

perform_update() {
    local project_dir="$1"

    if [[ ! -d "$project_dir" ]]; then
        error "Project directory not found: $project_dir"
    fi

    local metadata_file="$project_dir/uspecs/u/uspecs.yml"
    if [[ ! -f "$metadata_file" ]]; then
        error "Installation metadata file not found: $metadata_file"
    fi

    echo "Saving metadata..."
    local temp_metadata
    temp_metadata=$(mktemp)
    cp "$metadata_file" "$temp_metadata"

    local version
    version=$(grep "^version:" "$temp_metadata" | sed 's/^version: *//')

    local commit="" commit_timestamp=""
    if [[ "$version" == "alpha" ]]; then
        commit=$(get_latest_commit)
        commit_timestamp=$(get_commit_timestamp "$commit")
    fi

    local ref
    ref=$(resolve_version_ref "$version" "$commit")

    local temp_dir
    temp_dir=$(create_temp_dir)

    echo "Downloading uspecs..."
    download_archive "$ref" "$temp_dir"

    replace_uspecs_u "$temp_dir" "$project_dir"

    echo "Restoring and updating metadata..."
    cp "$temp_metadata" "$metadata_file"
    rm -f "$temp_metadata"

    local timestamp
    timestamp=$(get_timestamp)

    local temp_sed
    temp_sed=$(mktemp)
    sed "s/^modified_at: .*/modified_at: $timestamp/" "$metadata_file" > "$temp_sed"

    if [[ "$version" == "alpha" ]]; then
        sed "s/^commit: .*/commit: $commit/" "$temp_sed" | \
            sed "s/^commit_timestamp: .*/commit_timestamp: $commit_timestamp/" > "$metadata_file"
    else
        mv "$temp_sed" "$metadata_file"
    fi
    rm -f "$temp_sed"

    echo ""
    echo "Update completed successfully!"
}

cmd_upgrade() {
    check_installed

    local project_dir
    project_dir=$(get_project_dir)

    local current_version
    current_version=$(get_config_value "version")

    if [[ "$current_version" == "alpha" ]]; then
        error "Only applicable for stable versions. Alpha versions always track the latest commit from main branch, use update instead"
    fi

    echo "Checking for major upgrades..."
    local target_version
    target_version=$(get_latest_major_tag)

    if [[ "$target_version" == "$current_version" ]]; then
        echo "Already on the latest major version: $current_version"
        return 0
    fi

    local target_ref="v$target_version"
    echo "New major version available:"
    echo "  Current: $current_version"
    echo "  Latest: $target_version"

    confirm_action "upgrade" || return 0

    local invocation_types
    invocation_types=$(get_config_value "invocation_types")

    local temp_dir
    temp_dir=$(create_temp_dir)

    echo "Downloading uspecs..."
    download_archive "$target_ref" "$temp_dir"

    replace_uspecs_u "$temp_dir" "$project_dir"

    echo "Updating installation metadata..."
    write_metadata "$project_dir" "$target_version" "$invocation_types" "" "" "false"

    echo ""
    echo "Upgrade completed successfully!"
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
    # Add any new types that were added
    for type in "${add_types[@]}"; do
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
        it)
            cmd_it "$@"
            ;;
        *)
            error "Unknown command: $command. Available: install, update, upgrade, it"
            ;;
    esac
}

main "$@"

