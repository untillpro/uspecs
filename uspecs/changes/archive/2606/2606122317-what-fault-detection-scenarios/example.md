# Example: fault localization signal

## Fault localized

The agent can identify the faulty mechanism and explain how it causes the symptom: the `## What` flowchart names the fault on a concrete step and contains no unlocalized fault marker.

````markdown
## What

Symptom: PR body contains duplicate What content after a change includes examples.

```text
upr invoked for change.md
    |
    v
PR body extractor    <-- fault: restarts on later fenced ## What heading
    |
    v
PR body contains duplicate What content   (symptom)
```

Corrected behavior: the PR body extractor ignores `## What` headings inside fenced code blocks, so the PR body contains the What content exactly once.
````

## Fault not yet localized

The agent cannot reconstruct the causal step from available evidence: the `## What` flowchart carries the unlocalized fault marker. A generated `## How` section does not count as fault localization, so the marker stays even when `## How` is present.

````markdown
## What

Symptom: PR body sometimes contains duplicate What content after a change includes examples.

```text
upr invoked for change.md
    |
    v
    ?    <-- fault: not yet localized
    |
    v
PR body contains duplicate What content   (symptom)
```

Corrected behavior: the PR body contains the What content exactly once.
````
