#!/usr/bin/env python3
"""
Parallel test runner for bats tests.

Usage:
    python3 tests/run-tests.py <path> [pattern] [--workers N] [--per-file] [--prof]

<path> may be a folder (recursively scanned for *.bats) or a single .bats file.

Examples:
    python3 tests/run-tests.py tests/unit
    python3 tests/run-tests.py tests/unit --workers 4
    python3 tests/run-tests.py tests/unit --per-file
    python3 tests/run-tests.py tests/unit "emit_prompt"
    python3 tests/run-tests.py tests/unit "emit_prompt" --per-file
    python3 tests/run-tests.py tests/unit --prof
    python3 tests/run-tests.py tests/sys/softeng.sh-action-uchange.bats
"""

import argparse
import atexit
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path
from typing import TypedDict

IS_WINDOWS = sys.platform == "win32"


class TestResult(TypedDict):
    file: str
    test: str
    returncode: int
    stdout: str
    stderr: str
    duration: float


class FileResult(TypedDict):
    file: str
    returncode: int
    stdout: str
    stderr: str
    duration: float


def discover_bats_files(path: str) -> list[Path]:
    """Discover .bats files at the given path.

    Accepts either a directory (recursively scanned for *.bats) or a single
    .bats file.
    """
    p = Path(path)
    if p.is_file():
        if p.suffix != ".bats":
            print(f"Error: '{path}' is not a .bats file", file=sys.stderr)
            sys.exit(1)
        return [p]
    if not p.is_dir():
        print(f"Error: '{path}' is not a directory or file", file=sys.stderr)
        sys.exit(1)

    bats_files = list(p.rglob("*.bats"))
    return sorted(bats_files)


def extract_test_names(bats_file: Path) -> list[str]:
    """Extract all @test names from a bats file."""
    test_pattern = re.compile(r'@test\s+"([^"]+)"')
    tests: list[str] = []

    try:
        with open(bats_file, "r", encoding="utf-8") as f:
            for line in f:
                match = test_pattern.search(line)
                if match:
                    tests.append(match.group(1))
    except Exception as e:
        print(f"Warning: Could not read {bats_file}: {e}", file=sys.stderr)

    return tests


def get_tests_to_run(
    bats_files: list[Path], pattern: str | None
) -> list[tuple[Path, str]]:
    """Get list of (file, test_name) tuples to run, optionally filtered by pattern."""
    tests: list[tuple[Path, str]] = []
    for bats_file in bats_files:
        test_names = extract_test_names(bats_file)
        for test_name in test_names:
            if not pattern or pattern in test_name:
                tests.append((bats_file, test_name))

    return tests


def ere_escape(text: str) -> str:
    """Escape ERE metacharacters for bats -f filter.

    Unlike re.escape, does not escape spaces or other characters that are
    harmless in ERE but would be misinterpreted by bash when passed as
    positional args (backslash-space splits arguments).
    """
    return re.sub(r"([.^$*+?{}\\|()\[\]])", r"\\\1", text)


def run_bats_test(test_info: tuple[Path, str]) -> TestResult:
    """Run a single bats test and return the result."""
    bats_file, test_name = test_info
    t0 = time.monotonic()
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
            "duration": time.monotonic() - t0,
        }
    except subprocess.TimeoutExpired:
        return {
            "file": str(bats_file),
            "test": test_name,
            "returncode": 124,
            "stdout": "",
            "stderr": f"Test timeout after 60 seconds",
            "duration": time.monotonic() - t0,
        }
    except Exception as e:
        return {
            "file": str(bats_file),
            "test": test_name,
            "returncode": 1,
            "stdout": "",
            "stderr": str(e),
            "duration": time.monotonic() - t0,
        }


def run_bats_file(bats_file: Path) -> FileResult:
    """Run all tests in a bats file and return the result."""
    t0 = time.monotonic()
    try:
        bats_path = str(bats_file).replace("\\", "/")
        bash_bin = shutil.which("bash") or "bash"
        cmd = [
            bash_bin,
            "-c",
            'exec bats --print-output-on-failure --tap --timing "$1"',
            "_",
            bats_path,
        ]

        result = subprocess.run(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=300,
        )
        return {
            "file": str(bats_file),
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "duration": time.monotonic() - t0,
        }
    except subprocess.TimeoutExpired:
        return {
            "file": str(bats_file),
            "returncode": 124,
            "stdout": "",
            "stderr": f"File timeout after 300 seconds",
            "duration": time.monotonic() - t0,
        }
    except Exception as e:
        return {
            "file": str(bats_file),
            "returncode": 1,
            "stdout": "",
            "stderr": str(e),
            "duration": time.monotonic() - t0,
        }


