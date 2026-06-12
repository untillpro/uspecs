#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

# Every test in this file needs git with an `origin` remote because uimpl
# resolves Working Change Folders against `origin/<default-branch>` (via
# wcf_list's merge-base lookup), so override setup() at file scope to include
# _setup_git_origin.
setup() {
    _setup_project_root
    _setup_gh_stub
    _setup_git_origin
}

# ---------------------------------------------------------------------------
# scn: No Active Working Change Folders + Multiple Active Working Change Folders + uimpl base behavior
# ---------------------------------------------------------------------------

@test "uimpl: scn: No Active Working Change Folders + Multiple Active Working Change Folders + uimpl base behavior" {
    # scn: No Active Working Change Folders
    # Then AI Agent displays a message "No active working change folder found"
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"No active working change folder found"* ]]

    # scn: Multiple Active Working Change Folders
    # And lists all Active Change Folders
    _make_change_folder "2601010000-alpha"
    _make_change_folder "2601010000-beta"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"softeng.sh action uimpl"* ]]

    # Remove one folder so single WCF remains
    rm -rf "$PROJECT_ROOT/uspecs/changes/2601010000-beta"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "remove beta"

    # scn: uimpl base behavior: impl.md does not exist -> uses change.md
    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Implementation Plan File: change.md"* ]]

    # scn: uimpl base behavior: impl.md exists -> uses impl.md
    echo "# Implementation plan" > "$PROJECT_ROOT/uspecs/changes/2601010000-alpha/impl.md"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Implementation Plan File: impl.md"* ]]
}

# ---------------------------------------------------------------------------
# scn: Some unchecked to-do items + Only Review Item unchecked
# ---------------------------------------------------------------------------

# Helper: write impl.md with a todo item and a review item, run uimpl
# Usage: _uimpl_with_review_form "- [ ] Review"
_uimpl_with_review_form() {
    local review_line="$1"
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        "$review_line" \
        > "$impl_path"
    uspecs action uimpl
}

@test "uimpl: scn: Some unchecked to-do items + Only Review Item unchecked" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    # scn: Some unchecked to-do items: with review item "- [ ] Review"
    # Review item is excluded from the emitted unchecked items list.
    _uimpl_with_review_form '- [ ] Review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]

    # scn: Some unchecked to-do items: with review item "- [ ] review" (lowercase)
    _uimpl_with_review_form '- [ ] review'
    [ "$status" -eq 0 ]

    # scn: Review checkbox outside the first unchecked block does not reduce
    # the counted non-review todo items.
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '' \
        'Notes' \
        '- [ ] Review' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]
    [[ "$output" != *'<instruction id="instr_uimpl_review_pending"'* ]]

    # scn: Bare review item outside the first unchecked block also does not
    # reduce the counted non-review todo items.
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '' \
        'Notes' \
        '- review' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]
    [[ "$output" != *'<instruction id="instr_uimpl_review_pending"'* ]]

    # scn: Some unchecked to-do items: with review item "- Review" (no checkbox)
    _uimpl_with_review_form '- Review'
    [ "$status" -eq 0 ]

    # scn: Some unchecked to-do items: with review item "- review" (no checkbox, lowercase)
    _uimpl_with_review_form '- review'
    [ "$status" -eq 0 ]

    # scn: Some unchecked to-do items: checked review "- [x] Review" is treated as a normal item
    _uimpl_with_review_form '- [x] Review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]

    # scn: Some unchecked to-do items: without review item
    # Then AI Agent implements each unchecked To-Do Item
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '- [ ] update: [file2.go](../../file2.go)' \
        '  - fix: something else' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]

    # scn: Only Review Item unchecked: "- [ ] Review" -> review pending
    # Then AI Agent displays a message "Review item is pending"
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [x] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '- [ ] Review' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Review item is pending"* ]]

    # scn: Only Review Item unchecked: "- Review" (no checkbox) -> review pending
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [x] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '- Review' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Review item is pending"* ]]

    # scn: Only Review Item unchecked: "- review" (no checkbox, lowercase) -> review pending
    # Then AI Agent displays a message "Review item is pending"
    # And does not emit next todo instructions
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [x] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '- review' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *"Review item is pending"* ]]
    [[ "$output" == *'<instruction id="instr_uimpl_review_pending"'* ]]
    [[ "$output" != *'<instruction id="instr_uimpl_todos"'* ]]
    [[ "$output" != *"Complete to-do items"* ]]

}

