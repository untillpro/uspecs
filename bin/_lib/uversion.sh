#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=meta.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/meta.sh"

availability=""
availability_note=""
latest_version=""
update_instructions=""

uversion_fetch_marketplace_manifest() {
    local marketplace_repo="$1"
    local url="https://raw.githubusercontent.com/${marketplace_repo}/main/.claude-plugin/marketplace.json"
    local fetched

    if ! command -v curl >/dev/null 2>&1; then
        printf 'curl is not available to fetch marketplace metadata\n' >&2
        return 1
    fi

    if ! fetched=$(curl -fsSL "$url" 2>&1); then
        printf 'failed to fetch marketplace manifest from %s: %s\n' "$url" "$fetched" >&2
        return 1
    fi

    printf '%s' "$fetched"
}

uversion_manifest_version() {
    local manifest="$1"
    local value

    value=$(
        printf '%s\n' "$manifest" | sed -nE '
s/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"([^"]*)"[[:space:]]*,?[[:space:]]*$/\1/
t found
b
:found
p
q
'
    )
    if [[ -z "$value" ]]; then
        printf 'metadata.version not found in marketplace manifest\n' >&2
        return 1
    fi

    printf '%s\n' "$value"
}

uversion_stable_is_newer() {
    local latest="$1"
    local installed="$2"

    [[ "$latest" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || return 2
    local latest_major="${BASH_REMATCH[1]}"
    local latest_minor="${BASH_REMATCH[2]}"
    local latest_patch="${BASH_REMATCH[3]}"
    [[ "$installed" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || return 2
    local installed_major="${BASH_REMATCH[1]}"
    local installed_minor="${BASH_REMATCH[2]}"
    local installed_patch="${BASH_REMATCH[3]}"

    if (( latest_major > installed_major )); then return 0; fi
    if (( latest_major < installed_major )); then return 1; fi
    if (( latest_minor > installed_minor )); then return 0; fi
    if (( latest_minor < installed_minor )); then return 1; fi
    if (( latest_patch > installed_patch )); then return 0; fi
    return 1
}

uversion_dev_build_id() {
    local version="$1"
    [[ "$version" =~ -dev\+([0-9]{8}-[0-9]{4})\. ]] || return 1
    printf '%s\n' "${BASH_REMATCH[1]}"
}

uversion_dev_is_newer() {
    local latest="$1"
    local installed="$2"
    local latest_id installed_id

    latest_id=$(uversion_dev_build_id "$latest") || return 2
    installed_id=$(uversion_dev_build_id "$installed") || return 2
    [[ "$latest_id" > "$installed_id" ]]
}

uversion_resolve_availability() {
    local installed_version="${USPECS_VERSION:-}"

    availability=""
    availability_note=""
    latest_version=""
    update_instructions=""

    if [[ "$installed_version" == "0.0.0-source" ]]; then
        availability="skipped"
        availability_note="local source build"
        return 0
    fi

    if [[ -z "${USPECS_MARKETPLACE_REPO:-}" \
        || -z "${USPECS_MARKETPLACE_NAME:-}" \
        || -z "${USPECS_STREAM:-}" \
        || -z "${USPECS_CLI:-}" \
        || -z "${USPECS_MARKETPLACE_UPDATE_VERB:-}" ]]; then
        availability="unknown"
        availability_note="generated marketplace metadata is missing from _lib/meta.sh"
        return 0
    fi

    local manifest
    if ! manifest=$(uversion_fetch_marketplace_manifest "$USPECS_MARKETPLACE_REPO" 2>&1); then
        availability="unknown"
        availability_note="$manifest"
        return 0
    fi

    if ! latest_version=$(uversion_manifest_version "$manifest" 2>&1); then
        availability="unknown"
        availability_note="$latest_version"
        latest_version=""
        return 0
    fi

    local is_newer_rc=1
    case "$USPECS_STREAM" in
        stable)
            if uversion_stable_is_newer "$latest_version" "$installed_version"; then
                is_newer_rc=0
            else
                is_newer_rc=$?
            fi
            ;;
        development)
            if uversion_dev_is_newer "$latest_version" "$installed_version"; then
                is_newer_rc=0
            else
                is_newer_rc=$?
            fi
            ;;
        *)
            availability="unknown"
            availability_note="unsupported stream in metadata: $USPECS_STREAM"
            return 0
            ;;
    esac

    if [[ "$is_newer_rc" -eq 2 ]]; then
        availability="unknown"
        availability_note="could not compare installed version $installed_version with latest version $latest_version for $USPECS_STREAM stream"
        return 0
    fi

    if [[ "$is_newer_rc" -eq 0 ]]; then
        availability="newer version $latest_version available"
        update_instructions="$USPECS_CLI plugin marketplace $USPECS_MARKETPLACE_UPDATE_VERB $USPECS_MARKETPLACE_NAME"
    else
        availability="up to date"
    fi
}

uversion_resolve_availability
printf 'availability=%q\n' "$availability"
printf 'availability_note=%q\n' "$availability_note"
printf 'latest_version=%q\n' "$latest_version"
printf 'update_instructions=%q\n' "$update_instructions"
