# Domain architecture: devops

## Development conventions

### Line endings

All files in `bin/` directory use LF (Unix-style) line endings.

Rationale: Files downloaded from GitHub use LF line endings, making updates easier and avoiding unnecessary line ending conversions.

Implementation: Enforced via `.gitattributes` file in `bin/` directory.

## Key data models

### Version format

- Semantic versioning aligned with the three-branch release cycle:
  - `X.Y.Z-dev` on `main` (active development)
  - `X.Y.Z-rc` on `rc` (release candidate stabilization)
  - `X.Y.Z` on `release` (stable production)
  - X: major version
  - Y: minor version
  - Z: patch version
- Build suffix for delivered pre-release plugin builds: `+YYYYMMDD-HHMM.SHORT_SHA`
  - Applied to dev and rc streams when CD publishes plugins
  - Example: `2.3.0-dev+20260509-1049.a1b2c3d`, `2.3.0-rc+20260509-1830.e4f5a6b`
- Examples: `2.3.0-dev` (main), `2.3.0-rc` (rc), `2.3.0` (release)
