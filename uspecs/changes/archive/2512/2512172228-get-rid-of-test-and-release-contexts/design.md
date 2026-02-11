# Technical design: Context consolidation

## Overview

Consolidate test and release contexts into dev context by updating contexts.yml configuration, merging relationship definitions, and regenerating domain documentation. The change simplifies the devops domain structure from four contexts (dev, test, release, ops) to two contexts (dev, ops).

## Project configuration

**Schema updates:**

- `[scheme-contexts.json](../../u/scheme-contexts.json)`: Add modified_at field support
  - Manual edit - Add optional modified_at field to metadata.generation properties

## Architecture

### Relationship mapping

Current relationships involving test and release contexts:

- [release, ops] supplier-customer: Deployable releases and artifacts
- [test, release] supplier-customer: Test results and quality metrics
- [dev, test] supplier-customer: Code changes for testing
- [CI System, test] ohs: Test execution automation
- [CI System, release] ohs: Build and deployment automation
- [test, Developer] supplier-customer: Test execution capabilities
- [test, Maintainer] supplier-customer: Test environment management
- [release, Maintainer] supplier-customer: Release management capabilities

After consolidation, these become dev relationships:

- [dev, ops] supplier-customer: Deployable releases and artifacts (NEW - was release->ops)
- [CI System, dev] ohs: CI automation and automated checks (EXISTING - already covers all automation)
- [dev, Developer] supplier-customer: Software development environment (EXISTING - expand details to include test execution)
- [dev, Maintainer] supplier-customer: Repository management capabilities (EXISTING - expand details to include test environment and release management)

Removed relationships (internal to dev context):

- [dev, test] supplier-customer: Code changes for testing (internal workflow)
- [test, release] supplier-customer: Test results and quality metrics (internal workflow)

## File updates

- [x] update: `[scheme-contexts.json](../../u/scheme-contexts.json)`
  - Add modified_at as optional field in metadata.generation.properties (after generated_at)
  - Pattern: "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}$"
  - Description: "Timestamp when the file was last modified in UTC"

- [x] update: `[contexts.yml](../../contexts.yml)`
  - Update devops domain description from "Development, testing, release and operations" to "Development and operations" (line 79)
  - Remove test context definition (lines 84-86)
  - Remove release context definition (lines 87-89)
  - Update dev context description to "Development, testing, and release automation" (line 83)
  - Remove relationship: [test, release] (lines 107-109)
  - Remove relationship: [dev, test] (lines 110-112)
  - Remove relationship: [CI System, test] (lines 116-118)
  - Remove relationship: [CI System, release] (lines 119-121)
  - Remove relationship: [test, Developer] (lines 135-141)
  - Remove relationship: [test, Maintainer] (lines 142-147)
  - Remove relationship: [release, Maintainer] (lines 148-153)
  - Update relationship: [release, ops] to [dev, ops] - change first participant from "release" to "dev" (line 104)
  - Expand [dev, Developer] details to add: "Write tests", "Run tests locally", "Review test results" (after line 128)
  - Expand [dev, Maintainer] details to add: "Configure test environments", "Set up test automation", "Configure release pipelines", "Manage versions and tags" (after line 134)
  - Add modified_at: "2025-12-17 21:30" to metadata.generation (after line 8)
  - Preserve existing generated_at: "2025-12-13 14:30" (line 8)

- [x] update: `[domain-devops.md](../../domain-devops.md)`
  - Regenerate by running build-rels.sh after contexts.yml update
  - Will automatically update Contexts section to show only dev and ops
  - Will automatically update Context map to show simplified relationships
  - Will automatically remove "Relationships for context: test" and "Relationships for context: release" sections
  - Will automatically update "Relationships for context: dev" to include merged relationships

## Quick start

Update contexts.yml manually, then regenerate domain documentation:

```bash
bash uspecs/u/scripts/uspecs.sh domains build uspecs/contexts.yml
```

## References

- `[change.md](change.md)` - Change description and scope
- `[decisions.md](decisions.md)` - Design decisions
- `[contexts.yml](../../contexts.yml)` - Source configuration file
- `[build-rels.sh](../../u/scripts/build-rels.sh)` - Domain documentation generator
- `[scheme-contexts.json](../../u/scheme-contexts.json)` - YAML schema definition
