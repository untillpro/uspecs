# Implementation plan: Pass PR body via --body parameter instead of stdin

## Construction

- [x] update: [actn-upr.md](../../../../u/actn-upr.md)
  - update: Replace stdin piping instruction with `--body` CLI parameter
  - update: Add newline encoding note and shell-special characters note
- [x] update: [scripts/_lib/pr.sh](../../../../u/scripts/_lib/pr.sh)
  - update: Decode literal `\n` sequences to actual newlines in `cmd_changepr` and `cmd_pr`
  - update: Add doc comments for `\n` decoding in `changepr` and `pr` commands
- [x] update: [scripts/uspecs.sh](../../../../u/scripts/uspecs.sh)
  - update: Add doc comment noting `\n` decoding for `pr create`
- [x] update: [tests/sys/uspecs.sh-pr-create.bats](../../../../../../tests/sys/uspecs.sh-pr-create.bats)
  - add: Test that `\n` sequences in `--body` are decoded to actual newlines
