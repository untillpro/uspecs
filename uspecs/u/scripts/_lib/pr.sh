#!/usr/bin/env bash
set -Eeuo pipefail

# Concepts
#   pr_remote: upstream or origin
#
#
# Usage:
#   pr.sh check: make sure prerequisites are met
#   pr.sh newbranch <name>: 
#       fetch pr_remote
#       create a branch with the given name from the pr_remote default
#   pr.sh pr --title <name> --body <description>
