# What section fix format

## data

The `## What` section consists of three blocks in this order:

```markdown
[symptom]

[flow]

[corrected behavior claim]
```

Rules:

- Symptom: one sentence stating the observable wrong outcome
- Flow: a fenced `text` block containing a vertical ASCII flowchart from the external trigger through the internal causal chain to the symptom, with the fault marked as a step
  - Steps may use conceptual labels (e.g. "the body builder", "the validator", "the rule") and/or concrete identifiers (file names, function/method names, config keys, etc.)
  - Prefer concrete identifiers when the fault is already located in code; use conceptual labels when it is not
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
