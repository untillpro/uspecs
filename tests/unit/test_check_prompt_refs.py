#!/usr/bin/env python3
"""Unit tests for check_prompt_refs.py functions."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from check_prompt_refs import (
    check_orphans,
    collect_refs,
    collect_roots,
    walk_refs,
)


class TestCollectRoots(unittest.TestCase):
    def test_extracts_ids(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
            f.write(
                '    emit_prompt "$prompts_dir" "instr_uchange" context_vars\n'
                '    emit_prompt "$prompts_dir" "instr_upr_success" vars\n'
            )
            f.flush()
            result = collect_roots(Path(f.name))
        self.assertEqual(result, {"instr_uchange", "instr_upr_success"})

    def test_no_matches(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
            f.write("echo hello\n")
            f.flush()
            result = collect_roots(Path(f.name))
        self.assertEqual(result, set())


class TestCollectRefs(unittest.TestCase):
    def test_extracts_refs(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("Use `@artdef_change_why_what` and `@artdef_change_how`\n")
            f.flush()
            result = collect_refs(Path(f.name))
        self.assertEqual(result, {"artdef_change_why_what", "artdef_change_how"})

    def test_no_refs(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("# Just a heading\n\nNo refs here.\n")
            f.flush()
            result = collect_refs(Path(f.name))
        self.assertEqual(result, set())

    def test_ignores_non_artdef(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("Use `@something_else` and `@artdef_real`\n")
            f.flush()
            result = collect_refs(Path(f.name))
        self.assertEqual(result, {"artdef_real"})

    def test_extracts_include_refs(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("Use `@artdef_a` and `@include_b`\n")
            f.flush()
            result = collect_refs(Path(f.name))
        self.assertEqual(result, {"artdef_a", "include_b"})


def _make_prompt(prompts_dir: Path, name: str, content: str) -> None:
    (prompts_dir / f"{name}.md").write_text(content, encoding="utf-8")


class TestWalkRefs(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.prompts_dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_simple_root(self) -> None:
        _make_prompt(self.prompts_dir, "instr_a", "# A\n## data\nHello\n")
        reachable, errors = walk_refs(self.prompts_dir, {"instr_a"})
        self.assertEqual(reachable, {"instr_a"})
        self.assertEqual(errors, [])

    def test_transitive_deps(self) -> None:
        _make_prompt(self.prompts_dir, "instr_a", "# A\n## data\nUse `@artdef_b`\n")
        _make_prompt(self.prompts_dir, "artdef_b", "# B\n## data\nUse `@artdef_c`\n")
        _make_prompt(self.prompts_dir, "artdef_c", "# C\n## data\nLeaf\n")
        reachable, errors = walk_refs(self.prompts_dir, {"instr_a"})
        self.assertEqual(reachable, {"instr_a", "artdef_b", "artdef_c"})
        self.assertEqual(errors, [])

    def test_missing_ref(self) -> None:
        _make_prompt(
            self.prompts_dir, "instr_a", "# A\n## data\nUse `@artdef_missing`\n"
        )
        reachable, errors = walk_refs(self.prompts_dir, {"instr_a"})
        self.assertIn("instr_a", reachable)
        self.assertIn("artdef_missing", reachable)
        self.assertEqual(len(errors), 1)
        self.assertIn("missing file", errors[0])

    def test_missing_root(self) -> None:
        _, errors = walk_refs(self.prompts_dir, {"instr_gone"})
        self.assertEqual(len(errors), 1)
        self.assertIn("instr_gone", errors[0])

    def test_dedup(self) -> None:
        _make_prompt(
            self.prompts_dir, "instr_a", "# A\n## data\nUse `@artdef_shared`\n"
        )
        _make_prompt(
            self.prompts_dir, "instr_b", "# B\n## data\nUse `@artdef_shared`\n"
        )
        _make_prompt(self.prompts_dir, "artdef_shared", "# S\n## data\nLeaf\n")
        reachable, errors = walk_refs(self.prompts_dir, {"instr_a", "instr_b"})
        self.assertEqual(reachable, {"instr_a", "instr_b", "artdef_shared"})
        self.assertEqual(errors, [])


class TestCheckOrphans(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.prompts_dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_no_orphans(self) -> None:
        _make_prompt(self.prompts_dir, "instr_a", "")
        result = check_orphans(self.prompts_dir, {"instr_a"}, set())
        self.assertEqual(result, [])

    def test_detects_orphan(self) -> None:
        _make_prompt(self.prompts_dir, "instr_a", "")
        _make_prompt(self.prompts_dir, "instr_orphan", "")
        result = check_orphans(self.prompts_dir, {"instr_a"}, set())
        self.assertEqual(len(result), 1)
        self.assertIn("instr_orphan", result[0])

    def test_allow_orphan(self) -> None:
        _make_prompt(self.prompts_dir, "instr_a", "")
        _make_prompt(self.prompts_dir, "instr_orphan", "")
        result = check_orphans(self.prompts_dir, {"instr_a"}, {"instr_orphan"})
        self.assertEqual(result, [])


if __name__ == "__main__":
    unittest.main()
