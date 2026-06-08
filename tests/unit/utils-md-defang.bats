#!/usr/bin/env bats
set -Eeuo pipefail

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
    source "$REPO_ROOT/bin/_lib/utils.sh"
}

# ---------------------------------------------------------------------------
# md_defang_relative_link
# ---------------------------------------------------------------------------
# Per-row coverage of the `PR body link handling` Scenario Outline in
# uspecs/specs/prod/softeng/upr.feature. The matching integration test in
# tests/sys/softeng.sh-action-upr.bats only verifies the wiring of
# md_defang_relative_link into cmd_action_upr.
#
# shellcheck disable=SC2016
# Backticks inside single quotes are intentionally literal -- they are part
# of the asserted Markdown output produced by md_defang_relative_link.

@test "upr: scn: PR body link handling: all helper rows" {
    # | link_target                   | link_context           | rendered_link                                                                              |
    # | ../../../bin/softeng.sh       | regular paragraph      | `[text](/bin/softeng.sh)` (defanged: prefix stripped, `/` prepended, wrapped in backticks) |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = `[text](/bin/softeng.sh)` (defanged: prefix stripped, `/` prepended, wrapped in backticks)
    run -0 md_defang_relative_link <<< '[label](../../../bin/softeng.sh)'
    [ "$output" = '`[label](/bin/softeng.sh)`' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | ../../../../../bin/softeng.sh | regular paragraph      | `[text](/bin/softeng.sh)` (any depth of `../` is stripped)                                 |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = `[text](/bin/softeng.sh)` (any depth of `../` is stripped)
    run -0 md_defang_relative_link <<< '[label](../../../../../bin/softeng.sh)'
    [ "$output" = '`[label](/bin/softeng.sh)`' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | https://example.com/page      | regular paragraph      | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[site](https://example.com/page)'
    [ "$output" = '[site](https://example.com/page)' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | http://example.com/page       | regular paragraph      | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[site](http://example.com/page)'
    [ "$output" = '[site](http://example.com/page)' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | mailto:user@example.com       | regular paragraph      | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[mail](mailto:user@example.com)'
    [ "$output" = '[mail](mailto:user@example.com)' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | #section-anchor               | regular paragraph      | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[here](#section-anchor)'
    [ "$output" = '[here](#section-anchor)' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | /already/root-absolute.md     | regular paragraph      | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<< '[root](/already/root-absolute.md)'
    [ "$output" = '[root](/already/root-absolute.md)' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | ./sibling.md                  | regular paragraph      | `[text](./sibling.md)` (same-folder file link is wrapped in backticks)                     |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = `[text](./sibling.md)` (same-folder file link is wrapped in backticks)
    run -0 md_defang_relative_link <<< '[sib](./sibling.md)'
    [ "$output" = '`[sib](./sibling.md)`' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | decisions.md                  | regular paragraph      | `[text](decisions.md)` (same-folder file link is wrapped in backticks)                     |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = `[text](decisions.md)` (same-folder file link is wrapped in backticks)
    run -0 md_defang_relative_link <<< '[current clarification decisions](decisions.md)'
    [ "$output" = '`[current clarification decisions](decisions.md)`' ]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | ../../../bin/softeng.sh       | inside ``` fenced code | the link unchanged                                                                         |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = the link unchanged
    run -0 md_defang_relative_link <<EOF
\`\`\`
[label](../../../bin/softeng.sh)
\`\`\`
EOF
    [[ "$output" == *'[label](../../../bin/softeng.sh)'* ]]
    [[ "$output" != *'`[label]'* ]]

    # | link_target                   | link_context           | rendered_link                                                                              |
    # | ../../../../../etc/passwd     | regular paragraph      | `[text](/etc/passwd)` (escape-the-repo inputs are treated uniformly; the link is inert)    |
    # Then pr_body renders the link as <rendered_link>
    # rendered_link = `[text](/etc/passwd)` (escape-the-repo inputs are treated uniformly; the link is inert)
    run -0 md_defang_relative_link <<< '[pw](../../../../../etc/passwd)'
    [ "$output" = '`[pw](/etc/passwd)`' ]
}

# Supporting test (no matching .feature scenario): each link on a line is
# rewritten independently and links of mixed input classes coexist.
@test "defang: rewrites multiple links on the same line" {
    run -0 md_defang_relative_link <<< 'see [a](../../a.md) and [b](../b.md) also [c](https://x.example)'
    [ "$output" = 'see `[a](/a.md)` and `[b](/b.md)` also [c](https://x.example)' ]
}

# Supporting test (no matching .feature scenario): same-folder and parent links
# are rewritten independently when mixed on the same line.
@test "defang: rewrites mixed same-folder and parent links on the same line" {
    run -0 md_defang_relative_link <<< 'see [a](../../a.md), [b](decisions.md), and [c](./c.md)'
    [ "$output" = 'see `[a](/a.md)`, `[b](decisions.md)`, and `[c](./c.md)`' ]
}

# Supporting test (no matching .feature scenario): non-link content
# surrounding a rewritten link is preserved character-for-character.
@test "defang: preserves surrounding text and non-link content" {
    run -0 md_defang_relative_link <<< 'prefix [label](../../../bin/softeng.sh) suffix'
    [ "$output" = 'prefix `[label](/bin/softeng.sh)` suffix' ]
}

# Supporting test (no matching .feature scenario): fence tracking is
# symmetric -- rewriting resumes after a fence closes.
@test "defang: rewrites only outside fences but processes lines after fence closes" {
    run -0 md_defang_relative_link <<EOF
before [a](../../a.md)
\`\`\`
[b](../../b.md)
\`\`\`
after [c](../../c.md)
EOF
    [[ "$output" == *'before `[a](/a.md)`'* ]]
    [[ "$output" == *'[b](../../b.md)'* ]]
    [[ "$output" != *'`[b]'* ]]
    [[ "$output" == *'after `[c](/c.md)`'* ]]
}