# ---------------------------------------------------------------------------
# Helper: append `## How` to change.md and commit, so the new uimpl
# How-creation branch is bypassed and tests exercise the cascade / completion
# paths that follow `## How`.
# Usage: _add_how_to_change_md "2601010000-my-change"
# ---------------------------------------------------------------------------
_add_how_to_change_md() {
    local folder_name="$1"
    local change_path="$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    printf '\n%s\n' '## How' >> "$change_path"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add How to $folder_name"
}

# ---------------------------------------------------------------------------
# Helper: write impl.md with given sections (all items checked), commit, run uimpl
# Usage: _uimpl_with_sections "domains" "fd" "prov" ...
#   Supported section names: domains, fd, prov, td, constr
# ---------------------------------------------------------------------------
_uimpl_with_sections() {
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    {
        echo '# Implementation plan: Test'
        echo ''
        for sec in "$@"; do
            case "$sec" in
                domains) echo '## Domain specifications' ;;
                fd)    echo '## Functional design specifications' ;;
                prov)  echo '## Provisioning and configuration' ;;
                td)    echo '## Technical design specifications' ;;
                constr) echo '## Construction' ;;
            esac
            echo ''
            echo '- [x] placeholder item'
            echo ''
        done
    } > "$impl_path"
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
}

# ---------------------------------------------------------------------------
# scn: No unchecked to-do items -- all cases
# Check presence/absence of artdef blocks by their id attribute.
# ---------------------------------------------------------------------------

@test "uimpl: scn: No unchecked to-do items: section priority and completion" {
    # condition: Domain specifications section does not exist and it is needed
    # condition: Functional design specifications section does not exist and it is needed
    # condition: Technical design specifications section does not exist and it is needed
    # condition: Provisioning and configuration section does not exist and it is needed
    # condition: Construction section does not exist and it is needed
    # condition: Nothing of the above
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    # Pre-populate `## How` so the cascade path under test is reached
    # (without it, the new uimpl How-creation branch would fire first).
    _add_how_to_change_md "2601010000-my-change"
    # Create specs folder so specs_maybe=1
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # condition: all sections do not exist and are needed -> all 5 bullets present
    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"- Domain specifications section"*"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" == *"- Functional design section"*"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" == *"- Provisioning and configuration section"*"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" == *"- Technical design section"*"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # condition: Domain specifications exists -> domains absent, fd/prov/td/constr present
    _uimpl_with_sections domains
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" == *"- Functional design section"*"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" == *"- Provisioning and configuration section"*"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" == *"- Technical design section"*"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # condition: Domains + Functional design specifications exist -> domains/fd absent, prov/td/constr present
    _uimpl_with_sections domains fd
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" == *"- Provisioning and configuration section"*"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" == *"- Technical design section"*"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # condition: Domains + FD + Provisioning exist -> domains/fd/prov absent, td/constr present
    _uimpl_with_sections domains fd prov
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" != *"- Provisioning and configuration section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" == *"- Technical design section"*"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # condition: Domains + FD + Provisioning + TD exist -> only constr present
    _uimpl_with_sections domains fd prov td
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" != *"- Provisioning and configuration section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" != *"- Technical design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # condition: Nothing of the above -> completed, no bullets
    _uimpl_with_sections domains fd prov td constr
    [ "$status" -eq 0 ]
    [[ "$output" == *"completed"* ]]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-constr"* ]]
}

