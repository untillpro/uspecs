# What section fix format

## data

The `## What` section consists of three blocks in this order:

```markdown
Symptom: [symptom]

[flow]

Corrected behavior: [corrected behavior claim]
```

Rules:

- Symptom: one sentence stating the observable wrong outcome
- Flow: a fenced `text` block explaining how the fault produces the symptom, as a vertical ASCII flowchart from the external trigger through the internal causal chain to the symptom, with the fault marked as a step
  - Steps may use conceptual labels (e.g. "the body builder", "the validator", "the rule") and/or concrete identifiers (file names, function/method names, config keys, etc.)
  - Prefer file names and concrete identifiers when the fault is already located in code; use conceptual labels when it is not
  - When a step in the chain cannot be reconstructed from available evidence, use `?` as its label and continue the chain. Mark the fault on the `?` step when the location itself is the unknown
  - Example:

    ```text
    user submits form
          |
          v
    request validator
          |
          v
    body builder         <-- fault: drops trailing field
          |
          v
    downstream API rejects request   (symptom)
    ```

  - Example with unknown step:

    ```text
    user submits form
          |
          v
    request validator
          |
          v
          ?               <-- fault: not yet localized
          |
          v
    downstream API rejects request   (symptom)
    ```

- Corrected behavior claim: one sentence stating what the system does after the fix
- Marker placement:
  - When the fault is not localized, the flowchart contains the unlocalized fault marker (a `?` step annotated `<-- fault: not yet localized`)
  - When the fault is localized, the flowchart names it on a concrete step and contains no unlocalized fault marker
- Localization investigation bounds (at change-request creation time):
  - Static only: read and search the codebase; do not run code or tests; do not attempt to reproduce the symptom
  - Capped at roughly 5 searches and 10 file reads
  - Stop earlier as soon as pinning the fault would require verification rather than reading, and place the marker; deeper localization happens later in uimpl
