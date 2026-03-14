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

# file_section <file> <section_id> [vars_map]
# Outputs the body of a markdown section whose heading matches "## section_id: ...".
# section_id may contain alphanumerics, hyphens and underscores.
# The section starts after the heading line and ends before the next heading
# (any level) or EOF. Subsections are NOT included.
# vars_map is the name of an associative array; every {KEY} in the body is
# replaced with the corresponding value. Omit when no placeholders exist.
# Fails if the file is missing, the section is not found, or unsubstituted
# {VAR} placeholders remain in the output.
file_section() {
    local file="$1"
    local section_id="$2"

    [[ -f "$file" ]] || error "file not found: $file"

    # Extract heading + body up to next heading, then strip the heading line.
    # Keeping the heading in the initial output lets us distinguish
    # "section found but empty" (heading present) from "not found" (no output).
    local raw
    raw=$(sed -n "/^#\\{1,\\} ${section_id}:/,/^#/{/^#\\{1,\\} ${section_id}:/p;/^#\\{1,\\} ${section_id}:/!{/^#/!p}}" "$file")

    [[ -n "$raw" ]] || error "section not found: $section_id in $file"

    # Drop the heading line
    local body
    body=$(echo "$raw" | sed '1d')

    # Strip leading and trailing blank lines
    body=$(echo "$body" | sed '/./,$!d' | sed -e :a -e '/^[[:space:]]*$/{ $d; N; ba; }')

    # Apply substitutions from associative array (nameref)
    if [[ -n "${3:-}" ]]; then
        local -n _fs_vars="$3"
        local key value
        for key in "${!_fs_vars[@]}"; do
            value="${_fs_vars[$key]}"
            # Escape special chars: bash 4.4+ treats \ as escape, & as matched pattern
            value="${value//\\/\\\\}"  # Escape backslashes
            value="${value//&/\\&}"     # Escape ampersands
            body="${body//\{$key\}/$value}"
        done
    fi

    # Fail if unsubstituted placeholders remain
    local leftover
    leftover=$(echo "$body" | grep -oE '\{[A-Za-z_][A-Za-z0-9_-]*\}' | head -1) || true
    [[ -z "$leftover" ]] || error "unsubstituted variable $leftover in $file"

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
