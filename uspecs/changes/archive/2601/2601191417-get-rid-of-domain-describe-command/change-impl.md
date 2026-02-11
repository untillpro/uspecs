# Implementation: Get rid of domain describe command

## Construction

- [x] update: `[uspecs.sh](../../u/scripts/uspecs.sh)`
  - Remove `domain describe` usage documentation from header comments
  - Remove `cmd_domain_describe()` function
  - Remove domain subcommand case in main() function

- [x] delete: `[domain-describe.sh](../../u/scripts/domain-describe.sh)`
  - Remove main domain describe script

- [x] delete: `[domain-describe-yq.sh](../../u/scripts/domain-describe-yq.sh)`
  - Remove yq-based parser implementation

- [x] delete: `[domain-describe-fb.sh](../../u/scripts/domain-describe-fb.sh)`
  - Remove bash fallback parser implementation
