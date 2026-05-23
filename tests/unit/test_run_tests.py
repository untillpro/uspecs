#!/usr/bin/env python3
"""Unit tests for run-tests.py functions."""

import importlib.util
import tempfile
import unittest
from pathlib import Path

_RUNNER_PATH = Path(__file__).resolve().parents[1] / "run-tests.py"
_spec = importlib.util.spec_from_file_location("run_tests", _RUNNER_PATH)
assert _spec is not None and _spec.loader is not None
run_tests = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(run_tests)

discover_bats_files = run_tests.discover_bats_files


class TestDiscoverBatsFiles(unittest.TestCase):
    def test_directory_recursive(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "a.bats").write_text("@test x { :; }\n")
            sub = root / "sub"
            sub.mkdir()
            (sub / "b.bats").write_text("@test y { :; }\n")
            (root / "ignore.txt").write_text("nope\n")
            result = discover_bats_files(str(root))
        self.assertEqual(
            sorted(p.name for p in result),
            ["a.bats", "b.bats"],
        )

    def test_single_bats_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "single.bats"
            f.write_text("@test x { :; }\n")
            result = discover_bats_files(str(f))
        self.assertEqual(result, [f])

    def test_non_bats_file_exits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "not-bats.txt"
            f.write_text("\n")
            with self.assertRaises(SystemExit) as cm:
                discover_bats_files(str(f))
        self.assertEqual(cm.exception.code, 1)

    def test_missing_path_exits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            missing = str(Path(tmp) / "does-not-exist")
            with self.assertRaises(SystemExit) as cm:
                discover_bats_files(missing)
        self.assertEqual(cm.exception.code, 1)

    def test_empty_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = discover_bats_files(tmp)
        self.assertEqual(result, [])


if __name__ == "__main__":
    unittest.main()
