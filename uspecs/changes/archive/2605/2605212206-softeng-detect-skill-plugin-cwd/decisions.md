# Decisions

## Uncertainty: scope of the cwd guard — gate all invocations or only project-context actions

Decision: Guard all invocations uniformly

- Pros: simplest implementation; matches the issue's literal wording ("running `bin/softeng.sh` from a skill/plugin root fails"); no per-command carve-outs to maintain; tests are trivial (one fixture per marker type)
- Cons: breaks the natural "cd into the installed plugin and run `softeng action uversion` to check which version is installed" workflow; same for `meta options`
- Confidence: high

Alternatives:

1. Guard only the project-context actions (apply the check inside the handlers that actually need a project, i.e. uchange/uimpl/uarchive/upr/umergepr/usync/change/diff/self-review; leave `action uversion` and `meta options` unguarded)
   - Pros: preserves the read-only introspection workflow inside an installed plugin; aligns the guard with the actual failure mode (only project-context commands misbehave in a plugin tree)
   - Cons: more code paths to keep in sync; per-action wiring means a new action could forget to call the guard; slightly weakens the issue's "running `bin/softeng.sh` from a plugin root fails" wording (some invocations would still succeed)
   - Confidence: medium
2. Guard all invocations uniformly, but allow an opt-out env var (e.g. `USPECS_ALLOW_PLUGIN_CWD=1` bypasses the guard)
   - Pros: keeps the strong default the issue specifies while leaving a documented escape hatch for the legitimate "check the installed version from inside the plugin" use case and for tests
   - Cons: adds public surface (an env var contract); users who hit the guard may reach for the env var instead of fixing their cwd
   - Confidence: low
