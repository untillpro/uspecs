---
registered_at: 2026-03-10T12:20:55Z
change_id: 2603101220-use-python-instead-of-bash
baseline: fbce1b2c5864e7caf1cd1ea269bcf11db209c3f4
---

# Change request: Use Python instead of Bash

## Why

The current `uspecs.sh` script is implemented in Bash, which has limited tooling, harder error handling, and less maintainable code for complex logic. Python offers better readability, richer standard library, and improved testability.

## What

Replace the Bash implementation of `uspecs/u/scripts/uspecs.sh` with a Python equivalent:

- Rewrite `uspecs.sh` entry point as a Python script (e.g., `uspecs.py`)
- Port all existing commands and subcommands to Python
- Update any references to the script (CLAUDE.md, documentation, other scripts)
- Ensure the Python script has the same CLI interface and behavior as the current Bash script
