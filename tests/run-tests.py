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
import shutil
import subprocess
import sys
import time

IS_WINDOWS = sys.platform == "win32"
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def discover_bats_files(folder):
    """Recursively discover all .bats files in the given folder."""
    folder_path = Path(folder)
    if not folder_path.is_dir():
        print(f"Error: '{folder}' is not a directory", file=sys.stderr)
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


def ere_escape(text):
    """Escape ERE metacharacters for bats -f filter.

    Unlike re.escape, does not escape spaces or other characters that are
    harmless in ERE but would be misinterpreted by bash when passed as
    positional args (backslash-space splits arguments).
    """
    return re.sub(r"([.^$*+?{}\\|()\[\]])", r"\\\1", text)


def run_bats_test(test_info):
    """Run a single bats test and return the result."""
    bats_file, test_name = test_info
    try:
        bats_path = str(bats_file).replace("\\", "/")
        filter_re = f"^{ere_escape(test_name)}$"
        # Run bats via bash -c to bypass bats.cmd on Windows which mangles
        # special characters like parentheses in filter expressions.
        bash_bin = shutil.which("bash") or "bash"
        cmd = [
            bash_bin,
            "-c",
            'exec bats --print-output-on-failure --tap -f "$1" "$2"',
            "_",
            filter_re,
            bats_path,
        ]

        result = subprocess.run(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=60,
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
    # Ensure each print() is written to terminal immediately
    sys.stdout.reconfigure(write_through=True)

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
    workers = (
        args.workers
        if args.workers
        else min(os.cpu_count(), 10) if IS_WINDOWS else os.cpu_count()
    )

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
    skipped = 0
    start_time = time.monotonic()

    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(run_bats_test, t): t for t in tests}
        for future in as_completed(futures):
            result = future.result()
            file_path = result["file"].replace("\\", "/")
            label = f"{file_path}: {result['test']}"
            if result["returncode"] == 0:
                passed += 1
                print(f" ok {label}", flush=True)
            elif "Executed 0 instead of expected 1 tests" in result["stdout"]:
                skipped += 1
                print(f" skip {label}", flush=True)
            else:
                failed += 1
                print(f" FAIL {label}", flush=True)
                output = result["stdout"] + result["stderr"]
                if output.strip():
                    for line in output.strip().splitlines():
                        print(f"   {line}", flush=True)

    elapsed = time.monotonic() - start_time
    total = passed + failed + skipped
    total_failed = failed + skipped
    fail_str = f"{total_failed} failures"
    if skipped:
        fail_str += f" ({skipped} skipped)"
    parts = [f"{total} tests", fail_str, f"{elapsed:.1f}s"]
    print(f"\n{', '.join(parts)}", flush=True)

    return 1 if total_failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
