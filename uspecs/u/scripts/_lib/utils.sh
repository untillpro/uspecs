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
