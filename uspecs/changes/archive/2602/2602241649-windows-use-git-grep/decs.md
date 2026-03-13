# Decisions: On Windows use grep from git install

## Windows detection

Use `$OSTYPE` variable to detect Windows (confidence: high).

Rationale: `$OSTYPE` is set by bash itself - `msys` for Git Bash and `cygwin` for Cygwin. No external command is needed. This approach is already used in `conf.sh` (`case "$OSTYPE" in msys*|cygwin*)`), keeping it consistent.[^1]

Alternatives:

- `uname -s` and check for `MINGW`/`MSYS`/`CYGWIN` prefix (confidence: medium)
  - Requires subprocess; less portable across non-bash shells
- Check `$OS` environment variable for `Windows_NT` (confidence: low)
  - `$OS` is a Windows env var, not guaranteed in all bash environments

## Locating git's bundled grep

Derive grep path from `git` executable location (confidence: high).

Rationale: `command -v git` returns the git binary path (e.g. `/c/Program Files/Git/cmd/git.exe` in MSYS path format). Git for Windows stores its usr/bin tools at `../usr/bin/` relative to `cmd/`. This is reliable without hardcoding drive or install prefix.[^2]

```text
git_path=$(command -v git)            # e.g. /c/Program Files/Git/cmd/git.exe
git_root=$(dirname "$(dirname "$git_path")")  # -> .../Git
git_grep="$git_root/usr/bin/grep"
```

Alternatives:

- Hardcode `C:/Program Files/Git/usr/bin/grep` (confidence: low)
  - Breaks for non-default install locations
- Use `git --exec-path` to derive root (confidence: low)
  - Points to `libexec/git-core`, not `usr/bin`; more fragile navigation

## Where to apply the fix

Add an `_grep` wrapper function to `utils.sh` that lazily resolves the correct grep binary on first call and caches it in a module-level variable (confidence: high).

Rationale: All three scripts (`uspecs.sh`, `pr.sh`, `conf.sh`) source `utils.sh`, so one function covers all call sites. A wrapper function is cleaner than a `$GREP` variable -- call sites read as `_grep -E ...` instead of `"$GREP" -E ...`, and there is no risk of the variable being unset. All existing grep calls are inline pipelines within the same shell process, so no `export -f` is needed.

```text
_GREP_BIN=""
_grep() {
    if [[ -z "$_GREP_BIN" ]]; then
        case "$OSTYPE" in
            msys*|cygwin*)
                local git_path git_root candidate
                git_path=$(command -v git 2>/dev/null)
                if [[ -n "$git_path" ]]; then
                    git_root=$(dirname "$(dirname "$git_path")")
                    candidate="$git_root/usr/bin/grep"
                    [[ -x "$candidate" ]] && _GREP_BIN="$candidate"
                fi
                ;;
        esac
        [[ -z "$_GREP_BIN" ]] && _GREP_BIN="grep"
    fi
    "$_GREP_BIN" "$@"
}
```

Alternatives:

- Store resolved path in a `$GREP` variable, use `"$GREP"` at call sites (confidence: medium)
  - More explicit but noisier call sites; variable can be accidentally unset
- Prepend git's `usr/bin` to `$PATH` at script start (confidence: medium)
  - No call-site changes needed, but mutates PATH globally and may affect other tool resolution
- Shadow the `grep` name with a shell function (confidence: low)
  - Confusing; may interfere with tab completion and external tooling

## Fallback when git's grep is not found

Fail fast with an error on Windows if git's bundled grep is not found (confidence: high).

Rationale: Git is a hard dependency of these scripts; if git is installed, its `usr/bin/grep` will always be present. Falling back to system grep would silently reintroduce the broken behavior we are trying to fix -- for example, `count_uncompleted_items` uses `\s` in BRE and would return 0 on a broken grep, allowing archive to proceed incorrectly. A clear error message is better than a silent wrong result.

Alternatives:

- Fall back to system grep with a warning (confidence: low)
  - Defeats the purpose: broken system grep causes silent wrong results, not obvious errors
- Silently fall back to system grep (confidence: low)
  - Makes failures invisible and hard to diagnose

## Scope of fix -- grep only vs sed as well

Fix grep only (confidence: high).

Rationale: The issue report specifically mentions grep. The `sed_inplace` function in `utils.sh` uses `-i.bak` for BSD compatibility, which works correctly with Git for Windows's sed. No sed incompatibilities have been reported. Expanding scope is premature.

Alternatives:

- Also resolve `sed` from git's `usr/bin` (confidence: low)
  - No evidence of sed failures; adds unnecessary complexity

[^1]: Stack Overflow (2008). *How to detect the OS from a Bash script?* [Stack Overflow](https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script)
[^2]: Stack Overflow / Super User. *Git for Windows usr/bin location.* [Stack Overflow](https://stackoverflow.com/questions/2499331/git-with-ssh-on-windows)