@test "uimpl: scn: No unchecked to-do items: no specs folder skips Domain specifications, Functional design specifications and Technical design specifications" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    # Pre-populate `## How` so the cascade path under test is reached
    # (without it, the new uimpl How-creation branch would fire first).
    _add_how_to_change_md "2601010000-my-change"
    # Remove specs folder -> specs_maybe="" (empty dir, not tracked by git)
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    # No sections, no specs -> domains/fd/td absent, only prov/constr present
    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" == *"- Provisioning and configuration section"*"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" != *"- Technical design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # Prov exists, no specs -> only constr present
    _uimpl_with_sections prov
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
    [[ "$output" != *"- Provisioning and configuration section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-prov"* ]]
    [[ "$output" != *"- Technical design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-td"* ]]
    [[ "$output" == *"- Construction and Quick start sections"*"Required skill: uspecs-sec-constr"* ]]

    # Prov+Constr exist, no specs -> completed
    _uimpl_with_sections prov constr
    [ "$status" -eq 0 ]
    [[ "$output" == *"completed"* ]]
}

@test "uimpl: scn: Construction frontmatter sub-bullets (scope/breaking) appear when constr_maybe is set, with scope branch driven by domains_defined" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    # Pre-populate `## How` so the cascade path under test is reached
    # (without it, the new uimpl How-creation branch would fire first).
    _add_how_to_change_md "2601010000-my-change"

    # Case 1: specs folder + at least one domain.md -> specs-derived scope branch
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod/softeng"
    echo '# domain' > "$PROJECT_ROOT/uspecs/specs/prod/domain.md"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` from the contexts listed under \`## Contexts\` in \`uspecs/specs/{domain}/domain.md\`"* ]]
    [[ "$output" == *"YAML flow list"*"scope: [softeng]"* ]]
    [[ "$output" != *"short free-form name from the code area"* ]]
    [[ "$output" == *"frontmatter \`breaking: true\`"* ]]

    # Case 2: specs folder exists but no domain.md anywhere -> free-form scope branch
    rm -f "$PROJECT_ROOT/uspecs/specs/prod/domain.md"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` as a short free-form name from the code area"* ]]
    [[ "$output" == *"YAML flow list"*"scope: [auth]"* ]]
    [[ "$output" != *"contexts listed under \`## Contexts\`"* ]]
    [[ "$output" == *"frontmatter \`breaking: true\`"* ]]

    # Case 3: no specs folder at all -> free-form scope branch
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` as a short free-form name from the code area"* ]]
    [[ "$output" == *"YAML flow list"*"scope: [auth]"* ]]
    [[ "$output" != *"contexts listed under \`## Contexts\`"* ]]
    [[ "$output" == *"frontmatter \`breaking: true\`"* ]]

    # Case 4: Construction section already exists (constr_maybe="") -> sub-bullets absent
    _uimpl_with_sections prov constr
    [ "$status" -eq 0 ]
    [[ "$output" != *"frontmatter \`scope:\`"* ]]
    [[ "$output" != *"frontmatter \`breaking: true\`"* ]]
}


# ---------------------------------------------------------------------------
# scn: unchecked items are emitted into the instr_uimpl_todos prompt
# ---------------------------------------------------------------------------

@test "uimpl: unchecked items with sub-bullets are emitted in the prompt" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        '  - add: another detail' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    [[ "$output" == *'- [ ] update: [file.go](../../file.go)'* ]]
    [[ "$output" == *'  - fix: something'* ]]
    [[ "$output" == *'  - add: another detail'* ]]
}

@test "uimpl: multiple unchecked items appear in order" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [alpha.go](../../alpha.go)' \
        '  - fix: alpha detail' \
        '- [ ] update: [beta.go](../../beta.go)' \
        '  - fix: beta detail' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'alpha.go'*'beta.go'* ]]
    [[ "$output" == *'  - fix: alpha detail'* ]]
    [[ "$output" == *'  - fix: beta detail'* ]]
}

@test "uimpl: pending review item bounds emitted unchecked items" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    local review_line
    for review_line in '- [ ] Review' '- [ ] review' '- Review' '- review'; do
        printf '%s\n' \
            '# Implementation plan: Test' \
            '' \
            '## Construction' \
            '' \
            '- [ ] update: [alpha.go](../../alpha.go)' \
            '  - fix: alpha detail' \
            "$review_line" \
            '- [ ] update: [beta.go](../../beta.go)' \
            '  - fix: beta detail' \
            > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

        uspecs action uimpl
        [ "$status" -eq 0 ]
        [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
        local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
        todos_block="${todos_block%%</instruction>*}"
        [[ "$todos_block" == *'alpha.go'* ]]
        [[ "$todos_block" == *'  - fix: alpha detail'* ]]
        [[ "$todos_block" != *"$review_line"* ]]
        [[ "$todos_block" != *'beta.go'* ]]
        [[ "$todos_block" != *'  - fix: beta detail'* ]]
    done
}

@test "uimpl: multi-line item with blank line inside is preserved" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [alpha.go](../../alpha.go)' \
        '  - fix: first detail' \
        '' \
        '  - fix: second detail after blank line' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'  - fix: first detail'* ]]
    [[ "$output" == *'  - fix: second detail after blank line'* ]]
}

# ---------------------------------------------------------------------------
# scn: first-area scoping -- only the first contiguous run of unchecked items
# is emitted into the instr_uimpl_todos prompt. The run is terminated by a
# section header or by any non-indented non-empty line.
# ---------------------------------------------------------------------------

@test "uimpl: first area scoping: section header terminates the area" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Functional design specifications' \
        '' \
        '- [ ] update: [alpha.feature](../../alpha.feature)' \
        '  - add: alpha scenario' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [beta.go](../../beta.go)' \
        '  - fix: beta detail' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *'alpha.feature'* ]]
    [[ "$todos_block" == *'  - add: alpha scenario'* ]]
    [[ "$todos_block" != *'beta.go'* ]]
    [[ "$todos_block" != *'  - fix: beta detail'* ]]
}

@test "uimpl: first area scoping: non-indented line terminates the area" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [alpha.go](../../alpha.go)' \
        '  - fix: alpha detail' \
        'some prose paragraph between items' \
        '- [ ] update: [beta.go](../../beta.go)' \
        '  - fix: beta detail' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *'alpha.go'* ]]
    [[ "$todos_block" != *'beta.go'* ]]
}

@test "uimpl: first area scoping: area can start in a later section when earlier sections have no unchecked items" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Functional design specifications' \
        '' \
        '- [x] update: [done.feature](../../done.feature)' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [alpha.go](../../alpha.go)' \
        '  - fix: alpha detail' \
        '- [ ] update: [beta.go](../../beta.go)' \
        '  - fix: beta detail' \
        '' \
        '## Provisioning and configuration' \
        '' \
        '- [ ] update: [gamma.yaml](../../gamma.yaml)' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    # Both alpha and beta are in the first contiguous run under Construction
    [[ "$todos_block" == *'alpha.go'* ]]
    [[ "$todos_block" == *'beta.go'* ]]
    # gamma in a later section is excluded
    [[ "$todos_block" != *'gamma.yaml'* ]]
}

# ---------------------------------------------------------------------------
# scn: permissive heading detection (regression for canonical short forms)
# ---------------------------------------------------------------------------

# Helper: write impl.md with given verbatim heading lines, run uimpl
# Usage: _uimpl_with_headings "## Functional design" "### Construction"
# Each heading is followed by a checked placeholder item so the file has no
# unchecked todos and uimpl emits the next-section menu.
_uimpl_with_headings() {
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    {
        echo '# Implementation plan: Test'
        echo ''
        for heading in "$@"; do
            echo "$heading"
            echo ''
            echo '- [x] placeholder item'
            echo ''
        done
    } > "$impl_path"
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
}

@test "uimpl: permissive heading detection: canonical short forms" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Canonical short FD heading produced by the uspecs-sec-fd skill.
    # Original bug: `## Functional design` was not detected because the
    # case pattern required the trailing word "specifications".
    _uimpl_with_headings '## Functional design'
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]

    # Canonical short TD heading produced by the uspecs-sec-td skill.
    _uimpl_with_headings '## Technical design'
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Technical design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-td"* ]]
}

