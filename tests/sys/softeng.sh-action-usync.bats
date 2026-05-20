#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Helper: set up a git repo on a feature branch with a WCF and a source change
# outside uspecs/changes/. Tests that need git but don't go through this helper
# must call _setup_git_repo themselves (the default setup() no longer inits git).
_setup_usync_branch() {
    _setup_git_origin
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-test-change"
    echo "new content" > "$PROJECT_ROOT/src-file.txt"
    git add .
    git commit -q -m "source change"
}

# ---------------------------------------------------------------------------
# Rule: Core behavior
# ---------------------------------------------------------------------------

@test "usync: scn: Core output: small diff emits artifact usync_diff and instr_usync" {
    # Then WCF Implementation Plan in change.md or impl.md (if exists) is updated to reflect changes in diff_scope vs baseline
    _setup_usync_branch

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *'<artifact id="usync_diff"'* ]]
    [[ "$output" == *"</artifact>"* ]]
    [[ "$output" == *"instr_usync"* ]]
    [[ "$output" == *"src-file.txt"* ]]
    # Verify template vars are substituted
    [[ "$output" == *"uspecs/changes/2601010000-test-change"* ]]
    [[ "$output" == *"uspecs/specs"* ]]
}

@test "usync: scn: Core output: diff payload entity-escaped" {
    # End-to-end: source bytes containing & < > must surface as XML entities
    # inside the <artifact id="usync_diff"> body, never as raw chars.
    _setup_git_origin
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-test-change"
    cat > "$PROJECT_ROOT/markup.html" <<'EOF'
<div class="x">a & b</div>
EOF
    git add .
    git commit -q -m "source change with markup"

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *'<artifact id="usync_diff"'* ]]
    [[ "$output" == *"&lt;div"* ]]
    [[ "$output" == *"a &amp; b"* ]]
    [[ "$output" == *"&lt;/div&gt;"* ]]
    # Raw `+<div` from the diff must not appear -- it must be entity-escaped
    [[ "$output" != *"+<div class"* ]]
}

@test "usync: scn: Core output: impl.md detected when present" {
    # Then WCF Implementation Plan in change.md or impl.md (if exists) is updated
    _setup_usync_branch
    echo "# Impl" > "$PROJECT_ROOT/uspecs/changes/2601010000-test-change/impl.md"
    git add .
    git commit -q -m "add impl.md"

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *"impl.md"* ]]
}

@test "usync: scn: Core output: issue.md triggers discrepancy reporting" {
    # And If issue.md exists, Engineer is informed of any discrepancies between issue.md and actual sources
    _setup_usync_branch
    echo "# Issue" > "$PROJECT_ROOT/uspecs/changes/2601010000-test-change/issue.md"
    git add .
    git commit -q -m "add issue.md"

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *"issue.md"* ]]
    [[ "$output" == *"contradict"* ]]
}

@test "usync: scn: Core output: empty diff" {
    # Then WCF Implementation Plan is updated (agent-side no-op for empty diff)
    _setup_git_origin
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-test-change"
    # No source changes outside changes folder

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *'<artifact id="usync_diff"'* ]]
    [[ "$output" == *"</artifact>"* ]]
    [[ "$output" == *"instr_usync"* ]]
    [[ "$output" == *"Diff size: 0 bytes"* ]]
}

@test "usync: scn: Core output: changes inside uspecs/changes/ excluded from diff" {
    _setup_usync_branch
    # Add another change inside the changes folder -- should not appear in diff
    echo "extra" >> "$PROJECT_ROOT/uspecs/changes/2601010000-test-change/change.md"
    git add .
    git commit -q -m "change inside changes folder"

    uspecs action usync
    [ "$status" -eq 0 ]
    # The diff artifact should contain src-file.txt but NOT the changes folder content
    [[ "$output" == *"src-file.txt"* ]]
}

# ---------------------------------------------------------------------------
# Rule: Large diff handling
# ---------------------------------------------------------------------------

@test "usync: scn: Diff exceeds size threshold without -y option" {
    # Then Engineer is informed that there are a lot of changes since the baseline and asked whether to proceed
    _setup_usync_branch
    # Create a file larger than 100K
    dd if=/dev/zero bs=1024 count=120 2>/dev/null | tr '\0' 'x' > "$PROJECT_ROOT/large-file.txt"
    git add .
    git commit -q -m "add large file"

    uspecs action usync
    [ "$status" -eq 0 ]
    [[ "$output" == *"instr_usync_large_diff"* ]]
    [[ "$output" == *"since the baseline"* ]]
    [[ "$output" == *"bytes"* ]]
    [[ "$output" == *"action usync -y"* ]]
    # instr_usync should NOT be emitted
    [[ "$output" != *"instr_usync\""* ]] || [[ "$output" != *"instr_usync "* ]]
}

@test "usync: scn: Diff exceeds size threshold with -y option" {
    # Then Core output is produced
    _setup_usync_branch
    dd if=/dev/zero bs=1024 count=120 2>/dev/null | tr '\0' 'x' > "$PROJECT_ROOT/large-file.txt"
    git add .
    git commit -q -m "add large file"

    uspecs action usync -y
    [ "$status" -eq 0 ]
    [[ "$output" == *'<artifact id="usync_file_list"'* ]]
    [[ "$output" == *"</artifact>"* ]]
    [[ "$output" == *"instr_usync"* ]]
    [[ "$output" == *"large-file.txt"* ]]
    [[ "$output" == *"src-file.txt"* ]]
    # Should reference diff file command
    [[ "$output" == *"diff file"* ]]
}

# ---------------------------------------------------------------------------
# Rule: Edge cases
# ---------------------------------------------------------------------------

# Change Folder validations#Exactly one Working Change Folder
@test "usync: scn: Exactly one Working Change Folder: no WCF" {
    _setup_git_origin
    git checkout -q -b feature-branch
    echo "content" > "$PROJECT_ROOT/some-file.txt"
    git add .
    git commit -q -m "no WCF commit"

    uspecs action usync
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No Working Change Folder"* ]]
}

# Change Folder validations#Exactly one Working Change Folder
@test "usync: scn: Exactly one Working Change Folder: multiple WCFs" {
    _setup_git_origin
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-first"
    _make_change_folder "2601010000-second"

    uspecs action usync
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
    [[ "${stderr:-}" == *"2601010000-first"* ]]
    [[ "${stderr:-}" == *"2601010000-second"* ]]
}

# Git validations#Project inside Git working tree
@test "usync: scn: Project inside Git working tree: no git repo" {
    # Uses the cheap default setup() -- no git repo initialised.

    uspecs action usync
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"No git repository"* ]]
}

# Git validations#Git working tree is clean
@test "usync: scn: Git working tree is clean: uncommitted changes" {
    _setup_usync_branch
    echo "dirty" > "$PROJECT_ROOT/dirty-file.txt"

    uspecs action usync
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"uncommitted changes"* ]]
}

# Git validations#Git working tree is clean
@test "usync: scn: Git working tree is clean: current branch is default branch" {
    _setup_git_origin

    uspecs action usync
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"default branch"* ]]
}