def _prebuild_bats_templates() -> str:
    """Pre-build bats system-test scaffold templates into a shared temp dir.

    Returns the template directory path. Registers an atexit handler so the
    directory is cleaned up even on KeyboardInterrupt (which routes through
    os._exit and skips finally blocks).

    Fatal on failure: prints the helper's stderr and aborts the run.
    """
    repo_root = Path(__file__).resolve().parents[1]
    helper = repo_root / "tests" / "sys" / "prebuild-templates.sh"
    if not helper.is_file():
        print(
            f"Error: prebuild helper not found at {helper}",
            file=sys.stderr,
            flush=True,
        )
        sys.exit(1)

    tpl_dir = tempfile.mkdtemp(prefix="uspecs-bats-tpl-")
    atexit.register(shutil.rmtree, tpl_dir, True)

    bash_bin = shutil.which("bash") or "bash"
    try:
        subprocess.run(
            [bash_bin, str(helper), tpl_dir],
            check=True,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        print(
            f"Error: prebuild-templates.sh failed (rc={e.returncode})",
            file=sys.stderr,
            flush=True,
        )
        if e.stderr:
            sys.stderr.write(e.stderr.decode(errors="replace"))
            sys.stderr.flush()
        sys.exit(1)
    return tpl_dir


def main() -> int:
    # Ensure each print() is written to terminal immediately
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(write_through=True)  # type: ignore[union-attr]

    parser = argparse.ArgumentParser(
        description="Run bats tests in parallel",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "path",
        help="Folder to scan for .bats files, or a single .bats file",
    )
    parser.add_argument(
        "pattern",
        nargs="?",
        default=None,
        help="Optional pattern to filter test names (or file paths with --per-file)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=None,
        help="Number of parallel workers (default: auto-detect CPU cores)",
    )
    parser.add_argument(
        "--per-file",
        action="store_true",
        default=False,
        help="Run tests per file instead of per test name",
    )
    parser.add_argument(
        "--prof",
        action="store_true",
        default=False,
        help="On success, print the top 10 slowest tests with their durations",
    )

    args = parser.parse_args()

    # Determine number of workers
    cpu_count = os.cpu_count() or 4
    workers: int = (
        args.workers
        if args.workers
        else min(cpu_count, 10) if IS_WINDOWS else cpu_count
    )

    # Discover bats files
    bats_files = discover_bats_files(args.path)

    if not bats_files:
        print(f"No .bats files found in {args.path}")
        return 0

    # Pre-build shared bats scaffold templates once per run when any system
    # test is in the set; workers inherit USPECS_BATS_TPL_DIR and reuse the
    # pre-built copy instead of rebuilding per bats invocation.
    needs_sys_tpl = any("/sys/" in str(p).replace("\\", "/") for p in bats_files)
    if needs_sys_tpl:
        tpl_dir = _prebuild_bats_templates()
        os.environ["USPECS_BATS_TPL_DIR"] = tpl_dir

    if args.per_file:
        return _run_per_file(bats_files, args.pattern, workers, args.prof)
    else:
        return _run_per_test(bats_files, args.pattern, workers, args.prof)


_TIMING_RE = re.compile(r"\s+in (\d+)ms\s*$")


def _strip_timing(name: str) -> tuple[str, float]:
    """Strip trailing ' in NNNms' from a bats --timing TAP name; return (name, duration_s)."""
    m = _TIMING_RE.search(name)
    if m:
        return name[: m.start()].rstrip(), int(m.group(1)) / 1000.0
    return name, 0.0


def _parse_tap_output(
    file_path: str, stdout: str
) -> list[tuple[str, bool, str, float]]:
    """Parse TAP output: returns list of (label, passed, error_output, duration_s)."""
    results: list[tuple[str, bool, str, float]] = []
    lines = stdout.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match "ok N test name" or "not ok N test name"
        if line.startswith("ok "):
            # Extract test name (skip "ok N ")
            parts = line.split(" ", 2)
            test_name = parts[2] if len(parts) > 2 else "unknown"
            test_name, duration = _strip_timing(test_name)
            label = f"{file_path}: {test_name}"
            results.append((label, True, "", duration))
        elif line.startswith("not ok "):
            # Extract test name (skip "not ok N ")
            parts = line.split(" ", 3)
            test_name = parts[3] if len(parts) > 3 else "unknown"
            test_name, duration = _strip_timing(test_name)
            label = f"{file_path}: {test_name}"
            # Collect following comment lines as error output
            error_lines = [line]
            i += 1
            while i < len(lines) and lines[i].startswith("#"):
                error_lines.append(lines[i])
                i += 1
            results.append((label, False, "\n".join(error_lines), duration))
            continue  # Skip the i += 1 at the end
        i += 1
    return results


def _run_per_file(
    bats_files: list[Path], pattern: str | None, workers: int, prof: bool
) -> int:
    """Run tests per file: each .bats file is a single bats invocation."""
    # Filter files by pattern (match against file path)
    if pattern:
        bats_files = [f for f in bats_files if pattern in str(f).replace("\\", "/")]

    if not bats_files:
        print(f"No files matching '{pattern}' found")
        return 0

    print(f"Running {len(bats_files)} file(s) with {workers} worker(s)...\n")

    passed = 0
    failed = 0
    failures: list[tuple[str, str]] = []
    timings: list[tuple[str, float]] = []
    start_time = time.monotonic()

    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(run_bats_file, f): f for f in bats_files}
        try:
            for future in as_completed(futures):
                result = future.result()
                file_path = result["file"].replace("\\", "/")
                # Parse TAP output to get per-test results
                test_results = _parse_tap_output(file_path, result["stdout"])
                if test_results:
                    for label, test_passed, error_output, duration in test_results:
                        if test_passed:
                            passed += 1
                            timings.append((label, duration))
                            print(f" ok {label}", flush=True)
                        else:
                            failed += 1
                            failures.append((label, error_output))
                            print(f" FAIL {label}", flush=True)
                            if error_output:
                                for line in error_output.splitlines():
                                    print(f"   {line}", flush=True)
                else:
                    # No TAP output parsed - report file-level result
                    if result["returncode"] == 0:
                        passed += 1
                        timings.append((file_path, result["duration"]))
                        print(f" ok {file_path}", flush=True)
                    else:
                        failed += 1
                        output = (result["stdout"] + result["stderr"]).strip()
                        failures.append((file_path, output))
                        print(f" FAIL {file_path}", flush=True)
                        if output:
                            for line in output.splitlines():
                                print(f"   {line}", flush=True)
        except KeyboardInterrupt:
            print("\n\nInterrupted - cancelling pending tests...", flush=True)
            for f in futures:
                f.cancel()
            executor.shutdown(wait=False, cancel_futures=True)
            completed = passed + failed
            print(f"\nAborted after {completed} tests", flush=True)
            os._exit(130)

    if failures:
        print("\nFailed tests:", flush=True)
        for label, output in failures:
            print(f"  FAIL {label}", flush=True)
            if output:
                for line in output.splitlines():
                    print(f"    {line}", flush=True)
                print(flush=True)

    elapsed = time.monotonic() - start_time
    total = passed + failed
    parts = [f"{total} tests", f"{failed} failures", f"{elapsed:.1f}s"]
    print(f"\n{', '.join(parts)}", flush=True)

    if prof and not failed:
        _print_top_slowest(timings)

    return 1 if failed > 0 else 0


