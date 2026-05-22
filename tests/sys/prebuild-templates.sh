#!/bin/bash
# Pre-build bats system-test scaffold templates into $USPECS_BATS_TPL_DIR.
# Idempotent: re-running is a no-op if the templates are already present.
#
# Usage:
#   USPECS_BATS_TPL_DIR=/path/to/tpl bash tests/sys/prebuild-templates.sh
#   bash tests/sys/prebuild-templates.sh /path/to/tpl
#
# Intended to be invoked by tests/run-tests.py before spawning parallel
# workers, so every worker reuses a single set of pre-built templates
# instead of rebuilding them per bats invocation.
set -Eeuo pipefail

if [[ -z "${USPECS_BATS_TPL_DIR:-}" && $# -ge 1 ]]; then
    export USPECS_BATS_TPL_DIR="$1"
fi

if [[ -z "${USPECS_BATS_TPL_DIR:-}" ]]; then
    echo "prebuild-templates.sh: set USPECS_BATS_TPL_DIR or pass dir as \$1" >&2
    exit 2
fi

mkdir -p "$USPECS_BATS_TPL_DIR"

# On MSYS/Cygwin, normalize the template directory to mixed Windows form so
# git and bash agree on its location (matches _setup_project_root's handling
# of $BATS_TEST_TMPDIR). Without this, callers passing an MSYS-style path
# (e.g. /tmp/...) cause git -C inside _build_git_template to fail.
case "$OSTYPE" in
    msys*|cygwin*) USPECS_BATS_TPL_DIR=$(cygpath -m "$USPECS_BATS_TPL_DIR") ;;
esac
export USPECS_BATS_TPL_DIR

# shellcheck source=helpers.bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.bash"

_build_origin_template
