#!/usr/bin/env bash
# Marketplace metadata. Values are sentinels in the source repo and are
# rewritten by scripts/_lib/gen-uspecs-market.py at marketplace build time.
# Sourced by bin/softeng.sh and bin/_lib/uversion.sh; no export needed.

# shellcheck disable=SC2034 # these variables are used in sourced scripts, just not in this file

USPECS_VERSION="0.0.0-source"
USPECS_MARKETPLACE_REPO=""
USPECS_MARKETPLACE_NAME=""
USPECS_STREAM=""
USPECS_CLI=""
USPECS_MARKETPLACE_UPDATE_VERB=""
