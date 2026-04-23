# uspecs

## Install uspecs with natural language invocation support for AI agents

For AGENTS.md (nlia), alpha version:

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/bin/conf.sh | bash -s install --nlia --alpha
```

<details>
<summary>Other variants (not ready)</summary>

For AGENTS.md (nlia), stable version:

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/bin/conf.sh | bash -s install --nlia
```

For CLAUDE.md (nlic):

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/bin/conf.sh | bash -s install --nlic
```

For both:

```sh
curl -fsSL https://raw.githubusercontent.com/untillpro/uspecs/main/bin/conf.sh | bash -s install --nlia --nlic
```

</details>

### Update

Update to the latest version:

```sh
bin/conf.sh update
```

Behavior:

- For alpha: updates to the latest commit from main branch
- For stable: updates to the latest minor version (e.g., 1.2.3 -> 1.2.4, not 1.3.0)

### Upgrade

Upgrade to the latest major version (stable versions only):

```sh
bin/conf.sh upgrade
```

### Configure invocation methods

Add or remove invocation methods:

```sh
bin/conf.sh it --add nlia
bin/conf.sh it --remove nlic
bin/conf.sh it --add nlia --add nlic
```
