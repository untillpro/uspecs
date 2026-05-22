# Structure: Architecture and Feature Technical Design Specifications

## Layout

````markdown
# {spec-type}: {spec-name}

{Explanatory phrase about the specification}

## External actors

Roles:

- `@RoleName`
  - {Description}
...

Systems:

- `*SystemName`
  - {Description}
...

## Scenarios overview

- `Scenario-1`
  - Description of the scenario
...

## Components

Diagram:

```text
{Layered components diagram see example below}
```

Descriptions:

- `{Component name with notation, e.g. [Name], [[Name]], [(Name)], [/Name/], [~Name~]}`
  - {Description}
  - Path to file or folder, if applicable: [{parent-folder/file-or-folder}]({relative-path-to-code-artifact})
    - Example: [sys/auth.sql](../../../pkg/sys/auth.sql)
...

## Scenarios

### Scenario-1

```text
{ASCII flow diagram -- tree/outline, ladder/lifeline, or step list}
```

### Scenario-2

```mermaid
sequenceDiagram
    {Mermaid sequenceDiagram for complex scenarios -- many participants, branches/loops, or long interactions}
```
...

````

## Rules

- Title `# {spec-type}: {spec-name}` per artifact type:
  - `Domain architecture: {domain}` -- `arch.md`
  - `Domain subsystem architecture: {domain}/{subsystem}` -- `arch-{subsystem}.md`
  - `Context architecture: {domain}/{context}` -- `{context}/arch.md`
  - `Context subsystem architecture: {domain}/{context}/{subsystem}` -- `{context}/arch-{subsystem}.md`
  - `Feature technical design: {feature}` -- `{feature}--td.md`
- Components diagram: layered tree -- named layers stacked top-to-bottom (`== Layer name ==`), nodes within a layer listed as tree branches (`+--`), arrows (`|`, `v`) between layers. External actors, when shown, occupy their own layer (typically the topmost). Layer names describe what the layer contains (e.g. `== Email producers ==`, `== Execution state ==`); do not append the word "layer" to the name
- Scenario diagrams: use ASCII in a `text` fenced block (tree/outline, ladder/lifeline, or step list -- pick what fits the scenario). For complex scenarios (many participants, branches/loops, or long interactions) use a Mermaid `sequenceDiagram` in a `mermaid` fenced block instead
- ASCII diagram notation:
  - `@Name` -- external Role (person)
  - `*Name` -- external System
  - `[Name]` -- internal Component
  - `[(Name)]` -- internal Storage
  - `[/Name/]` -- internal Queue, Topic, or similar message channel
  - `[[Name]]` -- internal Subsystem
  - `[~Name~]` -- internal Scheduler/Timer etc.
- External actors section lists `Roles:` (`@Name`) and `Systems:` (`*Name`); omit either sub-list when empty; omit the whole section when there are no external actors
- Components section lists only internal components; external actors must not be repeated there. Each Component name in the Descriptions list MUST use the shape notation (`[Name]`, `[[Name]]`, `[(Name)]`, `[/Name/]`, `[~Name~]`) matching how it appears in the diagram, and likewise each External actor name in its section MUST use `@Name` / `*Name`
- Every participant name appearing in any diagram must resolve to exactly one entry in either External actors or Components; non-participant tokens in scenario diagrams (parameters, derived values, conditions) are unconstrained
- Every entry in `## Scenarios overview` must have a matching `### {Scenario name}` subsection under `## Scenarios`, and vice versa. Scenario names are written in backticks in the overview bullets and without backticks in the `###` heading; the name text must match exactly
- Top-level sections (`## External actors`, `## Scenarios overview`, `## Scenarios`) may be omitted when empty
- Feature TD only: when a corresponding `*.feature` file exists, scenario names must exactly match the `Scenario:` names in that feature file
- External actors notation is per-spec-type by design: `@Name` / `*Name` in architecture and Feature TD specs; emoji prefixes (`👤` / `⚙️`) in domain specs (see `uspecs-domains`)
- For architecture specifications prefer to describe generic flows, like handling queries, handling commands
  - If there are only a few specific scenarios that are important to call out, then it's ok to describe those specific scenarios instead of generic flows

### Example: layered components diagram

```text
== Email producers ==
  |
  +-- [ap.sys.ApplySendEmailVerificationCode]
  +-- [ap.sys.ApplyInviteEvents]
  +-- [~Jobs with INTENTS(sys.SendMail)~]
        |
        v

== Execution state ==
  |
  +-- [[Async actualizer state]]
  |     |
  |     +-- [(sys.AppSecret)]
  |     +-- [(sys.SendMail)]
  |
  +-- [[Scheduler state]]
        |
        +-- [(sys.AppSecret)]
        +-- [(sys.SendMail)]
              |
              v
```
