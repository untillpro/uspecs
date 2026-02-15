# Domain architecture: devops

## Development conventions

### Line endings

All files in `uspecs/u/` directory use LF (Unix-style) line endings.

Rationale: Files downloaded from GitHub use LF line endings, making updates easier and avoiding unnecessary line ending conversions.

Implementation: Enforced via `.gitattributes` file in `uspecs/u/` directory.

## Key data models

### Version format

- Semantic versioning: X.Y.Z-aN
  - X: major version
  - Y: minor version
  - Z: patch version
  - aN: pre-release identifier (optional, alpha build number)
- Examples: 1.0.0-a0 (development), 1.0.12 (release)
