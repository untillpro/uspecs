#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# ---------------------------------------------------------------------------
# scn: No Active Change Folders
# ---------------------------------------------------------------------------

@test "uarchive: scn: No Active Change Folders" {
    # Then AI Agent displays "No active working change folder found"
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uarchive
    [ "$status" -eq 0 ]
    [[ "$output" == *"No active working change folder found"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
}

# ---------------------------------------------------------------------------
# scn: Multiple Active Change Folders
# ---------------------------------------------------------------------------

@test "uarchive: scn: Multiple Active Change Folders: asks to select" {
    # Then AI Agent asks Engineer to select which folder to archive
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    _make_change_folder "2601010000-alpha"
    _make_change_folder "2601010000-beta"

    uspecs action uarchive
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"softeng.sh action uarchive"* ]]
}

# ---------------------------------------------------------------------------
# scn: Archive all modified change folders
# ---------------------------------------------------------------------------

@test "uarchive: scn: Archive all modified change folders: three folders" {
    # Then all change folders that have modifications vs pr_remote/default_branch are archived
    # And count of archived, unchanged, and failed folders is reported
    # And per-folder ok/failed lines with source and target paths are reported
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    _make_change_folder "2601010000-alpha"
    _make_change_folder "2601010000-beta"
    _make_change_folder "2601010000-gamma"

    uspecs action uarchive --all
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"3 archived"* ]]
    [[ "$output" == *"ok: uspecs/changes/2601010000-alpha -> uspecs/changes/archive/"* ]]
    [[ "$output" == *"ok: uspecs/changes/2601010000-beta -> uspecs/changes/archive/"* ]]
    [[ "$output" == *"ok: uspecs/changes/2601010000-gamma -> uspecs/changes/archive/"* ]]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-alpha" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-beta" ]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-gamma" ]
}

# ---------------------------------------------------------------------------
# scn: Archive change request: single + --change-folder + uncompleted
# ---------------------------------------------------------------------------

@test "uarchive: scn: Archive change request: single + --change-folder + uncompleted" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    # Single WCF, auto-detected
    # Then Active Change Folder is moved to changes archive
    _make_change_folder "2601010000-single"

    uspecs action uarchive
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"archived"* ]]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-single" ]
    local archived
    archived=$(find "$PROJECT_ROOT/uspecs/changes/archive" -type d -name "*single" 2>/dev/null | head -1)
    [ -n "$archived" ]

    # --change-folder archives specified folder
    _make_change_folder "2601010000-specific"

    uspecs action uarchive --change-folder "uspecs/changes/2601010000-specific"
    [ "$status" -eq 0 ]
    [[ "$output" == *"archived"* ]]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-specific" ]

    # Uncompleted items block archive
    _make_change_folder "2601010000-blocked"
    echo "- [ ] uncompleted task" >> "$PROJECT_ROOT/uspecs/changes/2601010000-blocked/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add uncompleted item"

    uspecs action uarchive --change-folder "uspecs/changes/2601010000-blocked"
    [ "$status" -ne 0 ]
    [[ "$output" == *"uncompleted todo item"* ]]
    [ -d "$PROJECT_ROOT/uspecs/changes/2601010000-blocked" ]
}

# ---------------------------------------------------------------------------
# --all with failures returns non-zero
# ---------------------------------------------------------------------------

@test "uarchive: --all with uncompleted items returns non-zero and reports per-folder details" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    _make_change_folder "2601010000-good"
    _make_change_folder "2601010000-bad"
    echo "- [ ] uncompleted task" >> "$PROJECT_ROOT/uspecs/changes/2601010000-bad/change.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add uncompleted item"

    uspecs action uarchive --all
    [ "$status" -ne 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *"ok: uspecs/changes/2601010000-good -> uspecs/changes/archive/"* ]]
    [[ "$output" == *"failed: uspecs/changes/2601010000-bad (uncompleted items)"* ]]
    [[ "$output" == *"1 archived"* ]]
    [[ "$output" == *"1 failed"* ]]
    [ ! -d "$PROJECT_ROOT/uspecs/changes/2601010000-good" ]
    [ -d "$PROJECT_ROOT/uspecs/changes/2601010000-bad" ]
}

# ---------------------------------------------------------------------------
# Error cases
# ---------------------------------------------------------------------------

@test "uarchive: error cases: unknown flag + mutually exclusive options" {
    cd "$PROJECT_ROOT"

    # unknown flag rejected
    uspecs action uarchive --bogus
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown argument"* ]]

    # --all and --change-folder mutually exclusive
    uspecs action uarchive --all --change-folder "foo"
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"mutually exclusive"* ]]
}
