# Worklog

## 2026-05-02 17:37 e2e tests for `deliver --local`

### Scope

Cover the `--local` execution path end-to-end with real `git`, real `python3`, real `deliver.sh`, and the real `gen-uspecs-market.py`. No network, no `gh`, no stubs.

### Files to add

- `tests/e2e/helpers.bash` - shared setup/teardown for e2e (mirrors style of `tests/sys/helpers.bash`).
- `tests/e2e/deliver.bats` - test cases covering `--local` and `--release` paths.

No production code changes.

### Fixture strategy

Use the actual repository as the `--uspecs-repo` input (read-only). Only the marketplace repo is a temp directory.

Rationale:

- `gen-uspecs-market.py` needs a real uspecs source tree (templates, skills, plugins). Building a synthetic fixture is high-maintenance and would drift from reality.
- The script never writes to `--uspecs-repo`; only reads.
- Faster and stays in sync with template changes.

Trade-off accepted: tests depend on the current repo content. If template changes break generation, e2e catches it - which is desirable.

### Per-test setup (in `helpers.bash`)

- Resolve `REPO_ROOT` from `BATS_TEST_DIRNAME`.
- Create `MKT_REPO="$BATS_TEST_TMPDIR/marketplace"`, `git init -q`, initial empty commit (so HEAD exists, count = 1).
- Create a bare origin repo for the marketplace so `git push` works in the skip-guardrail tests: `git init -q --bare "$BATS_TEST_TMPDIR/mkt-origin.git"`; add it as `origin` remote and set upstream branch for `main`.
- Set `USPECS_REPO="$REPO_ROOT"` (the real repo).
- Helper function `deliver()` wrapping `run --separate-stderr bash "$REPO_ROOT/scripts/deliver.sh" "$@"`.

Windows note: convert `$BATS_TEST_TMPDIR` via `cygpath -m` on `msys*|cygwin*`, same as existing `tests/sys/helpers.bash`.

### Test cases

Case 1: `--local` default (dev) build, per agent

For each agent in `claude`, `augment`, `codex`:

- Run `deliver.sh --agent <a> --uspecs-repo <REPO_ROOT> --marketplace-repo <MKT_REPO> --local`.
- Assert:
  - `$status -eq 0`
  - `$output` contains `Generated <a> (--local: no commit, no push)`
  - `$output` contains `Done:` line
  - `$MKT_REPO/uspecs/.claude-plugin/plugin.json` exists
  - `plugin.json` `version` matches regex `^[0-9]+\.[0-9]+\.[0-9]+-dev\+[0-9]{8}-[0-9]{4}\.[0-9a-f]{12}$`
  - `git -C $MKT_REPO rev-list --count HEAD` is unchanged (still 1) - no commit
  - `git -C $MKT_REPO status --porcelain` is **non-empty** - generated files are present but not staged/committed (proves "generate only")

Case 2: `--release --local` per agent

For each agent:

- Run `deliver.sh --agent <a> --uspecs-repo <REPO_ROOT> --marketplace-repo <MKT_REPO> --release --local`.
- Assert:
  - `$status -eq 0`
  - `plugin.json` `version` equals contents of `version.txt` core (e.g. `0.1.2`), no `-dev`, no `+build`
  - No commit on marketplace repo
  - `Done: <CORE>` line present

Case 3: `--release --local` bypasses skip guardrail

- Pre-populate `MKT_REPO` with a `plugin.json` whose `version` matches `version.txt` core, commit it (clean repo).
- Run `deliver.sh --agent claude ... --release --local`.
- Assert:
  - `$status -eq 0`
  - Output does **not** contain `Skipping`
  - Output contains `Generated claude (--local: no commit, no push)`
  - This validates the documented invariant: "Always regenerates (no skip guardrail)".

Case 4: argument validation (cheap, fast)

- Missing `--agent`: exit 2, stderr contains `--agent is required`.
- Invalid agent: exit 2, stderr contains `must be one of claude|augment|codex`.
- Unknown flag with `--local`: exit 2.

(These are technically unit/sys-level, but bundling them keeps one file authoritative for `deliver.sh`. Could also live in `tests/sys/` if preferred.)

Case 5: `--release` skips when version matches and repo is clean

- Run `deliver.sh --agent claude --uspecs-repo <REPO_ROOT> --marketplace-repo <MKT_REPO> --release` (no `--local`; commits and pushes to the bare origin).
- Assert first run succeeds, `$status -eq 0`, `plugin.json` exists.
- Run the **same command again** (same version, clean repo).
- Assert:
  - `$status -eq 0`
  - `$output` contains `Skipping claude: already at <CORE> and clean`
  - `$output` contains `Done: <CORE>`

Case 6: `--release` regenerates when version matches but repo is dirty

- Run `deliver.sh --agent claude ... --release` once to generate, commit, push.
- Dirty the repo by adding `extra-file.txt` (do not commit).
- Run the same command again (version matches but repo is dirty).
- Assert:
  - `$status -eq 0`
  - `$output` does **not** contain `Skipping`
  - `$output` contains `Generating claude marketplace`
  - This validates the guardrail: dirty repo forces regeneration even on version match.

### Assertion helpers

Small helpers to keep tests readable:

```bash
_plugin_version() {
  python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" \
    "$MKT_REPO/uspecs/.claude-plugin/plugin.json"
}

_assert_no_commits_added() {
  [ "$(git -C "$MKT_REPO" rev-list --count HEAD)" -eq 1 ]
}
```

### Running

Per the existing convention:

```text
python tests/run-tests.py tests/e2e
python tests/run-tests.py tests/e2e "deliver"
```

`tests/run-tests.py` already recursively discovers `*.bats`, so the new folder works without runner changes.

### CI integration (out of scope, ask before doing)

Currently `.github/workflows/cd.yml` runs `deliver.sh` directly. A separate CI job could run `python tests/run-tests.py tests/e2e` on PRs - but that is a follow-up decision for the user.

### Risks and mitigations

- Template changes break tests -> intended; surface failures early.
- Slow generation (3 agents x 2 modes = 6 full generations) -> acceptable; bats runs in parallel via `run-tests.py`. If too slow, reduce matrix to one representative agent for non-`--release` cases.
- Windows path issues with `python3` and `git` -> use the same `cygpath -m` pattern as `tests/sys/helpers.bash`.
- Non-deterministic dev version timestamp -> regex assertion, not exact match.

### Production fix

- [x] update: `scripts/deliver.sh`
  - Convert `GEN_SCRIPT` path with `cygpath -m` on `msys*|cygwin*` before passing to Windows Python

### Deliverables checklist

- [x] `tests/e2e/helpers.bash`
- [x] `tests/e2e/deliver.bats` with cases 1-6
- [x] Verify locally: `python tests/run-tests.py tests/e2e`
- [x] Production fix: `scripts/deliver.sh` Windows path fix documented
