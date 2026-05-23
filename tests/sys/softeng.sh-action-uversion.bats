#!/usr/bin/env bats
set -Eeuo pipefail

load 'helpers'

_set_softeng_constant() {
    local name="$1"
    local value="$2"
    python3 - "$PROJECT_ROOT/bin/_lib/meta.sh" "$name" "$value" <<'PY'
import re
import sys

path, name, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    text = f.read()
escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")
text, count = re.subn(rf'^{re.escape(name)}=.*$', f'{name}="{escaped}"', text, count=1, flags=re.MULTILINE)
if count != 1:
    raise SystemExit(f"{name} replacement failed")
with open(path, "w", encoding="utf-8", newline="") as f:
    f.write(text)
PY
}

_configure_uversion_constants() {
    local version="$1"
    local stream="$2"
    local marketplace_repo="$3"
    local marketplace_name="$4"
    local cli="$5"
    local marketplace_update_verb="$6"

    _set_softeng_constant "USPECS_VERSION" "$version"
    _set_softeng_constant "USPECS_MARKETPLACE_REPO" "$marketplace_repo"
    _set_softeng_constant "USPECS_MARKETPLACE_NAME" "$marketplace_name"
    _set_softeng_constant "USPECS_STREAM" "$stream"
    _set_softeng_constant "USPECS_CLI" "$cli"
    _set_softeng_constant "USPECS_MARKETPLACE_UPDATE_VERB" "$marketplace_update_verb"
}

_stub_marketplace_manifest() {
    local latest_version="$1"
    local stub_dir="$BATS_TEST_TMPDIR/uversion-stubs"
    mkdir -p "$stub_dir"
    cat > "$stub_dir/curl" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${USPECS_TEST_CURL_FAIL:-}" == "1" ]]; then
    echo "network unavailable" >&2
    exit 22
fi
cat <<JSON
{
  "metadata": {
    "version": "${USPECS_TEST_LATEST_VERSION}"
  }
}
JSON
SH
    chmod +x "$stub_dir/curl"
    export PATH="$stub_dir:$PATH"
    export USPECS_TEST_LATEST_VERSION="$latest_version"
    unset USPECS_TEST_CURL_FAIL
}

@test "uversion: scn: Display version: source repo emits sentinel" {
    cd "$PROJECT_ROOT"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"<LOG>"* ]]
    [[ "$output" == *"</LOG>"* ]]
    [[ "$output" == *"Action: uversion"* ]]
    [[ "$output" == *"<AGENT_INSTRUCTIONS>"* ]]
    [[ "$output" == *'<instruction id="instr_uversion"'* ]]
    [[ "$output" == *"0.0.0-source"* ]]
    [[ "$output" == *"Display update availability: skipped"* ]]
    [[ "$output" == *"local source build"* ]]
}

@test "uversion: stable marketplace build is up to date" {
    cd "$PROJECT_ROOT"
    _configure_uversion_constants \
        "2.3.0" \
        "stable" \
        "uspecs/uspecs-plugins-codex" \
        "uspecs-plugins-codex" \
        "codex" \
        "upgrade"
    _stub_marketplace_manifest "2.3.0"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"Display the uspecs framework plugin version to the user: 2.3.0"* ]]
    [[ "$output" == *"Display update availability: up to date"* ]]
    [[ "$output" != *"codex plugin marketplace upgrade"* ]]
    [[ "$output" != *"codex plugin add uspecs@uspecs-plugins-codex"* ]]
    [[ "$output" == *"Do not install the uspecs plugin."* ]]
}

@test "uversion: stable marketplace build reports newer version with update instructions" {
    cd "$PROJECT_ROOT"
    _configure_uversion_constants \
        "2.3.0" \
        "stable" \
        "uspecs/uspecs-plugins-codex" \
        "uspecs-plugins-codex" \
        "codex" \
        "upgrade"
    _stub_marketplace_manifest "2.4.0"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"Display update availability: newer version 2.4.0 available"* ]]
    [[ "$output" == *"Display latest available version: 2.4.0"* ]]
    [[ "$output" == *"codex plugin marketplace upgrade uspecs-plugins-codex"* ]]
    [[ "$output" != *"codex plugin add uspecs@uspecs-plugins-codex"* ]]
    [[ "$output" == *"Do not install the uspecs plugin."* ]]
    [[ "$output" == *"Do not execute the update command."* ]]
    [[ "$output" == *"Do not require a separate version-check command."* ]]
}

@test "uversion: development marketplace build reports newer version with update instructions" {
    cd "$PROJECT_ROOT"
    _configure_uversion_constants \
        "2.3.0-dev+20260504-1519.8da604592d28" \
        "development" \
        "uspecs/uspecs-dev-plugins-augment" \
        "uspecs-dev-plugins-augment" \
        "auggie" \
        "update"
    _stub_marketplace_manifest "2.3.0-dev+20260505-0901.f3a4189b21c0"

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"Display update availability: newer version 2.3.0-dev+20260505-0901.f3a4189b21c0 available"* ]]
    [[ "$output" == *"auggie plugin marketplace update uspecs-dev-plugins-augment"* ]]
    [[ "$output" != *"auggie plugin install uspecs-dev@uspecs-dev-plugins-augment"* ]]
}

@test "uversion: unavailable marketplace fetch reports unknown availability" {
    cd "$PROJECT_ROOT"
    _configure_uversion_constants \
        "2.3.0" \
        "stable" \
        "uspecs/uspecs-plugins-codex" \
        "uspecs-plugins-codex" \
        "codex" \
        "upgrade"
    _stub_marketplace_manifest "2.4.0"
    export USPECS_TEST_CURL_FAIL=1

    uspecs action uversion
    [ "$status" -eq 0 ]
    [[ "$output" == *"Display the uspecs framework plugin version to the user: 2.3.0"* ]]
    [[ "$output" == *"Display update availability: unknown"* ]]
    [[ "$output" == *"failed to fetch marketplace manifest"* ]]
    [[ "$output" != *"codex plugin add uspecs@uspecs-plugins-codex"* ]]
}

@test "uversion: rejects unknown arguments" {
    cd "$PROJECT_ROOT"

    uspecs action uversion --bogus
    [ "$status" -ne 0 ]
    [[ "${stderr:-}" == *"Unknown argument"* ]]
}
