#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"

    TEST_TMPDIR="$BATS_TEST_TMPDIR"
    case "$OSTYPE" in
        msys*|cygwin*) TEST_TMPDIR=$(cygpath -m "$TEST_TMPDIR") ;;
    esac

    PROMPTS_DIR="$TEST_TMPDIR/prompts"
    mkdir -p "$PROMPTS_DIR"
}

# ---------------------------------------------------------------------------
# Basic emission
# ---------------------------------------------------------------------------

@test "emit_prompt: tags, descr, ## data marker, content before data excluded" {
    cat > "$PROMPTS_DIR/instr_hello.md" <<'EOF'
# Say hello

Notes before data - should not appear.

## data

Hello world.
EOF
    cat > "$PROMPTS_DIR/artdef_thing.md" <<'EOF'
# My artifact

## data

Artifact body.
EOF

    # instruction tag with descr, body emitted, pre-data content excluded
    run emit_prompt "$PROMPTS_DIR" "instr_hello"
    [ "$status" -eq 0 ]
    local first_line last_line
    first_line=$(printf '%s\n' "$output" | head -1)
    last_line=$(printf '%s\n' "$output" | tail -1)
    [ "$first_line" = '<instruction id="instr_hello" descr="Say hello">' ]
    [ "$last_line" = '</instruction>' ]
    [[ "$output" == *"Hello world."* ]]
    [[ "$output" != *"Notes before data"* ]]

    # artdef_ prefix uses artdef tag
    run emit_prompt "$PROMPTS_DIR" "artdef_thing"
    [ "$status" -eq 0 ]
    first_line=$(printf '%s\n' "$output" | head -1)
    last_line=$(printf '%s\n' "$output" | tail -1)
    [ "$first_line" = '<artdef id="artdef_thing" descr="My artifact">' ]
    [ "$last_line" = '</artdef>' ]
}

# ---------------------------------------------------------------------------
# Dependency resolution
# ---------------------------------------------------------------------------

@test "emit_prompt: deps first, conditional deps excluded when falsy" {
    cat > "$PROMPTS_DIR/artdef_dep.md" <<'EOF'
# Dependency

## data

Dep content.
EOF
    cat > "$PROMPTS_DIR/artdef_optional.md" <<'EOF'
# Optional dep

## data

Optional content.
EOF
    cat > "$PROMPTS_DIR/instr_root.md" <<'EOF'
# Root instruction

## data

Use `@artdef_dep` here.
Use `@artdef_optional` only when enabled. (?enabled)
EOF

    # enabled=="" -> conditional line excluded, artdef_optional not resolved
    # shellcheck disable=SC2034
    declare -A vars=([enabled]="")
    run emit_prompt "$PROMPTS_DIR" "instr_root" vars
    [ "$status" -eq 0 ]

    # artdef_dep emitted before instruction
    local dep_pos instr_pos
    dep_pos=$(printf '%s\n' "$output" | grep -n 'artdef_dep' | head -1 | cut -d: -f1)
    instr_pos=$(printf '%s\n' "$output" | grep -n 'instr_root' | head -1 | cut -d: -f1)
    [ "$dep_pos" -lt "$instr_pos" ]
    [[ "$output" == *"Dep content."* ]]

    # artdef_optional not emitted (conditional line was excluded)
    [[ "$output" != *"artdef_optional"* ]]
    [[ "$output" != *"Optional content."* ]]

    # enabled="1" -> conditional line included, artdef_optional resolved
    vars=([enabled]="1")
    run emit_prompt "$PROMPTS_DIR" "instr_root" vars
    [ "$status" -eq 0 ]
    [[ "$output" == *"Optional content."* ]]
}

