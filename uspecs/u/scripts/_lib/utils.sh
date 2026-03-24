#!/usr/bin/env bash

# Well, we do not neeed it, since it is sourced, just for consistency with other scripts
set -Eeuo pipefail

# atexit API - safe accumulating EXIT handlers
_ATEXIT_CMDS=()
_ATEXIT_STACK=()

# Capture any EXIT trap registered before utils.sh was sourced so we can chain it.
_ATEXIT_PREV_TRAP=""
{ _tmp=$(trap -p EXIT)
  if [[ -n "$_tmp" ]]; then
      _tmp="${_tmp#trap -- \'}"
      _ATEXIT_PREV_TRAP="${_tmp%\' EXIT}"
  fi
  unset _tmp; }

_atexit_run() {
    local rc=$?
    trap - EXIT  # prevent re-entrancy if a chained handler calls exit
    local cmd
    for cmd in "${_ATEXIT_CMDS[@]+"${_ATEXIT_CMDS[@]}"}"; do
        eval "$cmd" || true
    done
    local i
    for (( i=${#_ATEXIT_STACK[@]}-1; i>=0; i-- )); do
        eval "${_ATEXIT_STACK[$i]}" || true
    done
    if [[ -n "${_ATEXIT_PREV_TRAP:-}" ]]; then
        eval "$_ATEXIT_PREV_TRAP" || true
    fi
    exit "$rc"
}
trap _atexit_run EXIT

# atexit_add <cmd>
# Appends cmd to the FIFO queue of EXIT handlers.
atexit_add() {
    _ATEXIT_CMDS+=("$1")
}

# atexit_push <cmd>
# Pushes cmd onto the LIFO stack; dispatcher runs stack entries after _ATEXIT_CMDS.
atexit_push() {
    _ATEXIT_STACK+=("$1")
}

# atexit_pop
# Removes the last-pushed entry from the stack.
atexit_pop() {
    if [[ ${#_ATEXIT_STACK[@]} -gt 0 ]]; then
        unset '_ATEXIT_STACK[-1]'
    fi
}

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
# Substitutes ${VAR} placeholders using the provided associative array.
# Only variables from vars_map are substituted; shell/environment variables
# are NOT expanded (safe against command injection via backticks or $()).
# Fails if the file is missing, the section is not found, or an unsubstituted
# ${VAR} placeholder remains.
section_templ() {
    local file="$1"
    local section_id="$2"

    [[ -f "$file" ]] || error "file not found: $file"

    local raw
    raw=$(sed -n "/^#\\{1,\\} ${section_id}:/,/^#/{/^#\\{1,\\} ${section_id}:/p;/^#\\{1,\\} ${section_id}:/!{/^#/!p}}" "$file")

    [[ -n "$raw" ]] || error "section not found: $section_id in $file"

    # Substitute ${KEY} patterns using awk (safe: no shell expansion of values)
    local body="$raw"
    if [[ -n "${3:-}" ]]; then
        local -n _st_vars="$3"
        local _st_key
        for _st_key in "${!_st_vars[@]}"; do
            export "_ST_VAL=${_st_vars[$_st_key]}"
            body=$(printf '%s\n' "$body" | awk -v "pat=\${${_st_key}}" \
                '{ val=ENVIRON["_ST_VAL"]
                   idx=index($0,pat)
                   while(idx>0){ $0=substr($0,1,idx-1) val substr($0,idx+length(pat)); idx=index($0,pat) }
                   print }')
        done
        unset _ST_VAL
    fi

    # Check for remaining unsubstituted ${...} placeholders
    if [[ "$body" =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*\} ]]; then
        error "unbound variable in section $section_id of $file: ${BASH_REMATCH[0]}"
    fi

    printf '%s\n' "$body"
}

# md_read_frontmatter_field <file> <field_name>
# Extracts the value of a named field from YAML frontmatter (between --- delimiters).
# Returns the trimmed value. Fails if the file is missing or the field is not found.
md_read_frontmatter_field() {
    local file="$1"
    local field_name="$2"

    [[ -f "$file" ]] || error "file not found: $file"

    local value
    value=$(awk -v field="$field_name" '
        /^---$/ { block++; next }
        block == 1 {
            # Match "field_name: value"
            if ($0 ~ "^" field ":") {
                sub("^" field ":[[:space:]]*", "")
                print
                exit
            }
        }
        block >= 2 { exit }
    ' "$file")

    [[ -n "$value" ]] || error "frontmatter field not found: $field_name in $file"
    printf '%s\n' "$value"
}

# md_read_title <file>
# Extracts the text of the first top-level heading (# ...) from a markdown file.
# Skips YAML frontmatter if present. Fails if the file is missing or has no heading.
md_read_title() {
    local file="$1"

    [[ -f "$file" ]] || error "file not found: $file"

    local title
    title=$(awk '
        /^---$/ && !past_fm { in_fm = !in_fm; next }
        in_fm { next }
        !in_fm { past_fm = 1 }
        /^# / { sub(/^# /, ""); print; exit }
    ' "$file")

    [[ -n "$title" ]] || error "no title heading found in $file"
    printf '%s\n' "$title"
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
