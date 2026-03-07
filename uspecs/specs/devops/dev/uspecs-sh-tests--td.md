# Feature technical design: uspecs.sh tests

## Key components

Feature components:

- [helpers.bash: shared bats helpers](../../../../tests/helpers.bash)
  - Loaded by all system test files via `load 'helpers'`
  - Contains `setup()`, `uspecs()` helper, and `_make_change_folder()` helper

- System test files (one per command, gh CLI stubbed, real git via local bare repos):
  - [uspecs.sh.bats](../../../../tests/uspecs.sh.bats) - general (unknown command)
  - [uspecs.sh-change-new.bats](../../../../tests/uspecs.sh-change-new.bats) - `change new`
  - [uspecs.sh-change-archive.bats](../../../../tests/uspecs.sh-change-archive.bats) - `change archive`
  - [uspecs.sh-pr-preflight.bats](../../../../tests/uspecs.sh-pr-preflight.bats) - `pr preflight`
  - [uspecs.sh-pr-create.bats](../../../../tests/uspecs.sh-pr-create.bats) - `pr create`
  - [uspecs.sh-diff.bats](../../../../tests/uspecs.sh-diff.bats) - `diff specs`
  - ...

- [uspecs.sh-e2e.bats: bats test file](../../../../tests/e2e/uspecs.sh-e2e.bats)
  - E2e tests for uspecs.sh: black-box, real gh CLI, real GitHub repo (future scope)
  - File exists with header comment only; no test cases implemented yet

- [gh: bash stub script](../../../../tests/stubs/gh)
  - Placed on PATH during system tests; records args to gh.calls and stdin to gh.body, prints a fake PR URL and exits 0

📦 System components:

- [uspecs.sh: bash script](../../../u/scripts/uspecs.sh)
  - Script under test; invoked as a black box via `run bash uspecs/u/scripts/uspecs.sh ...`
  - Used by: uspecs.sh.bats, uspecs.sh-e2e.bats

- [pr.sh: bash script](../../../u/scripts/_lib/pr.sh)
  - Called by uspecs.sh for PR creation and remote management
  - Used by: uspecs.sh.bats, uspecs.sh-e2e.bats

⚙️ External systems:

- [gh CLI: GitHub CLI](https://cli.github.com)
  - Stubbed in system tests; real in e2e tests
  - Used by: uspecs.sh-e2e.bats (real), uspecs.sh.bats (stub)

## Key flows

### System test execution

```text
Developer -> bats tests/uspecs.sh.bats
               |
               v
           setup()
               +-- create $BATS_TEST_TMPDIR as isolated project root
               +-- init local git repo, create initial commit
               +-- init local bare repo as "origin" remote
               +-- copy conf.md into temp project structure
               +-- prepend tests/stubs/ dir to PATH (gh stub)
               |
               v
           @test block
               +-- run bash uspecs/u/scripts/uspecs.sh <command> [args]
               +-- assert $status and $output
               |
               v
           teardown()
               +-- $BATS_TEST_TMPDIR removed automatically by bats
```

### Developer commands

- System tests: `bats tests/uspecs.sh*.bats` (runs all per-command `.bats` files)
- E2e tests: `bats tests/e2e/uspecs.sh-e2e.bats` (requires `USPECS_GH_TOKEN`)

## Scenario implementation

### Developer runs system tests

Command: `bats tests/uspecs.sh*.bats` (runs all per-command `.bats` files)

`setup()` runs before each test:

- Converts `BATS_TEST_TMPDIR` to a Windows-compatible path via `cygpath -m` on MSYS/Cygwin,
  so bash and Git for Windows resolve the same physical directory
- Creates an isolated project root under the converted temp dir
- Copies `uspecs/u/` into it so `uspecs.sh` resolves `get_project_dir()` to the temp root
- Initialises a local git repo with `main` as the default branch and an initial commit
- Initialises a local bare repo as the `origin` remote and pushes `main` to it
- Prepends `tests/stubs/` to `PATH` so the `gh` stub intercepts all `gh` calls

Each `@test` block:

- Invokes `uspecs.sh` via the `uspecs` helper: `run bash ... uspecs.sh <command> [args] 2>&1`
- Merging stderr into stdout ensures both normal output and error messages are in `$output`
- Asserts `$status` (exit code) and `$output` (combined stdout+stderr)

`gh` stub (`tests/stubs/gh`):

- Appends CLI args to `$BATS_TEST_TMPDIR/gh.calls`
- Appends stdin to `$BATS_TEST_TMPDIR/gh.body`
- Prints a fixed fake PR URL (`https://github.com/org/repo/pull/42`) and exits 0

bats removes `BATS_TEST_TMPDIR` automatically after each test.

### Developer runs e2e tests

Not yet implemented. `tests/e2e/uspecs.sh-e2e.bats` exists with a header comment only.

When implemented:

- Same black-box invocation of `uspecs.sh` as system tests
- Uses the real `gh` CLI against a dedicated GitHub test repo
- Requires `USPECS_GH_TOKEN` and test repo configuration to be set in the environment
