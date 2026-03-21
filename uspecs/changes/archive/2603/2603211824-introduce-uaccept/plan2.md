<!-- markdownlint-disable -->

## Final Implementation Plan: Enhanced upr error messages

### Implementation changes needed:

#### 1. Add prompt section to `prompts.md`

**Add new section:**
```markdown
## upr_uncompleted_todos: Change folder has uncompleted todo items

Cannot create PR: ${uncompleted_count} uncompleted todo item(s) found in files:

${uncompleted_files}

Complete todo items before creating a PR.
```

**Variables needed:**

- `uncompleted_count`: number of uncompleted items
- `uncompleted_files`: list of files with uncompleted items, relative to project root paths

---

#### 2. Update `cmd_prompt_upr` in `uspecs.sh` (lines 759-764)

**Current code:**
```bash
# Check for uncompleted todo items
local uncompleted_count
uncompleted_count=$(count_uncompleted_items "$wcf_path")
if [[ "$uncompleted_count" -gt 0 ]]; then
    error "Change folder has $uncompleted_count uncompleted todo item(s). Complete or cancel them before creating a PR."
fi
```

**Replace with:**
```bash
# Check for uncompleted todo items
local uncompleted_count
uncompleted_count=$(count_uncompleted_items "$wcf_path")
if [[ "$uncompleted_count" -gt 0 ]]; then
    local uncompleted_files
    uncompleted_files=$(grep -rl "^[[:space:]]*-[[:space:]]*\[ \]" "$wcf_path"/*.md 2>/dev/null | sed 's|^'"$PROJECT_ROOT"'/||')
    
    local prompts_file
    prompts_file="$(get_script_dir)/prompts.md"
    
    # shellcheck disable=SC2034  # vars used via nameref
    declare -A uncompleted_vars=(
        [uncompleted_count]="$uncompleted_count"
        [uncompleted_files]="$uncompleted_files"
    )
    section_templ "$prompts_file" "upr_uncompleted_todos" uncompleted_vars
    exit 1
fi
```

**Pattern:** Follow how `pr preflight` displays detailed uncompleted items (lines 335-340), but use `section_templ` instead of plain echo

---

#### 3. Update test in `uspecs.sh-prompt-upr.bats`

**Test 0: No Working Change Folder test (lines 195-206) - Already exists ✅**
- Already verifies error message contains "No Working Change Folder"
- No changes needed - matches spec requirement for generic message

**Test 1: Update existing uncompleted todos test (lines 208-229)**

**Current test:**
- Only checks for generic "uncompleted todo item" in stderr
- Only has uncompleted item in `change.md`

**Update to:**
- Create uncompleted items in **multiple files** (both `change.md` and `impl.md`)
- Assert output contains:
  - File names: `change.md` and `impl.md`
  - Line numbers or actual uncompleted item text
  - Prompt to complete or cancel them

**Example:**
```bash
@test "prompt upr: edge - change folder has uncompleted todo items" {
    cd "$PROJECT_ROOT"
    git checkout -q -b todo-feature
    local folder_name="2601010000-with-todos"
    mkdir -p "$PROJECT_ROOT/uspecs/changes/$folder_name"
    
    # Create change.md with uncompleted item
    {
        echo '---'
        echo "registered_at: 2026-01-01T00:00:00Z"
        echo "change_id: $folder_name"
        echo '---'
        echo ''
        echo '# Change request: Has todos'
        echo ''
        echo '- [ ] uncompleted task in change'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/change.md"
    
    # Create impl.md with uncompleted item
    {
        echo '# Implementation plan'
        echo ''
        echo '- [ ] uncompleted task in impl'
    } > "$PROJECT_ROOT/uspecs/changes/$folder_name/impl.md"
    
    git add .
    git commit -q -m "add folder with todos"

    uspecs prompt upr
    [ "$status" -ne 0 ]
    
    # Verify detailed error message
    [[ "$output" == *"uncompleted todo item"* ]]
    [[ "$output" == *"change.md"* ]]
    [[ "$output" == *"impl.md"* ]]
    [[ "$output" == *"Complete or cancel"* ]]
}
```

---

**Test 2: Add new test for Multiple Working Change Folders (NEW)**

**Add after line 206:**
```bash
@test "prompt upr: edge - Multiple Working Change Folders exist" {
    cd "$PROJECT_ROOT"
    git checkout -q -b multi-wcf-branch
    
    # Create two change folders
    _make_upr_change "2601010000-first-change" "First change"
    _make_upr_change "2601010000-second-change" "Second change"
    
    uspecs prompt upr
    [ "$status" -ne 0 ]
    
    # Verify error lists both folders
    [[ "${stderr:-}" == *"Multiple Working Change Folders"* ]]
    [[ "${stderr:-}" == *"2601010000-first-change"* ]]
    [[ "${stderr:-}" == *"2601010000-second-change"* ]]
}
```
