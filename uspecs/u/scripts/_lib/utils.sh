#!/usr/bin/env bash
set -Eeuo pipefail

# git_path
# Ensures Git's usr/bin is in PATH on Windows (Git Bash / MSYS2 / Cygwin).
# Call this at the start of main() in every top-level script.
git_path() {
    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
        PATH="/usr/bin:${PATH}"
    fi
}

# error <message>
# Prints an error message to stderr and exits with status 1.
error() {
    echo "Error: $1" >&2
    exit 1
}

# get_pr_info <pr_sh_path> <map_nameref> [project_dir]
# Calls pr.sh info and parses the key=value output into the given associative array.
# Keys populated: pr_remote, default_branch
# project_dir: directory to run pr.sh from (defaults to $PWD)
# Returns non-zero if pr.sh info fails.
# // TODO circular dependency: pr.sh depends on utils.sh for error(), but utils.sh depends on pr.sh for get_pr_info()
get_pr_info() {
    local pr_sh="$1"
    local -n _pr_info_map="$2"
    local project_dir="${3:-$PWD}"
    local output
    output=$(cd "$project_dir" && bash "$pr_sh" info) || return 1
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        _pr_info_map["$key"]="$value"
    done <<< "$output"
}

# is_tty
# Returns 0 if stdin is connected to a terminal, 1 if piped or redirected.
is_tty() {
    [ -t 0 ]
}

# is_git_repo <dir>
# Returns 0 if <dir> is inside a git repository, 1 otherwise.
is_git_repo() {
    local dir="$1"
    (cd "$dir" && git rev-parse --git-dir > /dev/null 2>&1)
}

# section_templ <file> <section_id> [vars_map]
# Outputs the heading and body of a markdown section whose heading matches
# "## section_id: ...". The output includes the heading line itself.
# section_id may contain alphanumerics, hyphens and underscores.
# The section ends before the next heading (any level) or EOF.
# Subsections are NOT included.
# Uses shell parameter expansion (eval) to substitute ${VAR} placeholders.
# vars_map is the name of an associative array; its keys are set as local
# variables before expansion. Any existing shell/environment variables are
# also available in templates.
# Fails if the file is missing, the section is not found, or an unbound
# variable is referenced (via set -u).
section_templ() {
    local file="$1"
    local section_id="$2"

    [[ -f "$file" ]] || error "file not found: $file"

    local raw
    raw=$(sed -n "/^#\\{1,\\} ${section_id}:/,/^#/{/^#\\{1,\\} ${section_id}:/p;/^#\\{1,\\} ${section_id}:/!{/^#/!p}}" "$file")

    [[ -n "$raw" ]] || error "section not found: $section_id in $file"

    # Set local variables from associative array (nameref)
    if [[ -n "${3:-}" ]]; then
        local -n _st_vars="$3"
        local _st_key
        for _st_key in "${!_st_vars[@]}"; do
            local "$_st_key"="${_st_vars[$_st_key]}"
        done
    fi

    # Use eval to expand ${VAR} placeholders in the body.
    # Variable values are safe: they expand through parameter expansion,
    # whose results are not subject to further command substitution.
    # Unbound variables trigger set -u error; catch and report with context.
    local body
    if ! body=$(eval "printf '%s\n' \"$raw\"" 2>&1); then
        error "unbound variable in section $section_id of $file: $body"
    fi

    printf '%s\n' "$body"
}

# sed_inplace file sed-args...
# Portable in-place sed. Uses -i.bak for BSD compatibility.
# Restores the original file on failure.
sed_inplace() {
    local file="$1"
    shift
    if ! sed -i.bak "$@" "$file"; then
        mv "${file}.bak" "$file" 2>/dev/null || true
        return 1
    fi
    rm -f "${file}.bak"
}