@test "uimpl: permissive heading detection: deeper heading levels" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # h3 Construction heading must still be detected; menu collapses to "completed".
    _uimpl_with_headings '### Construction'
    [ "$status" -eq 0 ]
    [[ "$output" == *"completed"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-constr"* ]]
}

@test "uimpl: permissive heading detection: non-canonical trailing words" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Trailing words after the canonical name must still match (locks in `*` glob).
    _uimpl_with_headings '## Functional design notes'
    [ "$status" -eq 0 ]
    [[ "$output" != *"- Functional design section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-fd"* ]]
}


# ---------------------------------------------------------------------------
# scn: Auto-invoke self-review after todos
# After the Agent completes unchecked todos, the uimpl emit must include a
# chained instruction to invoke `softeng self-review`. The --type is selected
# from the section the completed todos belong to:
#   - Construction todos     -> --type construction
#   - any specs-side todos   -> --type specs
# --no-self-review on uimpl suppresses the chain.
# ---------------------------------------------------------------------------

# Helper: write impl.md with a single unchecked item under the given heading
# and run uimpl. Extracts the instr_uimpl_todos block into $todos_block.
_uimpl_with_section_todo() {
    local heading="$1"; shift
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        "$heading" \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        > "$impl_path"
    uspecs action uimpl "$@"
}

