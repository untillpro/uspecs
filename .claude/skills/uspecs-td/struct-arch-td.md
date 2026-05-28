# Structure: Architecture and Feature Technical Design Specifications

## Layout

````markdown
# {spec-type}: {spec-name}

## External actors

Roles:

- `@RoleName`
  - {Description}
...

Systems:

- `*SystemName`
  - {Description}
...

## Components

### Layers

{Layered components diagram see example below}

### {Layer name}

- `[Name1]`
  - {Description}
  - decl: [{path-from-the-project-root}]({relative-path-to-declaration})
  - impl: [{path-from-the-project-root}]({relative-path-to-implementation})

- `[(Name2)]`
  - {Description}
  - ...
...

### {Another layer name}

...

## Scenarios

### Scenario 1

{Scenario 1 entry}

...

### {Rule name}

#### Scenario 2

{Scenario 2 entry}

...

## Cross-cutting concerns

### {Concern, e.g. Testing, Observability...}

- {Meta-rule that quantifies over Components or Scenarios in this spec}
- ...

{Brief high-level design for this concern -- optional}

...
```

## Rules

### General

- Every participant name appearing in any diagram must resolve to exactly one entry in either External actors or Components; non-participant tokens in scenario diagrams (parameters, derived values, conditions) are unconstrained
- Top-level sections (`## External actors`, `## Cross-cutting concerns`) may be omitted when empty

### Title

- Title `# {spec-type}: {spec-name}` per artifact type:
  - `Domain architecture: {domain}` -- `arch.md`
  - `Domain subsystem architecture: {domain}/{subsystem}` -- `arch-{subsystem}.md`
  - `Context architecture: {domain}/{context}` -- `{context}/arch.md`
  - `Context subsystem architecture: {domain}/{context}/{subsystem}` -- `{context}/arch-{subsystem}.md`
  - `Feature technical design: {feature}` -- `{feature}--td.md`

### Component notation in diagrams and entries

- `@Name` -- external Role (person)
- `*Name` -- external System
- `[Name]` -- internal Component
- `[(Name)]` -- internal Storage
- `[/Name/]` -- internal callable Endpoint (HTTP, RPC, stored procedure, CLI command, etc.); endpoint names MUST follow established project conventions or external interface rules when they exist, such as route syntax, RPC naming, database routine naming, or CLI command naming. When no convention is defined, use a kind-prefixed endpoint name such as `[/POST /sessions/]`, `[/rpc CreateSession/]`, `[/proc sys.create_session/]`, or `[/cli uspecs sync/]`
- `[>Name>]` -- internal Queue, Topic, Stream, or similar asynchronous message channel
- `[~Name~]` -- internal Scheduler/Timer etc.
- `[[Name]]` -- internal Subsystem

### External actors section

- External actors section lists `Roles:` (`@Name`) and `Systems:` (`*Name`); omit either sub-list when empty; omit the whole section when there are no external actors. Each External actor name in its section MUST use `@Name` / `*Name`
- When possible, actor names should be taken from higher-level specs, such as domain specifications

### Scenarios section

- Feature TD scenarios mirror the corresponding `.feature` file when it exists: `Rule:` blocks become `###` headings; scenarios become `####` headings under their rule, or `###` headings when they are not under a rule. Scenario and scenario outline names must match exactly
- Architecture scenarios usually use generic flow headings directly under `## Scenarios`, such as `Handling queries`, `Handling commands`, or `Processing scheduled work`. If an architecture spec covers 5 or fewer meaningful scenarios and they all use the same small component set, document those specific scenarios directly. Otherwise, use a specific scenario heading only when that flow has distinct architecture worth documenting.

### Scenario entries

- Each scenario entry contains one diagram:

```text
{ASCII flow diagram -- tree/outline, ladder/lifeline, or step list}
```

- Use Mermaid `sequenceDiagram` only for complex scenarios with many participants, branches/loops, or long interactions

### Components section

- `## Components` contains the `### Layers` diagram and internal component entries grouped by layer
- Layered components diagram: named layers stacked top-to-bottom (plain-text layer header on its own line), nodes within a layer listed as tree branches (`+--`), arrows (`|`, `v`) between layers. External actors, when shown, occupy their own layer (typically the topmost). Layer names describe what the layer contains (e.g. `Email producers`, `Execution state`); do not append the word "layer" to the name
- Components section lists only internal components; external actors must not be repeated there
- Every internal participant appearing in any diagram MUST have exactly one Component entry
- Entries for participants shown in the `### Layers` diagram MUST be grouped under their containing layer heading; layer headings MUST match diagram layer names

