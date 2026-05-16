#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

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
    # But it stops on Review Item if it is unchecked
    _uimpl_with_review_form '- [ ] Review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]
    [[ "$output" == *"Stop on the"* ]]
    [[ "$output" == *"review checkpoint"* ]]

    # scn: Some unchecked to-do items: with review item "- [ ] review" (lowercase)
    _uimpl_with_review_form '- [ ] review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Stop on the"* ]]

    # scn: Some unchecked to-do items: with review item "- Review" (no checkbox)
    _uimpl_with_review_form '- Review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Stop on the"* ]]

    # scn: Some unchecked to-do items: with review item "- review" (no checkbox, lowercase)
    _uimpl_with_review_form '- review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Stop on the"* ]]

    # scn: Some unchecked to-do items: checked review "- [x] Review" is NOT detected
    _uimpl_with_review_form '- [x] Review'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Complete to-do items"* ]]
    [[ "$output" != *"Stop on the"* ]]
    [[ "$output" != *"review checkpoint"* ]]

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
    [[ "$output" != *"Stop on the"* ]]
    [[ "$output" != *"review checkpoint"* ]]

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

    # Case 1: specs folder + at least one domain.md -> specs-derived scope branch
    mkdir -p "$PROJECT_ROOT/uspecs/specs/prod/softeng"
    echo '# domain' > "$PROJECT_ROOT/uspecs/specs/prod/domain.md"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` from the contexts listed under \`## Contexts\` in \`uspecs/specs/{domain}/domain.md\`"* ]]
    [[ "$output" != *"short free-form name from the code area"* ]]
    [[ "$output" == *"frontmatter \`breaking: true\`"* ]]

    # Case 2: specs folder exists but no domain.md anywhere -> free-form scope branch
    rm -f "$PROJECT_ROOT/uspecs/specs/prod/domain.md"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` as a short free-form name from the code area"* ]]
    [[ "$output" != *"contexts listed under \`## Contexts\`"* ]]
    [[ "$output" == *"frontmatter \`breaking: true\`"* ]]

    # Case 3: no specs folder at all -> free-form scope branch
    rm -rf "$PROJECT_ROOT/uspecs/specs"

    _uimpl_with_sections
    [ "$status" -eq 0 ]
    [[ "$output" == *"frontmatter \`scope:\` as a short free-form name from the code area"* ]]
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

@test "uimpl: review item is excluded from emitted unchecked items" {
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
        '- [ ] Review' \
        '- [ ] update: [beta.go](../../beta.go)' \
        '  - fix: beta detail' \
        > "$PROJECT_ROOT/uspecs/changes/2601010000-my-change/impl.md"

    uspecs action uimpl
    [ "$status" -eq 0 ]
    # Review path still triggers
    [[ "$output" == *"Stop on the"* ]]
    # Both non-review items are present in the output
    [[ "$output" == *'alpha.go'* ]]
    [[ "$output" == *'beta.go'* ]]
    # Review item must not appear inside the ${unchecked_items} block.
    # Extract the instr_uimpl_todos block and check it does not contain the
    # bare "- [ ] Review" line.
    local todos_block="${output#*<instruction id=\"instr_uimpl_todos\"}"
    todos_block="${todos_block%%</instruction>*}"
    [[ "$todos_block" != *$'\n- [ ] Review\n'* ]]
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
