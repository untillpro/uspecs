#!/bin/bash
set -Eeuo pipefail

# Regenerate one uspecs marketplace.
#
# Default mode: dev build. Version = <CORE>-dev+YYYYMMDD-HHMM.<SHORT_SHA> (UTC),
# where CORE is the SemVer core read from <uspecs-repo>/version.txt with any
# pre-release / build suffix stripped, and SHORT_SHA is the first 12
# characters of the HEAD commit hash from --uspecs-repo.
#
# Required:
#   --agent <name>             Agent: claude|augment|codex.
#   --uspecs-repo <path>       Path to uspecs source repo.
#   --marketplace-repo <path>  Path to output marketplace repo.
#
# Optional flags (order-independent):
#   --release  Stable release. Version = CORE (no timestamp).
#              Skips if plugin.json version already matches CORE
#              and the marketplace repo is git-clean.
#   --local    Generate only. Skip both `git commit` and `git push`.
#              Always regenerates (no skip guardrail).
#
# Examples:
#   ./deliver.sh --agent claude --uspecs-repo /path/to/uspecs \
#               --marketplace-repo /path/to/uspecs-plugins-claude
#   ./deliver.sh --agent codex --uspecs-repo ... --marketplace-repo ... --release
#   ./deliver.sh --agent augment --uspecs-repo ... --marketplace-repo ... --local

RELEASE_MODE=0
LOCAL_MODE=0
AGENT=""
USPECS_REPO=""
MARKETPLACE_REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --release) RELEASE_MODE=1; shift ;;
    --local)   LOCAL_MODE=1; shift ;;
    --agent)
      if [ $# -lt 2 ]; then echo "error: --agent requires a value" >&2; exit 2; fi
      AGENT="$2"; shift 2 ;;
    --uspecs-repo)
      if [ $# -lt 2 ]; then echo "error: --uspecs-repo requires a value" >&2; exit 2; fi
      USPECS_REPO="$2"; shift 2 ;;
    --marketplace-repo)
      if [ $# -lt 2 ]; then echo "error: --marketplace-repo requires a value" >&2; exit 2; fi
      MARKETPLACE_REPO="$2"; shift 2 ;;
    -h|--help)
      sed -n '3,27p' "$0"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      echo "usage: $0 --agent <name> --uspecs-repo <path> --marketplace-repo <path> [--release] [--local]" >&2
      exit 2
      ;;
  esac
done

if [ -z "$AGENT" ]; then
  echo "error: --agent is required" >&2
  exit 2
fi
case "$AGENT" in
  claude|augment|codex) ;;
  *)
    echo "error: --agent must be one of claude|augment|codex (got: $AGENT)" >&2
    exit 2
    ;;
esac
if [ -z "$USPECS_REPO" ]; then
  echo "error: --uspecs-repo is required" >&2
  exit 2
fi
if [ -z "$MARKETPLACE_REPO" ]; then
  echo "error: --marketplace-repo is required" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$USPECS_REPO/version.txt"

if [ ! -f "$VERSION_FILE" ]; then
  echo "error: version.txt not found at $VERSION_FILE" >&2
  exit 1
fi

RAW_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
# Strip to SemVer core MAJOR.MINOR.PATCH: drop pre-release ("-...") and build metadata ("+...")
CORE="${RAW_VERSION%%-*}"
CORE="${CORE%%+*}"

if [ "$RELEASE_MODE" = 1 ]; then
  VERSION="$CORE"
else
  TS="$(date -u +'%Y%m%d-%H%M')"
  SHORT_SHA="$(git -C "$USPECS_REPO" rev-parse --short=12 HEAD)"
  VERSION="${CORE}-dev+${TS}.${SHORT_SHA}"
fi

PLUGIN_JSON="$MARKETPLACE_REPO/uspecs/.claude-plugin/plugin.json"

# --- Skip guardrail: only in --release mode (and not --local) ---
if [ "$RELEASE_MODE" = 1 ] && [ "$LOCAL_MODE" = 0 ] && [ -f "$PLUGIN_JSON" ]; then
  REPO_VERSION="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$PLUGIN_JSON")"
  if [ "$REPO_VERSION" = "$VERSION" ] && git -C "$MARKETPLACE_REPO" diff --quiet && git -C "$MARKETPLACE_REPO" diff --cached --quiet; then
    echo "Skipping $AGENT: already at $VERSION and clean"
    echo "Done: $VERSION"
    exit 0
  fi
fi

# --- Generate ---
echo "Generating $AGENT marketplace (version $VERSION)..."
GEN_SCRIPT="$SCRIPT_DIR/_lib/gen-uspecs-market.py"
case "$OSTYPE" in
    msys*|cygwin*) GEN_SCRIPT=$(cygpath -m "$GEN_SCRIPT") ;;
esac
python3 "$GEN_SCRIPT" \
  --agent "$AGENT" \
  --uspecs-repo "$USPECS_REPO" \
  --marketplace-repo "$MARKETPLACE_REPO" \
  --version "$VERSION"

# --- Commit and push (skipped in --local mode) ---
if [ "$LOCAL_MODE" = 1 ]; then
  echo "Generated $AGENT (--local: no commit, no push)"
  echo "Done: $VERSION"
  exit 0
fi

git -C "$MARKETPLACE_REPO" add -A
if git -C "$MARKETPLACE_REPO" diff --cached --quiet; then
  echo "No changes in $AGENT after generation, skipping commit"
else
  echo "Committing $MARKETPLACE_REPO..."
  git -C "$MARKETPLACE_REPO" commit -m "$VERSION"
  git -C "$MARKETPLACE_REPO" push
fi

echo "Done: $VERSION"
