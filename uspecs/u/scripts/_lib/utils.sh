#!/usr/bin/env bash

# checkcmds command1 [command2 ...]
# Verifies that each listed command is available on PATH.
# Prints an error message and exits with status 1 if any command is missing.
checkcmds() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            echo "Error: required command not found: $cmd" >&2
            exit 1
        fi
    done
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
