# Decisions

## Uncertainty: how should `gen-uspecs-market.py` find and replace the `USPECS_VERSION` line in the copied `softeng.sh`

Decision: Regex on line prefix

- Pros: robust if the sentinel value is ever changed later; replaces exactly one line; idiomatic Python (no subprocess); matches the in-process style already used by `render_marketplace`/`render_plugin_json`
- Cons: slightly more code than a literal string replace; a stray `USPECS_VERSION=...` written elsewhere in `softeng.sh` would also match (mitigated by `count=1` and the convention to declare it once at the top)
- Confidence: high

Alternatives:

1. Literal line replace
   - Pros: simplest possible implementation; mirrors the existing `result.replace("{{version}}", version)` pattern in the same file; impossible to mis-match
   - Cons: silently breaks if the sentinel literal in `softeng.sh` ever drifts; no warning, plugin ships with the unsubstituted source value
   - Confidence: medium
2. Tokenized sentinel comment
   - Pros: matches the existing `{{version}}` placeholder convention used for `marketplace.json`/`plugin.json`/`README.md`
   - Cons: doesn't actually update the bash value, only the comment; would require both a comment-token and a separate value swap, which is more complex
   - Confidence: low

## Uncertainty: what should the `AGENT_INSTRUCTIONS` prompt template for `uversion` instruct the agent to do

Decision: Minimal directive

- Pros: matches the conversational style of other prompts (e.g. `instr_umergepr_no_pr.md`, `instr_uimpl_review_pending.md` which use natural language); the user gets a clear, labeled output
- Cons: exact wording the agent produces is non-deterministic, so output is not pipe-friendly
- Confidence: high

Alternatives:

1. Bare version
   - Pros: deterministic, scriptable output; matches the literal phrasing of the original request
   - Cons: AI agents tend to add a sentence around bare strings anyway, so determinism is not guaranteed; no framing means user has to know what they're looking at
   - Confidence: medium
2. With provenance
   - Pros: useful for debugging which marketplace build is installed
   - Cons: out of scope for this change; that data isn't currently baked into `softeng.sh`; would require additional sentinels and generator substitutions
   - Confidence: low