@test "uimpl: Construction todos emit chained self-review --type construction --stage A" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    _uimpl_with_section_todo '## Construction'
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *"self-review"* ]]
    [[ "$todos_block" == *"--type construction"* ]]
    [[ "$todos_block" == *"--stage A"* ]]
    # -b is rejected for construction, so the chain must NOT carry it
    [[ "$todos_block" != *"--type construction --stage A -b"* ]]
}

@test "uimpl: specs-side todos emit chained self-review --type specs --stage A -b 4" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    # Functional design section -> specs review with default budget
    _uimpl_with_section_todo '## Functional design specifications'
    [ "$status" -eq 0 ]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *"self-review --type specs --stage A -b 4"* ]]

    # Technical design section -> specs review with default budget
    _uimpl_with_section_todo '## Technical design specifications'
    [ "$status" -eq 0 ]
    todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *"self-review --type specs --stage A -b 4"* ]]

    # Domain specifications section -> specs review with default budget
    _uimpl_with_section_todo '## Domain specifications'
    [ "$status" -eq 0 ]
    todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *"self-review --type specs --stage A -b 4"* ]]

    # Provisioning and configuration section -> specs review with default budget
    _uimpl_with_section_todo '## Provisioning and configuration'
    [ "$status" -eq 0 ]
    todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" == *"self-review --type specs --stage A -b 4"* ]]
}

@test "uimpl: --no-self-review suppresses the chained self-review instruction" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"

    _uimpl_with_section_todo '## Construction' --no-self-review
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" != *"self-review"* ]]
}

# ---------------------------------------------------------------------------
# scn: Auto-invoke self-review after a section-creation cycle
# When uimpl appends a section (no unchecked to-dos but a section is missing),
# the emitted instr_uimpl prompt chains a specs self-review with the default
# retry budget of 4. `--no-self-review` suppresses the chain. The "plan
# completed" cycle (all sections present, no to-dos) does not chain.
# ---------------------------------------------------------------------------

@test "uimpl: section-creation cycle chains self-review --type specs --stage A -b 4" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    # Pre-populate `## How` so the chain-emission cascade path under test is
    # reached (without it, the new uimpl How-creation branch would fire first).
    _add_how_to_change_md "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # No sections present -> the next section to author is Domain
    # specifications; the rendered instr_uimpl prompt must include a chained
    # self-review invocation with the default budget.
    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" == *"\"$PROJECT_ROOT/bin/softeng.sh\" self-review --type specs --stage A -b 4"* ]]
}