def _run_per_test(
    bats_files: list[Path], pattern: str | None, workers: int, prof: bool
) -> int:
    """Run tests per test name: each @test is a separate bats invocation."""
    # Get individual tests to run
    tests = get_tests_to_run(bats_files, pattern)

    if not tests:
        print(f"No tests matching '{pattern}' found")
        return 0

    print(f"Running {len(tests)} test(s) with {workers} worker(s)...\n")

    # Run tests in parallel, report as they complete
    passed = 0
    failed = 0
    skipped = 0
    failures: list[tuple[str, str]] = []
    timings: list[tuple[str, float]] = []
    start_time = time.monotonic()

    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(run_bats_test, t): t for t in tests}
        try:
            for future in as_completed(futures):
                result = future.result()
                file_path = result["file"].replace("\\", "/")
                label = f"{file_path}: {result['test']}"
                if result["returncode"] == 0:
                    passed += 1
                    timings.append((label, result["duration"]))
                    print(f" ok {label}", flush=True)
                elif (
                    "Executed 0 instead of expected 1 tests"
                    in result["stdout"] + result["stderr"]
                ):
                    skipped += 1
                    print(f" skip {label}", flush=True)
                else:
                    failed += 1
                    output = (result["stdout"] + result["stderr"]).strip()
                    failures.append((label, output))
                    print(f" FAIL {label}", flush=True)
                    if output:
                        for line in output.splitlines():
                            print(f"   {line}", flush=True)
        except KeyboardInterrupt:
            print("\n\nInterrupted - cancelling pending tests...", flush=True)
            for f in futures:
                f.cancel()
            executor.shutdown(wait=False, cancel_futures=True)
            completed = passed + failed + skipped
            print(f"\nAborted after {completed}/{len(tests)} tests", flush=True)
            # os._exit bypasses atexit handlers that would block waiting
            # for worker processes to finish
            os._exit(130)

    if failures:
        print("\nFailed tests:", flush=True)
        for label, output in failures:
            print(f"  FAIL {label}", flush=True)
            if output:
                for line in output.splitlines():
                    print(f"    {line}", flush=True)
                print(flush=True)

    elapsed = time.monotonic() - start_time
    total = passed + failed + skipped
    total_failed = failed + skipped
    fail_str = f"{total_failed} failures"
    if skipped:
        fail_str += f" ({skipped} skipped)"
    parts = [f"{total} tests", fail_str, f"{elapsed:.1f}s"]
    print(f"\n{', '.join(parts)}", flush=True)

    if prof and not total_failed:
        _print_top_slowest(timings)

    return 1 if total_failed > 0 else 0


def _print_top_slowest(timings: list[tuple[str, float]], limit: int = 10) -> None:
    """Print the slowest tests by duration (descending)."""
    if not timings:
        return
    timings = sorted(timings, key=lambda x: x[1], reverse=True)[:limit]
    print(f"\nTop {len(timings)} slowest tests:", flush=True)
    for label, duration in timings:
        print(f"  {duration:6.2f}s  {label}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
