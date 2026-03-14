#!/usr/bin/env python3
"""
Parallel test runner for bats tests.

Usage:
    python scripts/run-tests.py <folder> [pattern] [--workers N]

Examples:
    python scripts/run-tests.py tests/unit
    python scripts/run-tests.py tests/unit "shell metacharacters"
    python scripts/run-tests.py tests/unit --workers 4
    python scripts/run-tests.py tests/unit "extracts section" --workers 1
"""

import argparse
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def discover_bats_files(folder):
    """Recursively discover all .bats files in the given folder."""
    folder_path = Path(folder)
    if not folder_path.exists():
        print(f"Error: Folder '{folder}' does not exist", file=sys.stderr)
        sys.exit(1)

    bats_files = list(folder_path.rglob("*.bats"))
    return sorted(bats_files)


def extract_test_names(bats_file):
    """Extract all @test names from a bats file."""
    test_pattern = re.compile(r'@test\s+"([^"]+)"')
    tests = []

    try:
        with open(bats_file, "r", encoding="utf-8") as f:
            for line in f:
                match = test_pattern.search(line)
                if match:
                    tests.append(match.group(1))
    except Exception as e:
        print(f"Warning: Could not read {bats_file}: {e}", file=sys.stderr)

    return tests


def get_tests_to_run(bats_files, pattern):
    """Get list of (file, test_name) tuples to run, optionally filtered by pattern."""
    tests = []
    for bats_file in bats_files:
        test_names = extract_test_names(bats_file)
        for test_name in test_names:
            if not pattern or pattern in test_name:
                tests.append((bats_file, test_name))

    return tests


def run_bats_test(test_info):
    """Run a single bats test and return the result."""
    bats_file, test_name = test_info
    try:
        # On Windows, use shell=True and convert path to forward slashes for bats
        use_shell = sys.platform == "win32"
        bats_path = str(bats_file).replace("\\", "/") if use_shell else str(bats_file)
        cmd = (
            f'bats -f "^{re.escape(test_name)}$" "{bats_path}"'
            if use_shell
            else ["bats", "-f", f"^{re.escape(test_name)}$", bats_path]
        )

        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=60, shell=use_shell
        )
        return {
            "file": str(bats_file),
            "test": test_name,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
        }
    except subprocess.TimeoutExpired:
        return {
            "file": str(bats_file),
            "test": test_name,
            "returncode": 124,
            "stdout": "",
            "stderr": f"Test timeout after 60 seconds",
        }
    except Exception as e:
        return {
            "file": str(bats_file),
            "test": test_name,
            "returncode": 1,
            "stdout": "",
            "stderr": str(e),
        }


def main():
    parser = argparse.ArgumentParser(
        description="Run bats tests in parallel",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("folder", help="Folder to scan for .bats files")
    parser.add_argument(
        "pattern", nargs="?", default=None, help="Optional pattern to filter test names"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=None,
        help="Number of parallel workers (default: auto-detect CPU cores)",
    )

    args = parser.parse_args()

    # Determine number of workers
    workers = args.workers if args.workers else os.cpu_count()

    # Discover bats files
    bats_files = discover_bats_files(args.folder)

    if not bats_files:
        print(f"No .bats files found in {args.folder}")
        return 0

    # Get individual tests to run
    tests = get_tests_to_run(bats_files, args.pattern)

    if not tests:
        print(f"No tests matching '{args.pattern}' found")
        return 0

    print(f"Running {len(tests)} test(s) with {workers} worker(s)...\n")

    # Run tests in parallel, report as they complete
    passed = 0
    failed = 0
    start_time = time.monotonic()

    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(run_bats_test, t): t for t in tests}
        for future in as_completed(futures):
            result = future.result()
            file_path = result["file"].replace("\\", "/")
            label = f"{file_path}: {result['test']}"
            if result["returncode"] == 0:
                passed += 1
                print(f" ok {label}")
            else:
                failed += 1
                print(f" FAIL {label}")
                output = result["stdout"] + result["stderr"]
                if output.strip():
                    for line in output.strip().splitlines():
                        print(f"   {line}")

    elapsed = time.monotonic() - start_time
    print(f"\n{passed + failed} tests, {failed} failures, {elapsed:.1f}s")

    return 1 if failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