### Component entries

- Each Component entry heading MUST use the same shape notation and name as the matching participant in diagrams
- Each Component entry MUST include a short description and MAY include:
  - `decl: [{path-from-the-project-root}]({relative-path-to-declaration})`
  - `impl: [{path-from-the-project-root}]({relative-path-to-implementation})`
- Omit `decl` or `impl` when not applicable
- The `decl` / `impl` link text SHOULD show the path from the project root and MAY append a symbol fragment, e.g. `[{path-from-the-project-root}#cmdResetPasswordByEmailExec]({relative-path-to-target})`
- The `decl` / `impl` link destination MUST be the relative path to the target without a fragment
- Component entries MAY include multiple `decl:` or `impl:` bullets when declaration or implementation is split across files or entry points; use one link per bullet
- If a `decl:` and an `impl:` bullet have the same link text, omit the `decl:` bullet

Example:

```markdown
- `[/proc auth.reset_password_by_email/]`
  - Stored procedure endpoint that accepts a reset token and replacement password, validates the token, updates the account password, and consumes the reset request atomically.
  - impl: [db/auth/procedures.sql#cmdResetPasswordByEmailExec](db/auth/procedures.sql)

- `[PasswordResetEmailSender]`
  - Sends password reset instructions after a reset request is created.
  - decl: [src/auth/email.ts](src/auth/email.ts)
  - impl: [src/auth/smtp-email-sender.ts#SmtpPasswordResetEmailSender](src/auth/smtp-email-sender.ts)
```

### Cross-cutting concerns

- A spec MAY include a `## Cross-cutting concerns` section after `## Scenarios`, with one `### {Concern}` subsection per concern
- When the spec is derived from existing code, the `## Cross-cutting concerns` section MUST cover every cross-cutting concern already present in that code; no existing aspect may be omitted

Each `### {Concern}` subsection in `## Cross-cutting concerns`:

- MUST list meta-rule bullets. Each meta-rule quantifies over a declared set in this spec (e.g. "Every Component in {Layer} ...", "Every `*System` interaction ...", "Every `[>Queue>]` ...") and is checkable: it specifies a convention (naming, signal kind, test kind, structural requirement), not implementation choices
- MAY be followed by a brief high-level design (narrative, ASCII diagrams), only when it follows this spec's conventions (diagram notation, name resolution, fenced-block style) and established codebase patterns and agent rules
- Lower-level specs inherit and may add but not contradict
- Do not duplicate inherited cross-cutting rules. If an architecture spec already describes a rule, lower-level specs silently reuse it unless they add a narrower rule or exception

Concrete details for a single Component or Scenario (a specific signal, a specific test case) belong inside that Component/Scenario entry, not in a cross-cutting subsection.

Common cross-cutting concerns (reference list; not a checklist):

- Testing
- Observability (logging, metrics, tracing, health)
- Security (authn/authz, secrets, audit)
- Error handling and resilience (retries, timeouts, circuit breakers, idempotency)
- Performance and scalability (latency budgets, throughput, capacity)
- Persistence and data lifecycle (ownership, retention, migration, backup)
- Configuration and feature flags
- Internationalization / localization
- Concurrency and consistency model
- Versioning and compatibility (APIs, schemas, events)
- Deployment and rollout (blue/green, canary, rollback)

### Example: layered components diagram

```text
Email producers
    |
    +-- [ap.sys.ApplySendEmailVerificationCode]
    +-- [ap.sys.ApplyInviteEvents]
    +-- [~Jobs with INTENTS(sys.SendMail)~]
    |
    v
Execution state
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
```

### Example: cross-cutting concerns

````markdown
## Cross-cutting concerns

### Observability

- Every Component in `Email producers` emits an INFO log `email.producer.invoked` with fields `component`, `intent`, `outcome` (`ok`|`error`)
- Every `[~Jobs with INTENTS(sys.SendMail)~]` emits INFO logs `job.started` and `job.finished` with fields `intent`, `status`, `duration_ms`
- Every `[[Async actualizer state]]` apply emits a histogram `apply_seconds{intent}`
- Every `[(sys.SendMail)]` write emits a trace span `sendmail.write` with attributes `app`, `outcome`
- Every `WARN`+ log line includes `correlation_id` and the originating `[Component]` name

Every layer in `## Components` exposes a uniform logging, metric, and tracing surface, so a single dashboard works across `Email producers` and `Execution state`, and a producer invocation can be correlated with its downstream storage writes.
````
