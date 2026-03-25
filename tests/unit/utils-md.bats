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

    # Sample markdown file with YAML frontmatter
    cat > "$TEST_TMPDIR/change.md" <<'EOF'
---
registered_at: 2026-03-12T07:00:31Z
change_id: 2603120700-introduce-umergepr
baseline: c9614d33d1f10184c96e64781e1fe3b439938e6f
issue_url: https://github.com/org/repo/issues/42
---

# Change request: Introduce umergepr action

## Why

Some explanation.
EOF

    # Markdown file without frontmatter
    cat > "$TEST_TMPDIR/no-frontmatter.md" <<'EOF'
# Simple title

Body text.
EOF

    # Markdown file without heading
    cat > "$TEST_TMPDIR/no-heading.md" <<'EOF'
---
field: value
---

Just body text, no heading.
EOF
}

# ---------------------------------------------------------------------------
# md_read_frontmatter_field
# ---------------------------------------------------------------------------

@test "frontmatter: extracts existing field" {
    run md_read_frontmatter_field "$TEST_TMPDIR/change.md" "change_id"
    [ "$status" -eq 0 ]
    [ "$output" = "2603120700-introduce-umergepr" ]
}

@test "frontmatter: extracts field with URL value" {
    run md_read_frontmatter_field "$TEST_TMPDIR/change.md" "issue_url"
    [ "$status" -eq 0 ]
    [ "$output" = "https://github.com/org/repo/issues/42" ]
}

@test "frontmatter: extracts timestamp field" {
    run md_read_frontmatter_field "$TEST_TMPDIR/change.md" "registered_at"
    [ "$status" -eq 0 ]
    [ "$output" = "2026-03-12T07:00:31Z" ]
}

@test "frontmatter: fails for absent field" {
    run md_read_frontmatter_field "$TEST_TMPDIR/change.md" "nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"frontmatter field not found"* ]]
    [[ "$output" == *"nonexistent"* ]]
}

@test "frontmatter: fails when no frontmatter present" {
    run md_read_frontmatter_field "$TEST_TMPDIR/no-frontmatter.md" "field"
    [ "$status" -eq 1 ]
    [[ "$output" == *"frontmatter field not found"* ]]
}

@test "frontmatter: fails for missing file" {
    run md_read_frontmatter_field "$TEST_TMPDIR/nonexistent.md" "field"
    [ "$status" -eq 1 ]
    [[ "$output" == *"file not found"* ]]
}

@test "frontmatter: does not match field outside frontmatter" {
    cat > "$TEST_TMPDIR/body-field.md" <<'EOF'
---
real_field: real_value
---

# Title

fake_field: fake_value
EOF
    run md_read_frontmatter_field "$TEST_TMPDIR/body-field.md" "fake_field"
    [ "$status" -eq 1 ]
    [[ "$output" == *"frontmatter field not found"* ]]
}

# ---------------------------------------------------------------------------
# md_read_title
# ---------------------------------------------------------------------------

@test "title: extracts standard title" {
    run md_read_title "$TEST_TMPDIR/change.md"
    [ "$status" -eq 0 ]
    [ "$output" = "Change request: Introduce umergepr action" ]
}

@test "title: extracts title without frontmatter" {
    run md_read_title "$TEST_TMPDIR/no-frontmatter.md"
    [ "$status" -eq 0 ]
    [ "$output" = "Simple title" ]
}

@test "title: fails when no heading present" {
    run md_read_title "$TEST_TMPDIR/no-heading.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no title heading found"* ]]
}

@test "title: fails for missing file" {
    run md_read_title "$TEST_TMPDIR/nonexistent.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"file not found"* ]]
}

@test "title: skips ## headings, returns only # heading" {
    cat > "$TEST_TMPDIR/h2-only.md" <<'EOF'
---
field: value
---

## Section heading

Body.
EOF
    run md_read_title "$TEST_TMPDIR/h2-only.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no title heading found"* ]]
}

@test "title: returns first # heading when multiple exist" {
    cat > "$TEST_TMPDIR/multi-h1.md" <<'EOF'
# First title

# Second title
EOF
    run md_read_title "$TEST_TMPDIR/multi-h1.md"
    [ "$status" -eq 0 ]
    [ "$output" = "First title" ]
}

