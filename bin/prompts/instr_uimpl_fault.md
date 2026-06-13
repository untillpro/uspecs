# Localize fault

## data

The change request `${change_folder}/change.md` is a fix whose fault is not yet localized: the `## What` section carries the `? <-- fault: not yet localized` marker on a standalone line.

Read `${change_folder}/fault.md` and build on the recorded efforts rather than restart the investigation. (?fault_md_exists)

Your task is to localize the fault: identify the faulty mechanism, file, symbol, rule, or causal step and explain how it causes the symptom. Unlike the bounded static investigation at change-request creation time, you may run code and tests to verify hypotheses.

Rules:

- Track localization efforts in `${change_folder}/fault.md`; the file persists across invocations and its format is up to you

On success:

- Replace the `?` step in the `## What` flowchart with the concrete faulty step
- Re-invoke uimpl with the original arguments: run `${uimpl_reinvoke}`

On failure:

- Update `${change_folder}/fault.md` with the efforts taken
- Inform the Engineer of the efforts taken and stop processing