@test "uimpl: --no-self-review on a section-creation cycle suppresses the chain" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    # Pre-populate `## How` so the no-chain cascade path under test is reached
    # (without it, the new uimpl How-creation branch would fire first).
    _add_how_to_change_md "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Re-implement _uimpl_with_sections inline to pass --no-self-review,
    # since the helper does not forward extra flags.
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    printf '%s\n' '# Implementation plan: Test' '' > "$impl_path"
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change" --no-self-review
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

@test "uimpl: plan-completed cycle does NOT chain self-review" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # All sections present and all items checked -> "plan completed" branch;
    # no section is appended, so no chain.
    _uimpl_with_sections domains fd prov td constr
    [ "$status" -eq 0 ]
    [[ "$output" == *"completed"* ]]
    [[ "$output" != *"self-review --type specs --stage A"* ]]
}

# ---------------------------------------------------------------------------
# scn: How section creation when missing
# When no unchecked to-dos exist, no planning section has been started, and
# `## How` is absent from `change.md`, `uimpl` (without `--plan`) emits the
# instr_uimpl_how prompt instructing the agent to author `## How` per
# `@artdef_change_how` against `change.md`, and stops -- no chained
# self-review, no planning-sections cascade. `--plan` opts out and falls
# through to the existing cascade.
# ---------------------------------------------------------------------------

@test "uimpl: How creation: missing How + no planning section + no todos -> emits How prompt targeting change.md" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # _make_change_folder leaves change.md with frontmatter only:
    # no `## How`, no planning section, no unchecked to-dos.
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]
    [[ "$output" == *'@artdef_change_how'* ]]
    # Targets change.md (How lives on the change request, not impl.md).
    [[ "$output" == *'uspecs/changes/2601010000-my-change/change.md'* ]]
    # No chained self-review (How produces no plan bullets to review).
    [[ "$output" != *"self-review --type specs --stage A"* ]]
    # No planning-sections cascade prompt.
    [[ "$output" != *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"Required skill: uspecs-sec-domains"* ]]
}

@test "uimpl: How creation: --plan skips How branch and emits planning-sections cascade" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Same setup as above (frontmatter-only change.md, no sections).
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change" --plan
    [ "$status" -eq 0 ]
    # The new How branch is skipped...
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]
    # ...and the existing cascade runs (Domain specifications is first).
    [[ "$output" == *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" == *"- Domain specifications section"*"Required skill: uspecs-sec-domains"* ]]
}

@test "uimpl: How creation: existing ## How falls through to planning-sections cascade" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Append `## How` to the existing change.md so how_exists="1".
    _add_how_to_change_md "2601010000-my-change"

    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]
    # Existing cascade prompt is emitted (Domain specifications is the first
    # missing planning section).
    [[ "$output" == *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" == *"- Domain specifications section"*"Required skill: uspecs-sec-domains"* ]]
}

@test "uimpl: How creation: impl.md present but change.md lacks ## How -> branch still targets change.md" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Add an impl.md with no unchecked to-dos and no planning section.
    # `## How` lives on change.md only, which still has frontmatter only.
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    printf '%s\n' '# Implementation plan: Test' '' > "$impl_path"

    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]
    # Despite impl.md existing, the How branch targets change.md (not impl.md).
    [[ "$output" == *'uspecs/changes/2601010000-my-change/change.md'* ]]
    [[ "$output" != *'uspecs/changes/2601010000-my-change/impl.md'* ]]
}

@test "uimpl: How creation: unchecked to-dos present run the existing todos branch regardless of --plan" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Add an impl.md with an unchecked Construction to-do; change.md still
    # lacks `## How`, but the to-dos branch must win.
    local impl_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"
    printf '%s\n' \
        '# Implementation plan: Test' \
        '' \
        '## Construction' \
        '' \
        '- [ ] update: [file.go](../../file.go)' \
        '  - fix: something' \
        > "$impl_path"

    # Without --plan: todos branch wins, How branch does not fire.
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]

    # With --plan: same -- todos branch still wins.
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change" --plan
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_todos"'* ]]
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]
}

