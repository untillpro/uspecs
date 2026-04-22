---
name: python
description: Use this skill when writing Python code
user-invocable: false
---

# Python type annotations

Always add explicit type annotations to prevent Pylance/type checker warnings:

- All function parameters and return types must have type annotations
- Empty lists must have type annotations: `failures: list[tuple[str, str]] = []`
- Use `TypedDict` for dictionary return types with known keys instead of `dict[str, str | int]`
- Handle `None` from functions like `os.cpu_count()`: use `os.cpu_count() or 4`
- For runtime-only attributes like `sys.stdout.reconfigure`, use `hasattr` check with `# type: ignore`
