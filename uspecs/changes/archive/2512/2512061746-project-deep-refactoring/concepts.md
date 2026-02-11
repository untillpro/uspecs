# Specification rules

## Definitions

- Change: A folder that contains change.md and other files and describes a change to be applied to the project
- Specification Folder: a folder with specification files describing a feature, story, concern etc.
- Specification File: Part of the specification folder, can be functional or technical
- Specification: All Specification Files in the Specification Folder

## Specification folder structure

Folder is named after the feature and contains multiple story-related files.

```text
feature-name/
  - feature-name.md # Functional specification, brief overview, history (change names)
  - story-name-1.feature # Functional story and its scenarios
  - story-name-1.md # Functional, requirements that do not fit .feature file
  - story-name-1-td.md # Technical
  - story-related-files... # Functional
  - user files... # Any
```
