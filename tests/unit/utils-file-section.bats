#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/uspecs/u/scripts/_lib/utils.sh"

    TEST_TMPDIR="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) TEST_TMPDIR=$(cygpath -m "$TEST_TMPDIR") ;;
    esac

    # Sample markdown file used by most tests
    cat > "$TEST_TMPDIR/sample.md" <<'EOF'
# top-level: Top title

Intro paragraph.

## first_section: First section

First content line.
Second content line.

## second-section: Second section

Some {color} text with {size} values.

## sub_parent: Parent with subsection

Parent content.

### child: Child heading

Child content.

## last-section: Last section

Final content.
EOF
}

# ---------------------------------------------------------------------------
# Basic extraction
# ---------------------------------------------------------------------------

@test "extracts section by id" {
    run file_section "$TEST_TMPDIR/sample.md" "first_section"
    [ "$status" -eq 0 ]
    [[ "$output" == *"First content line."* ]]
    [[ "$output" == *"Second content line."* ]]
}

@test "extracts last section up to EOF" {
    run file_section "$TEST_TMPDIR/sample.md" "last-section"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Final content."* ]]
}

@test "stops at next heading - subsections excluded" {
    run file_section "$TEST_TMPDIR/sample.md" "sub_parent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Parent content."* ]]
    [[ "$output" != *"Child content."* ]]
}

@test "matches section id with hyphens" {
    # shellcheck disable=SC2034  # vars used via nameref
    declare -A vars=([color]="red" [size]="big")
    run file_section "$TEST_TMPDIR/sample.md" "second-section" vars
    [ "$status" -eq 0 ]
    [[ "$output" == *"Some red text with big values."* ]]
}

@test "matches section id with underscores" {
    run file_section "$TEST_TMPDIR/sample.md" "first_section"
    [ "$status" -eq 0 ]
    [[ "$output" == *"First content line."* ]]
}

# ---------------------------------------------------------------------------
# Variable substitution
# ---------------------------------------------------------------------------

@test "substitutes all variables" {
    # shellcheck disable=SC2034  # vars used via nameref
    declare -A vars=([color]="blue" [size]="large")
    run file_section "$TEST_TMPDIR/sample.md" "second-section" vars
    [ "$status" -eq 0 ]
    [[ "$output" == *"Some blue text with large values."* ]]
}

@test "fails when variable is not substituted" {
    # shellcheck disable=SC2034  # vars used via nameref
    declare -A vars=([color]="red")
    run file_section "$TEST_TMPDIR/sample.md" "second-section" vars
    [ "$status" -eq 1 ]
    [[ "$output" == *"unsubstituted variable"* ]]
    [[ "$output" == *"{size}"* ]]
    [[ "$output" == *"sample.md"* ]]
}

@test "fails when no vars provided but placeholders exist" {
    run file_section "$TEST_TMPDIR/sample.md" "second-section"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unsubstituted variable"* ]]
}

@test "succeeds with no vars when section has no placeholders" {
    run file_section "$TEST_TMPDIR/sample.md" "first_section"
    [ "$status" -eq 0 ]
    [[ "$output" == *"First content line."* ]]
}

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

@test "returns error for missing file" {
    run file_section "$TEST_TMPDIR/nonexistent.md" "first_section"
    [ "$status" -eq 1 ]
    [[ "$output" == *"file not found"* ]]
}

@test "returns error for missing section" {
    run file_section "$TEST_TMPDIR/sample.md" "nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"section not found"* ]]
    [[ "$output" == *"sample.md"* ]]
}

@test "handles empty section" {
    cat > "$TEST_TMPDIR/empty-section.md" <<'EOF'
## empty-sec: Empty

## next-sec: Next
EOF
    run file_section "$TEST_TMPDIR/empty-section.md" "empty-sec"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "strips leading and trailing blank lines" {
    run file_section "$TEST_TMPDIR/sample.md" "first_section"
    [ "$status" -eq 0 ]
    local first_line
    first_line=$(echo "$output" | head -1)
    [ "$first_line" = "First content line." ]
}

@test "substitutes values containing backslashes" {
    cat > "$TEST_TMPDIR/backslash.md" <<'EOF'
## bs-sec: Backslash test

path is {path} and esc is {esc}
EOF
    # shellcheck disable=SC2034  # vars used via nameref
    declare -A vars=([path]='C:\Users\me\dir' [esc]='hello\nworld')
    run file_section "$TEST_TMPDIR/backslash.md" "bs-sec" vars
    [ "$status" -eq 0 ]
    [[ "$output" == *'C:\Users\me\dir'* ]]
    [[ "$output" == *'hello\nworld'* ]]
}

@test "handles unsafe values with shell metacharacters" {
    cat > "$TEST_TMPDIR/unsafe.md" <<'EOF'
## unsafe-sec: Unsafe test

cmd is {cmd} and text is {text}
EOF
    # Hostile values with shell metacharacters that would execute if not handled properly
    # shellcheck disable=SC2016  # Intentionally using literal $() and backticks
    local unsafe_cmd='$(rm -rf /) & echo pwned'
    # shellcheck disable=SC2016  # Intentionally using literal backticks
    local unsafe_text='hello `date` world'

    # shellcheck disable=SC2034  # vars used via nameref
    declare -A vars=([cmd]="$unsafe_cmd" [text]="$unsafe_text")

    run file_section "$TEST_TMPDIR/unsafe.md" "unsafe-sec" vars
    [ "$status" -eq 0 ]
    # Verify the hostile strings are treated as literal text, not executed
    # shellcheck disable=SC2016  # Intentionally checking for literal $()
    [[ "$output" == *'$(rm -rf /)'* ]]
    [[ "$output" == *'& echo pwned'* ]]
    # shellcheck disable=SC2016  # Intentionally checking for literal backticks
    [[ "$output" == *'`date`'* ]]
}

