#!/usr/bin/env python3
"""Extract literal option arms from softeng.sh action parsers.

This helper intentionally supports the local shape used by bin/softeng.sh. It
is not a general Bash parser.

Output is one tab-separated record per action:

    <action>\t<option> <option> ...

Actions with no options still emit the action name and trailing tab, so callers
can distinguish "action found with no options" from "action was not emitted".
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ANY_FUNCTION_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*\(\) \{\s*$")
ACTION_FUNCTION_RE = re.compile(r"^cmd_action_([A-Za-z0-9_]+)\(\) \{\s*$")
OPTION_ARM_RE = re.compile(r"^\s+(-{1,2}[A-Za-z0-9][A-Za-z0-9-]*)(?:\|[^)]*)?\)")


def split_functions(lines: list[str]) -> dict[str, list[str]]:
    functions: dict[str, list[str]] = {}
    current_action: str | None = None
    current_lines: list[str] = []

    for line in lines:
        action_match = ACTION_FUNCTION_RE.match(line)
        if ANY_FUNCTION_RE.match(line):
            if current_action is not None:
                functions[current_action] = current_lines
            if action_match:
                current_action = action_match.group(1)
                current_lines = [line]
            else:
                current_action = None
                current_lines = []
            continue

        if current_action is not None:
            current_lines.append(line)

    if current_action is not None:
        functions[current_action] = current_lines

    return functions


def extract_options(action: str, body: list[str]) -> list[str]:
    has_while_parser = any("while [[ $# -gt 0 ]]" in line for line in body)
    has_case_parser = any('case "$1" in' in line for line in body)
    if has_while_parser and not has_case_parser:
        raise ValueError(
            f"{action}: found argument loop but not supported case \"$1\" parser"
        )

    options: set[str] = set()
    for line in body:
        match = OPTION_ARM_RE.match(line)
        if not match:
            continue
        options.add(match.group(1))

    return sorted(options)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("script", type=Path, help="path to bin/softeng.sh")
    parser.add_argument(
        "actions",
        nargs="*",
        help="optional action names; defaults to every cmd_action_* in script order",
    )
    args = parser.parse_args()

    lines = args.script.read_text(encoding="utf-8").splitlines()
    functions = split_functions(lines)
    actions: list[str] = args.actions or list(functions)

    try:
        for action in actions:
            body = functions.get(action)
            if body is None:
                raise ValueError(f"{action}: cmd_action_{action}() not found")
            print(f"{action}\t{' '.join(extract_options(action, body))}")
    except ValueError as exc:
        print(f"parse-softeng-action-options.py: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
