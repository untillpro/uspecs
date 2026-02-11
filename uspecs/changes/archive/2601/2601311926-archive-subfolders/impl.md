# Implementation plan

## Construction

- [x] update: [uspecs.sh](../../../../u/scripts/uspecs.sh)
  - update: header comment (lines 17-19) - document new archive path structure with yymm subfolder
  - update: `convert_links_to_relative` - change `../` to `../../` in sed replacement
  - update: `cmd_change_archive` - extract yymm prefix, create year-month subfolder, update archive_path

- [x] update: [actn-changes.md](../../../../u/actn-changes.md)
  - update: line 53 - clarify archive subfolder structure in output description