@test "uimpl: How creation: nested ### How does not satisfy how_exists; new branch still fires" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Append a nested `### How` (level 3) to change.md. The canonical heading
    # per `@artdef_change_how` is `## How` (level 2); a nested heading must
    # NOT be treated as an existing How section.
    local change_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/change.md"
    printf '\n%s\n' '### How' >> "$change_path"
    git -C "$PROJECT_ROOT" add .
    git -C "$PROJECT_ROOT" commit -q -m "add nested ### How"

    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    # The new branch fires (nested `### How` does not bypass it).
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]
    [[ "$output" == *'@artdef_change_how'* ]]
}

# ---------------------------------------------------------------------------
# scn: Fault localization gate
# The gate is the first branch of the uimpl decision cascade: when change.md
# has frontmatter `type: fix` and the unlocalized fault marker
# `? <-- fault: not yet localized` appears as a standalone line inside the
# `## What` section, uimpl emits the instr_uimpl_fault prompt and
# authors no How and no planning sections. No option bypasses the gate.
# ---------------------------------------------------------------------------

# The unlocalized fault marker as a flowchart step line (shared by the
# positive fixture and the "outside the What section" negative).
FAULT_MARKER_STEP='      ?               <-- fault: not yet localized'

# Helper: overwrite change.md for 2601010000-my-change with the given
# frontmatter type and body lines (uncommitted; uimpl reads it from disk).
# Usage: _write_change_md <type> <body-line>...
_write_change_md() {
    local type="$1"; shift
    local change_path="$PROJECT_ROOT/uspecs/changes/2601010000-my-change/change.md"
    {
        printf '%s\n' \
            '---' \
            'change_id: 2601010000-my-change' \
            "type: $type" \
            '---' \
            '' \
            '# Change request: Test' \
            ''
        printf '%s\n' "$@"
    } > "$change_path"
}

# Helper: emit What-section body lines whose fenced flowchart carries the
# unlocalized fault marker as a step (mirrors artdef_change_what_fix.md).
_what_with_marker() {
    printf '%s\n' \
        '## What' \
        '' \
        'Symptom: downstream API rejects the request' \
        '' \
        '```text' \
        'user submits form' \
        '      |' \
        '      v' \
        "$FAULT_MARKER_STEP" \
        '      |' \
        '      v' \
        'downstream API rejects request   (symptom)' \
        '```' \
        '' \
        'Corrected behavior: the request is accepted'
}

@test "uimpl: scn: Gate trigger conditions: fix + marker in What section triggers" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # | type | location                                      | outcome          |
    # | fix  | as a standalone line in the What section      | triggers         |
    # Given change.md frontmatter has type <type>
    # type = fix
    # And the unlocalized fault marker `? <-- fault: not yet localized` appears <location>
    # location = as a standalone line in the What section
    _write_change_md fix "$(_what_with_marker)"

    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]

    # Then the fault localization gate <outcome>
    # outcome = triggers
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]

    # Also covers scn: Gated invocation emits no planning content
    # | flag          |
    # | without flags |
    # Then AI Agent does not create a `## How` section
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]
    [[ "$output" != *'@artdef_change_how'* ]]
    # And AI Agent does not create any planning section
    [[ "$output" != *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
}

@test "uimpl: scn: Gate trigger conditions: negatives do not trigger" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # | type | location                                      | outcome          |
    # | fix  | embedded in a prose line in the What section  | does not trigger |
    # Given change.md frontmatter has type <type>
    # type = fix
    # And the unlocalized fault marker `? <-- fault: not yet localized` appears <location>
    # location = embedded in a prose line in the What section
    _write_change_md fix \
        '## What' \
        '' \
        'The marker ? <-- fault: not yet localized appears in prose only.'
    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    # Then the fault localization gate <outcome>
    # outcome = does not trigger
    [[ "$output" != *'<instruction id="instr_uimpl_fault"'* ]]
    # Normal cascade proceeds (`## How` is missing -> How prompt)
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]

    # | type | location                                      | outcome          |
    # | fix  | as a standalone line outside the What section | does not trigger |
    # Given change.md frontmatter has type <type>
    # type = fix
    # And the unlocalized fault marker `? <-- fault: not yet localized` appears <location>
    # location = as a standalone line outside the What section
    _write_change_md fix \
        '## What' \
        '' \
        'Symptom: prose only, no flowchart here.' \
        '' \
        '## Notes' \
        '' \
        "$FAULT_MARKER_STEP"
    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    # Then the fault localization gate <outcome>
    # outcome = does not trigger
    [[ "$output" != *'<instruction id="instr_uimpl_fault"'* ]]
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]

    # | type | location                                      | outcome          |
    # | feat | as a standalone line in the What section      | does not trigger |
    # Given change.md frontmatter has type <type>
    # type = feat
    # And the unlocalized fault marker `? <-- fault: not yet localized` appears <location>
    # location = as a standalone line in the What section
    _write_change_md feat "$(_what_with_marker)"
    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    # Then the fault localization gate <outcome>
    # outcome = does not trigger
    [[ "$output" != *'<instruction id="instr_uimpl_fault"'* ]]
    [[ "$output" == *'<instruction id="instr_uimpl_how"'* ]]
}

