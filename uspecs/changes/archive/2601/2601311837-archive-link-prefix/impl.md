# Implementation plan

## Construction

- [x] update: [uspecs.sh](../../../u/scripts/uspecs.sh)
  - rename: `convert_links_to_backticks` -> `convert_links_to_relative`
  - update: sed pattern to add `../` prefix to link targets instead of wrapping in backticks
  - update: function call in `cmd_change_archive`
  - update: error message to reflect new function name  
