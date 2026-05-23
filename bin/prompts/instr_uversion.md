# Show plugin version

## data

Display the uspecs framework plugin version to the user: ${version}

Display update availability: ${availability}
Display latest available version: ${latest_version} (?latest_version)
Display availability note: ${availability_note} (?availability_note)

When update instructions are present, show them to the user as the marketplace refresh command:

```sh (?update_instructions)
${update_instructions} (?update_instructions)
``` (?update_instructions)

Do not install the uspecs plugin.
Do not execute the update command.
Do not require a separate version-check command.