@test "uimpl: scn: Gated invocation emits no planning content: with --plan" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Given the fault localization gate triggers
    _write_change_md fix "$(_what_with_marker)"

    # | flag          |
    # | with `--plan` |
    # When Engineer invokes uimpl action <flag>
    # flag = with `--plan`
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change" --plan
    [ "$status" -eq 0 ]
    # --plan does not bypass the gate
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]

    # Then AI Agent does not create a `## How` section
    [[ "$output" != *'<instruction id="instr_uimpl_how"'* ]]
    # And AI Agent does not create any planning section
    [[ "$output" != *'<instruction id="instr_uimpl"'* ]]
    [[ "$output" != *"- Domain specifications section"* ]]
    [[ "$output" != *"- Construction and Quick start sections"* ]]
}

@test "uimpl: scn: Gated instructions direct fault localization" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Given the fault localization gate triggers
    _write_change_md fix "$(_what_with_marker)"

    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]

    # Then AI Agent is instructed to localize the fault
    [[ "$output" == *"localize the fault"* ]]
    # And AI Agent is instructed to track localization efforts in fault.md in the Change Folder
    [[ "$output" == *"fault.md"* ]]
    [[ "$output" == *"uspecs/changes/2601010000-my-change"* ]]
}

@test "uimpl: scn: Existing fault.md is continued, not restarted" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Given the fault localization gate triggers
    _write_change_md fix "$(_what_with_marker)"

    # And fault.md exists in the Change Folder
    echo '# Fault localization log' > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/fault.md"

    # When Engineer invokes uimpl action
    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]

    # Then AI Agent is instructed to read fault.md and build on the recorded efforts rather than restart the investigation
    [[ "$output" == *"build on the recorded efforts"* ]]

    # Absent fault.md omits the continue line (the unconditional fault.md
    # tracking instruction remains).
    rm "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/fault.md"

    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change"
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]
    [[ "$output" != *"build on the recorded efforts"* ]]
    [[ "$output" == *"fault.md"* ]]
}

@test "uimpl: scn: Successful localization: prompt renders re-invocation with original arguments" {
    cd "$PROJECT_ROOT"
    git checkout -q -b feature-branch
    _make_change_folder "2601010000-my-change"
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod"

    # Given the fault localization gate triggers
    _write_change_md fix "$(_what_with_marker)"

    uspecs action uimpl --change-folder "uspecs/changes/2601010000-my-change" --no-self-review
    [ "$status" -eq 0 ]
    [[ "$output" == *'<instruction id="instr_uimpl_fault"'* ]]

    # And AI Agent re-invokes uimpl with the original arguments
    # The re-invocation line uses the absolute softeng_sh path (rendered from
    # $_CTX_SCRIPT_DIR) and carries the original invocation arguments.
    [[ "$output" == *"\"$PROJECT_ROOT/bin/softeng.sh\" action uimpl --change-folder uspecs/changes/2601010000-my-change --no-self-review"* ]]
}
