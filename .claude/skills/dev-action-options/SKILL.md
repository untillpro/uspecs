---
name: dev-action-options
description: Use this skill to add, remove, rename, or modify softeng action options. Covers `ACTION_OPTIONS`, `cmd_action_*` parser arms, dispatch templates, option behavior specs, and tests -- either by direct agent edits or through the uspecs uchange to uimpl cycle.
---

Develop the softeng action-option subsystem: the user-facing options an action accepts, how the action parser handles them, and how agents learn to pass them.

## Subsystem map

Action options are **specified by the specs** and **implemented by construction artifacts**, which must conform. Touch only the ones a given change needs.

Source of truth (specs govern):

- Domain design -- [context.md](../../../uspecs/specs/prod/softeng/context.md)
  - `ActionInvocation.options` and any option-derived model fields or rules
- Functional design -- action feature files such as [uimpl.feature](../../../uspecs/specs/prod/softeng/uimpl.feature) and [uchange.feature](../../../uspecs/specs/prod/softeng/uchange.feature)
  - Canonical observable behavior for option parsing, defaults, validation, and workflow effects
- Architecture -- [arch.md](../../../uspecs/specs/prod/softeng/arch.md)
  - Cross-action flow and emission-pipeline behavior when an option changes how prompts or follow-up commands are emitted

Implementation (construction, conforms to the specs):

- [softeng.sh](../../../bin/softeng.sh)
  - `ACTION_OPTIONS` is the action option display surface printed by `softeng meta options <action>`
  - `cmd_action_<action>` parser arms are the accepted action flags
  - command handlers implement option-driven branching, prompt context, and validation
- [scripts/templates/actions/*.yaml](../../../scripts/templates/actions)
  - dispatch-time agent instructions for deriving action command arguments from user input
  - usually say only `Parse user input as [options]`; edit a template only when the agent must derive a specific option from non-option input
- [scripts/_lib/gen-uspecs-market.py](../../../scripts/_lib/gen-uspecs-market.py)
  - `read_action_options` invokes `softeng meta options <action>` and consumes the rendered `ACTION_OPTIONS` text for generated action instructions
- [tests/sys/parse-softeng-action-options.py](../../../tests/sys/parse-softeng-action-options.py)
  - extracts literal flags from `cmd_action_*` parser arms; it does not parse `ACTION_OPTIONS`
- [tests/sys/softeng.sh-meta-options.bats](../../../tests/sys/softeng.sh-meta-options.bats)
  - extracts flags from rendered `ACTION_OPTIONS` output and compares them with the parser-arm flags
- Per-action system tests, such as [softeng.sh-action-uimpl.bats](../../../tests/sys/softeng.sh-action-uimpl.bats)
  - verify observable option behavior

Key facts:

- `ACTION_OPTIONS` and `cmd_action_*` parser arms must stay in sync. If a user-facing action flag is accepted, it must be listed in `ACTION_OPTIONS`; if it is listed, the parser must accept it.
- Keep `ACTION_OPTIONS` text suitable for generated command and skill files: `softeng meta options <action>` prints it as `Options: ...`.
- `scripts/templates/actions/<action>.yaml` is not the normal option catalog. Do not add option lists there just to document parser flags; use `ACTION_OPTIONS` for that.
- Internal carried state in an action parser is risky: the meta-options test treats parser arms as public action options. Prefer documented options or a design that avoids hidden `cmd_action_*` flags; if hidden flags are truly required, update specs and tests deliberately.
- Top-level commands such as `self-review` are not `action` dispatches and are not represented in `ACTION_OPTIONS`.

## Two ways to apply a change

Choose either approach. Both require the same edits; the cycle wraps them in plan sections and review gates.

### Direct edits

When asked to change action options outright without a Change Request, edit the source artifacts in place following the Recipes below, then verify.

### Within the uspecs cycle

Follow the user's `uchange` then `uimpl` invocations. Make the Recipe edits below, placing each in the plan section that matches its artifact's layer: [uspecs-sec-domains](../uspecs-sec-domains/SKILL.md), [uspecs-sec-fd](../uspecs-sec-fd/SKILL.md), [uspecs-sec-td](../uspecs-sec-td/SKILL.md), or [uspecs-sec-constr](../uspecs-sec-constr/SKILL.md).

## Recipes

Artifacts are named in short form below; their paths and roles are in the Subsystem map above.

### Add a user-facing option to an existing action

1. Specs: update the action feature file for observable behavior. Update `context.md` if the option introduces a model field or cross-action rule. Update `arch.md` only for flow or prompt-emission changes.
2. `softeng.sh`: add the flag to both `ACTION_OPTIONS[<action>]` and the `cmd_action_<action>` parser.
3. `softeng.sh`: implement validation, defaults, prompt context, and branching.
4. `scripts/templates/actions/<action>.yaml`: edit only if the agent must derive this option from free-form user input.
5. Tests: run or update `softeng.sh-meta-options.bats` to prove `ACTION_OPTIONS` and parser arms match. Update its parser helper only if the shell parser shape changes. Add or update the per-action system tests.

### Modify, rename, or remove an option

Start at the specs, then update `ACTION_OPTIONS`, parser arms, behavior, and tests together. For renames, cover the old spelling's rejection or compatibility behavior explicitly.

### Add option-driven prompt or follow-up command behavior

1. Capture the observable behavior in the feature file and any flow change in `arch.md`.
2. Keep prompt-root selection in the command handler; prompt files should receive prepared context variables, not rediscover shell state.
3. Ensure rendered follow-up commands preserve options that must survive re-invocation.
4. Test both rendered prompt content and command behavior.

### Add a dispatch-time inference rule

Use this only when the agent should infer an option from natural-language input before `softeng.sh` runs, such as `uchange` inferring `--type` or `--issue-url`.

1. Update `scripts/templates/actions/<action>.yaml` with concise derivation instructions.
2. Keep `ACTION_OPTIONS` and parser arms aligned in `softeng.sh`.
3. Add template or system tests that prove the dispatch instruction changed.

## Verify

Do not run tests unless requested; when you do:

```bash
python3 tests/run-tests.py tests/sys softeng.sh-meta-options
python3 tests/run-tests.py tests/sys/softeng.sh-action-<action>.bats
```

Also confirm `softeng meta options <action>` lists exactly the user-facing flags accepted by `cmd_action_<action>`.
