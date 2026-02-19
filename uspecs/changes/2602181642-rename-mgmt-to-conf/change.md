---
registered_at: 2026-02-18T16:43:05Z
change_id: 2602181642-rename-mgmt-to-conf
baseline: 1987769ee1d49a594d182abedac9c559ae4091e1
---

# Change request: Rename mgmt to conf, invocation type to invocation method

## Why

`mgmt` is an ambiguous shorthand and `manage` is too broad for a context whose purpose is configuring the uspecs lifecycle. `conf` is more precise. Separately, "invocation type" is better expressed as "invocation method" - it describes how the engineer invokes uspecs, not a classification of types.

## What

Two terminology renames across specs, domain files, and bash scripts.

Rename `mgmt` / `manage` to `conf`:

- Context folder `uspecs/specs/prod/mgmt/` -> `uspecs/specs/prod/conf/`
- `mgmt--arch.md` -> `conf--arch.md`
- `invocation-type-mgmt.feature` -> `invocation-method-conf.feature`
- `manage.sh` -> `conf.sh`, update all references in feature files, arch files, and domain files
- `prod--domain.md`: context name, description, and context map
- `ex-domain-prod.md`: context name and references
- `concepts.md`: feature naming convention examples
- `README.md`: all `manage.sh` references

Rename "Invocation Type" to "Invocation Method":

- Concept definition in `prod--domain.md`
- Feature file name and content: `invocation-type-mgmt.feature`
- `manage.sh`: comments, `cmd_it` function, `--nlia`/`--nlic` usage description
- `uspecs.yml` metadata field: `invocation_types` -> `invocation_methods`
- `conf--arch.md` (formerly `mgmt--arch.md`): all references
- `README.md`: "Configure Invocation Types" section header
