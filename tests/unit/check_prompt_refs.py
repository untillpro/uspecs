#!/usr/bin/env python3
"""Check prompt reference integrity.

- Every emit_prompt call in softeng.sh must reference an existing prompt file.
- Every @artdef_ reference in prompt files must reference an existing prompt file (transitive).
- Every prompt file must be reachable from roots (no orphans).

Usage: check_prompt_refs.py <repo_root>
Exit 0 on success, 1 with error details on failure.
"""

import re
import sys
from pathlib import Path


def collect_roots(softeng_sh: Path) -> set[str]:
    """Extract prompt ids from emit_prompt calls in softeng.sh."""
    text = softeng_sh.read_text(encoding="utf-8")
    # Pattern: emit_prompt "$prompts_dir" "instr_xxx" or emit_prompt "$prompts_dir" "instr_xxx" vars
    return set(re.findall(r'emit_prompt\s+"\$prompts_dir"\s+"([^"]+)"', text))


def collect_artdef_refs(prompt_file: Path) -> set[str]:
    """Extract @artdef_ references from a single prompt .md file."""
    text = prompt_file.read_text(encoding="utf-8")
    return set(re.findall(r"`@(artdef_[a-zA-Z0-9_-]+)`", text))


def walk_refs(prompts_dir: Path, roots: set[str]) -> tuple[set[str], list[str]]:
    """Walk references transitively from roots. Return (reachable, errors)."""
    reachable: set[str] = set()
    errors: list[str] = []
    queue = list(roots)
    while queue:
        ref_id = queue.pop()
        if ref_id in reachable:
            continue
        reachable.add(ref_id)
        ref_file = prompts_dir / f"{ref_id}.md"
        if not ref_file.is_file():
            errors.append(f"missing file: {ref_file.name} (referenced as {ref_id})")
            continue
        for dep in collect_artdef_refs(ref_file):
            if dep not in reachable:
                queue.append(dep)
    return reachable, errors


def check_orphans(
    prompts_dir: Path, reachable: set[str], allowed: set[str]
) -> list[str]:
    """Find prompt files not reachable from any root."""
    on_disk = {f.stem for f in prompts_dir.glob("*.md")}
    orphans = sorted(on_disk - reachable - allowed)
    return [f"orphan: {name}.md" for name in orphans]


def main() -> int:
    args = sys.argv[1:]
    allowed_orphans: set[str] = set()
    positional: list[str] = []
    i = 0
    while i < len(args):
        if args[i] == "--allow-orphan" and i + 1 < len(args):
            allowed_orphans.add(args[i + 1])
            i += 2
        else:
            positional.append(args[i])
            i += 1

    if len(positional) != 1:
        print(
            f"Usage: {sys.argv[0]} <repo_root> [--allow-orphan <id>]...",
            file=sys.stderr,
        )
        return 2

    repo_root = Path(positional[0])
    softeng_sh = repo_root / "bin" / "softeng.sh"
    prompts_dir = repo_root / "bin" / "prompts"

    if not softeng_sh.is_file():
        print(f"ERROR: {softeng_sh} not found", file=sys.stderr)
        return 2
    if not prompts_dir.is_dir():
        print(f"ERROR: {prompts_dir} not found", file=sys.stderr)
        return 2

    roots = collect_roots(softeng_sh)
    if not roots:
        print("ERROR: no emit_prompt calls found in softeng.sh", file=sys.stderr)
        return 2

    reachable, errors = walk_refs(prompts_dir, roots)
    errors.extend(check_orphans(prompts_dir, reachable, allowed_orphans))

    if errors:
        for e in sorted(errors):
            print(f"FAIL: {e}")
        return 1

    print(f"OK: {len(reachable)} prompts, all refs valid, no orphans")
    return 0


if __name__ == "__main__":
    sys.exit(main())
