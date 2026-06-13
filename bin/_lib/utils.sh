#!/usr/bin/env bash

# Well, we do not neeed it, since it is sourced, just for consistency with other scripts
set -Eeuo pipefail

# Source guard - utils.sh must only be sourced once per shell.
if [[ -n "${_UTILS_SH_LOADED:-}" ]]; then
    return 0
fi
_UTILS_SH_LOADED=1

# atexit API - safe accumulating EXIT handlers
_ATEXIT_CMDS=()
_ATEXIT_STACK=()
_ATEXIT_CHAINED=""

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
    # Run chained pre-existing trap last so our cleanup completes even if it calls exit
    if [[ -n "$_ATEXIT_CHAINED" ]]; then
        eval "$_ATEXIT_CHAINED" || true
    fi
    exit "$rc"
}

# Capture any pre-existing EXIT trap and chain it last.
# The source guard above guarantees this runs at most once per shell, preventing
# the self-chaining recursion that would occur on double-sourcing.
{ _prev_trap=$(trap -p EXIT | sed "s/^trap -- '\\(.*\\)' EXIT$/\\1/")
  _ATEXIT_CHAINED="${_prev_trap:-}"
  unset _prev_trap; }
trap _atexit_run EXIT

# atexit_add <cmd>
# Appends cmd to the FIFO queue of EXIT handlers.
# cmd must be a single quoted string, e.g. atexit_add 'rm -f /tmp/foo'
atexit_add() {
    [[ $# -eq 1 ]] || { echo "atexit_add: expected 1 argument, got $#" >&2; return 1; }
    _ATEXIT_CMDS+=("$1")
}

# atexit_push <cmd>
# Pushes cmd onto the LIFO stack; dispatcher runs stack entries after _ATEXIT_CMDS.
# cmd must be a single quoted string, e.g. atexit_push 'rm -f /tmp/foo'
atexit_push() {
    [[ $# -eq 1 ]] || { echo "atexit_push: expected 1 argument, got $#" >&2; return 1; }
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

# quiet <command> [args...]
# Runs the command with both stdout and stderr suppressed.
# On failure, dumps captured stdout to stdout and stderr to stderr,
# then returns the original exit code.
quiet() {
    local _q_out _q_err _q_rc=0
    _q_err=$(mktemp)
    _q_out=$("$@" 2>"$_q_err") || _q_rc=$?
    if [[ $_q_rc -ne 0 ]]; then
        [[ -n "$_q_out" ]] && printf '%s\n' "$_q_out"
        [[ -s "$_q_err" ]] && cat "$_q_err" >&2
    fi
    rm -f "$_q_err"
    return $_q_rc
}

# error <message>
# Prints an error message to stderr and exits with status 1.
error() {
    echo "Error: $1" >&2
    exit 1
}

# shell_quote_args "$@"
# Joins positional parameters into a space-separated string with each argument
# shell-quoted for safe re-execution. Preserves arguments containing whitespace,
# quotes, or metacharacters. Returns empty string for zero arguments.
# Usage: quoted=$(shell_quote_args "$@")
shell_quote_args() {
    if (( $# == 0 )); then
        return 0
    fi
    # shellcheck disable=SC2059
    printf ' %q' "$@"
}

# is_tty
# Returns 0 if stdin is connected to a terminal, 1 if piped or redirected.
is_tty() {
    [ -t 0 ]
}

# is_git_repo <dir>
# Returns 0 if <dir> is inside a git repository, 1 otherwise.
# //TODO replace with git.sh#git_validate_working_tree

is_git_repo() {
    local dir="$1"
    (cd "$dir" && git rev-parse --git-dir > /dev/null 2>&1)
}

# ---------------------------------------------------------------------------
# emit_prompt: file-per-section prompt emission with dependency resolution
# ---------------------------------------------------------------------------

# Global state for emit_prompt
declare -gA _EMIT_SEEN=()    # dedup: id -> 1
declare -ga _EMIT_QUEUE=()   # ordered list of entries: "tag\x1fid\x1fdescr\x1fbody"

# emit_prompt_reset
# Clears dedup and queue state. Not called from emit_prompt's entry: emit_prompt
# only resets _EMIT_SEEN (per-walk dedup) and lets caller-queued artifacts
# survive into the flush. Exported for tests and defensive use.
emit_prompt_reset() {
    _EMIT_SEEN=()
    _EMIT_QUEUE=()
}

# _emit_xml_escape <string>
# Prints the input with XML entity substitutions applied in fixed order:
# `&` -> `&amp;` (first), then `<` -> `&lt;`, then `>` -> `&gt;`. The `&`-first
# ordering avoids double-escaping the entities introduced by the later passes.
# Uses sed where `\&` is the portable literal-ampersand escape, sidestepping
# bash 5.2's patsub_replacement quirk in parameter-expansion substitution.
_emit_xml_escape() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# emit_artifact <id> <payload> [descr]
# Queues an opaque payload for emission. The payload bypasses templating
# (no conditional filtering, no ${VAR} substitution, no @artdef_* dep scan)
# and is XML-entity-escaped at flush time inside <artifact id="..." descr="...">.
# Must be called before emit_prompt; the queue survives emit_prompt's entry.
emit_artifact() {
    local id="$1"
    local payload="$2"
    local descr="${3:-}"
    local sep=$'\x1f'
    # TODO id/descr are interpolated into XML attributes at flush time without
    # escaping or validation. Current callers pass hard-coded ASCII literals so
    # this is safe, but a future caller passing values containing ", <, >, & or
    # newline would break the wrapper tag. Options: validate at queue time
    # (reject id outside [A-Za-z0-9_-]+ and descr containing " < > & or newline),
    # or escape attributes uniformly across artdef/instruction/artifact.
    # TODO emit_artifact stores the payload in _EMIT_QUEUE using \x1f as a field
    # separator, so a truly opaque payload containing that byte would corrupt
    # parsing at flush time. If artifacts are meant to be arbitrary bytes, this
    # delimiter-based framing seems fragile.
    _EMIT_QUEUE+=("artifact${sep}${id}${sep}${descr}${sep}${payload}")
}

# _emit_filter_body <raw_body> <section_id> <file> [vars_map_name]
# Filters conditional lines and checks for unbound ${KEY} placeholders.
# Does NOT substitute. Prints the filtered body to stdout.
_emit_filter_body() {
    local raw_body="$1"
    local section_id="$2"
    local file="$3"
    local vars_name="${4:-}"

    # Single nameref to the caller's vars map, when provided.
    if [[ -n "$vars_name" ]]; then
        local -n _ep_map="$vars_name"
    fi

    # Filter conditional lines: (?var) / (?!var)
    local filtered=""
    local _ep_cline _ep_negate _ep_cvar _ep_cval _ep_skip
    while IFS= read -r _ep_cline || [[ -n "$_ep_cline" ]]; do
        _ep_skip=0
        while [[ "$_ep_cline" =~ \(\?(\!?)([a-zA-Z_][a-zA-Z0-9_]*)\)[[:space:]]*$ ]]; do
            _ep_negate="${BASH_REMATCH[1]}"
            _ep_cvar="${BASH_REMATCH[2]}"
            _ep_cval=""
            if [[ -n "$vars_name" ]]; then
                if [[ -v "_ep_map[$_ep_cvar]" ]]; then
                    _ep_cval="${_ep_map[$_ep_cvar]}"
                else
                    error "unknown condition variable '${_ep_cvar}' in $section_id of $file (not in vars map '$vars_name')"
                fi
            else
                error "conditional (?${_ep_negate}${_ep_cvar}) in $section_id of $file but no vars map provided"
            fi
            if [[ -n "$_ep_negate" ]]; then
                [[ -z "$_ep_cval" ]] || _ep_skip=1
            else
                [[ -n "$_ep_cval" ]] || _ep_skip=1
            fi
            _ep_cline="${_ep_cline%"${BASH_REMATCH[0]}"}"
            _ep_cline="${_ep_cline%"${_ep_cline##*[! ]}"}"
        done
        (( _ep_skip )) && continue
        filtered+="${_ep_cline}"$'\n'
    done <<< "$raw_body"

    # Strip known ${KEY} placeholders so any survivor is, by definition, unbound.
    # Done before substitution -- post-substitution checks would falsely flag
    # dollar-brace literals carried inside substituted values (e.g. `${diff}`
    # containing `${impl_file}` text).
    local _ep_check="$filtered"
    local _ep_key
    if [[ -n "$vars_name" ]]; then
        for _ep_key in "${!_ep_map[@]}"; do
            _ep_check="${_ep_check//"\${${_ep_key}}"/}"
        done
    fi
    if [[ "$_ep_check" =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*\} ]]; then
        error "unbound variable in $section_id of $file: ${BASH_REMATCH[0]}"
    fi

    printf '%s' "$filtered"
}

# _emit_substitute_body <filtered_body> [vars_map_name]
# Substitutes ${KEY} patterns from the vars map. Prints the result to stdout.
_emit_substitute_body() {
    local body="$1"
    local vars_name="${2:-}"

    if [[ -n "$vars_name" ]]; then
        local -n _ep_map="$vars_name"
        local _ep_key
        for _ep_key in "${!_ep_map[@]}"; do
            body="${body//"\${${_ep_key}}"/"${_ep_map[$_ep_key]}"}"
        done
    fi

    printf '%s' "$body"
}

# _emit_read_data_body <file>
# Reads <file> and prints everything after the "## data" line.
# Errors if the marker is missing.
_emit_read_data_body() {
    local file="$1"
    local content body="" _ep_dline found_data=0
    content=$(< "$file")
    while IFS= read -r _ep_dline; do
        if (( found_data )); then
            body+="${_ep_dline}"$'\n'
        elif [[ "$_ep_dline" =~ ^##[[:space:]]+data[[:space:]]*$ ]]; then
            found_data=1
        fi
    done <<< "$content"
    (( found_data )) || error "missing '## data' marker in $file"
    printf '%s' "$body"
}

# _emit_collect <prompts_dir> <section_id> [vars_map_name]
# Recursively collects a prompt file and its @artdef_ dependencies.
# Dependencies are collected first (depth-first), then self is appended.
# Dedup via _EMIT_SEEN prevents double-emission.
_emit_collect() {
    local dir="$1"
    local id="$2"
    local vars_name="${3:-}"

    # Dedup guard
    [[ ! -v "_EMIT_SEEN[$id]" ]] || return 0
    _EMIT_SEEN[$id]=1

    local file="$dir/$id.md"
    [[ -f "$file" ]] || error "prompt file not found: $file"

    # Read file content
    local content
    content=$(< "$file")

    # Extract description from first # heading
    local descr=""
    local _ep_hline
    while IFS= read -r _ep_hline; do
        if [[ "$_ep_hline" =~ ^#[[:space:]]+(.*) ]]; then
            descr="${BASH_REMATCH[1]}"
            break
        fi
    done <<< "$content"

    # Extract body: everything after "## data" line
    local body
    body=$(_emit_read_data_body "$file") || exit 1

    # Inline includes: textual pre-pass, no conditionals/vars applied here.
    # Each `@include_xxx` is replaced with the body of include_xxx.md.
    local -A _inc_seen=()
    while [[ "$body" =~ \`@(include_[a-zA-Z0-9_-]+)\` ]]; do
        local inc_id="${BASH_REMATCH[1]}"
        [[ ! -v "_inc_seen[$inc_id]" ]] || error "include cycle: $inc_id"
        _inc_seen[$inc_id]=1
        local inc_file="$dir/$inc_id.md"
        [[ -f "$inc_file" ]] || error "include file not found: $inc_file"
        local inc_body
        inc_body=$(_emit_read_data_body "$inc_file") || exit 1
        body="${body//"\`@${inc_id}\`"/$inc_body}"
    done

    # Filter conditionals + check unbound vars (no substitution yet).
    local filtered
    filtered=$(_emit_filter_body "$body" "$id" "$file" "$vars_name") || exit 1

    # Scan for @artdef_ dependencies on the pre-substitution body. Scanning
    # post-substitution would pick up `@artdef_*` literals carried inside
    # substituted values (e.g. a `${diff}` value referencing `@artdef_X`).
    local _ep_scan="$filtered"
    while [[ "$_ep_scan" =~ \`@(artdef_[a-zA-Z0-9_-]+)\` ]]; do
        local dep="${BASH_REMATCH[1]}"
        _ep_scan="${_ep_scan#*"${BASH_REMATCH[0]}"}"
        _emit_collect "$dir" "$dep" "$vars_name"
    done

    # Substitute ${KEY} patterns now that deps have been collected.
    local processed
    processed=$(_emit_substitute_body "$filtered" "$vars_name") || exit 1

    # Determine XML tag
    local tag="instruction"
    if [[ "$id" == artdef_* ]]; then
        tag="artdef"
    fi

    # Append self to queue (after dependencies)
    local sep=$'\x1f'
    _EMIT_QUEUE+=("${tag}${sep}${id}${sep}${descr}${sep}${processed}")
}

# emit_prompt <prompts_dir> <section_id> [vars_map_name]
# Entry point: resets per-walk dedup state, collects the section and its
# dependencies, then emits all queued entries (caller-queued artifacts first,
# then collected dependencies, root last). _EMIT_QUEUE is preserved across
# entry so that emit_artifact calls placed before emit_prompt survive into
# the flush, and cleared after flush so the next cycle starts empty.
emit_prompt() {
    _EMIT_SEEN=()
    _emit_collect "$@"

    # Flush queue
    local entry tag id descr body sep=$'\x1f'
    for entry in "${_EMIT_QUEUE[@]+"${_EMIT_QUEUE[@]}"}"; do
        tag="${entry%%"$sep"*}"; entry="${entry#*"$sep"}"
        id="${entry%%"$sep"*}"; entry="${entry#*"$sep"}"
        descr="${entry%%"$sep"*}"; body="${entry#*"$sep"}"

        if [[ "$tag" == "artifact" ]]; then
            printf '<artifact id="%s" descr="%s">\n' "$id" "$descr"
            _emit_xml_escape "$body"
            printf '\n</artifact>\n'
        else
            printf '%s\n' "<${tag} id=\"${id}\" descr=\"${descr}\">"
            printf '%s\n' "$body"
            printf '%s\n' "</${tag}>"
        fi
    done

    _EMIT_QUEUE=()
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

# md_read_frontmatter_field_required <file> <field_name>
# Like md_read_frontmatter_field but treats missing fields as a critical error
# with a clear "required field" message. Use this when the field is mandatory
# and its absence indicates broken input that must be fixed before proceeding.
# Propagates "file not found" errors; only overrides "field not found" errors.
md_read_frontmatter_field_required() {
    local file="$1"
    local field_name="$2"
    local value rc=0

    # Don't capture stderr - let base errors (file not found, field not found) print
    value=$(md_read_frontmatter_field "$file" "$field_name") || rc=$?
    if (( rc != 0 )); then
        # If file doesn't exist, base already printed "file not found" - just exit
        [[ -f "$file" ]] || exit "$rc"
        # File exists but field is missing - augment with "required field" context
        error "frontmatter is missing required '${field_name}:' field in $file"
    fi

    printf '%s\n' "$value"
}

# md_read_frontmatter_field_optional <file> <field_name>
# Like md_read_frontmatter_field but returns empty string when the field is
# absent instead of erroring. Use this for truly optional fields like scope,
# breaking, issue_url. Returns empty when the file or field is missing.
md_read_frontmatter_field_optional() {
    local file="$1"
    local field_name="$2"

    # Return empty silently if file doesn't exist (optional field semantics).
    [[ -f "$file" ]] || return 0

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

    # Return the value (empty if field not found, which is fine for optional).
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

# md_defang_relative_link
# Reads markdown from stdin and writes the transformed markdown to stdout.
# Outside fenced code blocks, relative Markdown file links are rendered inert:
# paths starting with `../` have the leading `(../)+` segments stripped and a
# single `/` prepended, while same-folder file links keep their path. The whole
# `[text](path)` literal is wrapped in backticks so it renders as monospace
# text rather than a clickable link that would be ambiguous or broken outside
# the repository tree (e.g. on a GitHub PR page).
# Targets starting with `http://`, `https://`, `mailto:`, `#`, or `/` are left
# unchanged. Lines inside fenced code blocks (``` or ~~~) are emitted verbatim.
md_defang_relative_link() {
    awk '
        function is_fence(line) {
            return line ~ /^[[:space:]]*(```|~~~)/
        }
        function is_same_folder_file(path) {
            return path !~ /^#/ && (path ~ /^\.\/[^\/]+$/ || path ~ /^[^\/:]+$/)
        }
        BEGIN { in_fence = 0 }
        {
            if (is_fence($0)) { in_fence = !in_fence; print; next }
            if (in_fence)     { print; next }
            line = $0
            out = ""
            while (match(line, /\[[^]]*\]\([^)]+\)/)) {
                link = substr(line, RSTART, RLENGTH)
                bracket = index(link, "](")
                path = substr(link, bracket + 2, length(link) - bracket - 2)
                if (path ~ /^(\.\.\/)+/) {
                    label = substr(link, 1, bracket)
                    sub(/^(\.\.\/)+/, "", path)
                    out = out substr(line, 1, RSTART - 1) "`" label "(/" path ")`"
                } else if (is_same_folder_file(path)) {
                    out = out substr(line, 1, RSTART - 1) "`" link "`"
                } else {
                    out = out substr(line, 1, RSTART + RLENGTH - 1)
                }
                line = substr(line, RSTART + RLENGTH)
            }
            print out line
        }
    '
}

# ---------------------------------------------------------------------------
# Temp file/dir management with automatic cleanup
# ---------------------------------------------------------------------------

case "$OSTYPE" in
    msys*|cygwin*) _TMP_BASE=$(cygpath -w "$TEMP") ;;
    *)             _TMP_BASE="/tmp" ;;
esac

# temp_create_dir <varname>
# Creates a temporary directory, stores its path in the caller's variable
# <varname>, and registers it for cleanup on exit.
temp_create_dir() {
    local -n _out=$1
    _out=$(mktemp -d "$_TMP_BASE/uspecs.XXXXXX")
    atexit_add "rm -rf '$_out'"
}

# temp_create_file <varname>
# Creates a temporary file, stores its path in the caller's variable
# <varname>, and registers it for cleanup on exit.
temp_create_file() {
    local -n _out=$1
    _out=$(mktemp "$_TMP_BASE/uspecs.XXXXXX")
    atexit_add "rm -f '$_out'"
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


# ---------------------------------------------------------------------------
# Structured prompt output (LOG / AGENT_INSTRUCTIONS)
# ---------------------------------------------------------------------------

_PROMPT_LOG_OPEN=0

# _prompt_close_tags_on_exit
# EXIT handler: auto-closes open LOG and AGENT_INSTRUCTIONS tags.
# If LOG is still open (script failed before prompt_start_instructions),
# emits error-handling instructions.
# If AGENT_INSTRUCTIONS is open, emits the closing tag.
_prompt_close_tags_on_exit() {
    if [[ "${_PROMPT_LOG_OPEN:-0}" -eq 1 ]]; then
        echo "</LOG>"
        echo "<AGENT_INSTRUCTIONS>"
        echo "The script exited with an error."
        echo "Describe what happened based on the log above."
        echo "Suggest recovery options as a numbered list, include Cancel as a last item."
        echo "Do not take any further action until user explicitly chooses an option."
        echo "</AGENT_INSTRUCTIONS>"
    elif [[ "${_PROMPT_INSTR_OPEN:-0}" -eq 1 ]]; then
        echo "</AGENT_INSTRUCTIONS>"
    fi
}
atexit_add '_prompt_close_tags_on_exit'

# prompt_start_log
# Emits the opening <LOG> tag.
prompt_start_log() {
    _PROMPT_LOG_OPEN=1
    echo "<LOG>"
}

# prompt_start_instructions <mode>
# Closes the LOG block and opens an AGENT_INSTRUCTIONS block with a meta-instruction.
# mode: "results" - inform user about results
#        "action"  - artifact definitions followed by instructions
# The closing tag is emitted automatically on exit.
prompt_start_instructions() {
    if [[ $# -eq 0 ]]; then
        error "prompt_start_instructions requires a mode: results or action"
    fi
    local mode="$1"
    _PROMPT_LOG_OPEN=0
    _PROMPT_INSTR_OPEN=1
    echo "</LOG>"
    echo "<AGENT_INSTRUCTIONS>"
    case "$mode" in
        results)
            echo "Inform user about the results, see below. Ignore the <LOG> content above."
            ;;
        action)
            echo "See artifact and artifact definitions (artdef) below, followed by instructions."
            ;;
        *)
            error "prompt_start_instructions: unknown mode '$mode' (expected: results or action)"
            ;;
    esac
}