@test "emit_prompt: dedup - shared dependency emitted once" {
    cat > "$PROMPTS_DIR/artdef_shared.md" <<'EOF'
# Shared

## data

Shared content.
EOF
    cat > "$PROMPTS_DIR/artdef_a.md" <<'EOF'
# A

## data

A refs `@artdef_shared`.
EOF
    cat > "$PROMPTS_DIR/artdef_b.md" <<'EOF'
# B

## data

B refs `@artdef_shared`.
EOF
    cat > "$PROMPTS_DIR/instr_dedup.md" <<'EOF'
# Dedup test

## data

Use `@artdef_a` and `@artdef_b`.
EOF
    run emit_prompt "$PROMPTS_DIR" "instr_dedup"
    [ "$status" -eq 0 ]

    # artdef_shared appears exactly once as an XML tag
    local count
    count=$(printf '%s\n' "$output" | grep -c '<artdef id="artdef_shared"')
    [ "$count" -eq 1 ]
}


# ---------------------------------------------------------------------------
# Variable substitution
# ---------------------------------------------------------------------------

@test "emit_prompt: variable substitution and unbound error" {
    cat > "$PROMPTS_DIR/instr_vars.md" <<'EOF'
# Vars test

## data

Deploy ${app} to ${env}.
EOF
    # shellcheck disable=SC2034
    declare -A vars=([app]="myapp" [env]="prod")
    run emit_prompt "$PROMPTS_DIR" "instr_vars" vars
    [ "$status" -eq 0 ]
    [[ "$output" == *"Deploy myapp to prod."* ]]

    # unbound variable fails
    cat > "$PROMPTS_DIR/instr_unbound.md" <<'EOF'
# Unbound

## data

Value is ${missing}.
EOF
    run emit_prompt "$PROMPTS_DIR" "instr_unbound"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unbound variable"* ]]
}

# ---------------------------------------------------------------------------
# Conditional lines
# ---------------------------------------------------------------------------

@test "emit_prompt: conditional lines (?var) / (?!var)" {
    cat > "$PROMPTS_DIR/instr_cond.md" <<'EOF'
# Conditional

## data

always here
included (?flag)
excluded (?!flag)
EOF
    # shellcheck disable=SC2034
    declare -A vars=([flag]="1")
    run emit_prompt "$PROMPTS_DIR" "instr_cond" vars
    [ "$status" -eq 0 ]

    [[ "$output" == *"always here"* ]]
    [[ "$output" == *"included"* ]]
    [[ "$output" != *"excluded"* ]]
    [[ "$output" != *"(?flag)"* ]]
}

# ---------------------------------------------------------------------------
# Error cases
# ---------------------------------------------------------------------------

@test "emit_prompt: error cases - missing file, missing ## data, missing dep" {
    # missing file
    run emit_prompt "$PROMPTS_DIR" "instr_nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"prompt file not found"* ]]

    # missing ## data marker
    cat > "$PROMPTS_DIR/instr_nodata.md" <<'EOF'
# No data marker

Just content without ## data.
EOF
    run emit_prompt "$PROMPTS_DIR" "instr_nodata"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing '## data' marker"* ]]

    # missing dependency file
    cat > "$PROMPTS_DIR/instr_baddep.md" <<'EOF'
# Bad dep

## data

Use `@artdef_nonexistent`.
EOF
    run emit_prompt "$PROMPTS_DIR" "instr_baddep"
    [ "$status" -eq 1 ]
    [[ "$output" == *"prompt file not found"* ]]
}

# ---------------------------------------------------------------------------
# Reference integrity (real prompts dir)
# ---------------------------------------------------------------------------

@test "prompt refs: all refs valid, no orphans" {
    local root="$REPO_ROOT"
    case "$OSTYPE" in
        msys*|cygwin*) root=$(cygpath -m "$root") ;;
    esac
    # Allowed orphans: prompts for cmd_action_uimpl (not yet wired into softeng.sh)
    run python3 "$root/tests/unit/check_prompt_refs.py" "$root" \
        --allow-orphan instr_uimpl \
        --allow-orphan instr_uimpl_todos \
        --allow-orphan instr_shared_select_change_folder
    echo "$output"
    [ "$status" -eq 0 ]
}

@test "prompt refs: unit tests for check_prompt_refs.py" {
    local root="$REPO_ROOT"
    case "$OSTYPE" in
        msys*|cygwin*) root=$(cygpath -m "$root") ;;
    esac
    run python3 "$root/tests/unit/test_check_prompt_refs.py"
    echo "$output"
    [ "$status" -eq 0 ]
}