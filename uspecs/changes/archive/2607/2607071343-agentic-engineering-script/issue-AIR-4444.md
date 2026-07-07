# uspecs: script for agentic engineering

<!-- markdownlint-disable -->

- URL: https://untill.atlassian.net/browse/AIR-4444
- ID: AIR-4444
- State: in-progress
- Author: Maksim Geraskin
- Labels: none
- Parent: [AIR-4443: Agentic engineering action](https://untill.atlassian.net/browse/AIR-4443)

## What

Script that runs uspecs in a controlled loop and finally makes a PR.

Parameters:

* issueURL
* agentic-tool: auggie, claude

Flow:

* Run uchange {url}
* Fail fast if either the branch or the new change folder has not been created
* Run uspecs in a loop

    * break conditions

        * cap: 40 minutes or 40 iterations, whichever comes first
        * hash of the change folders is not changed


* switch:

    * Construction section with \[x\] exists?

        * `upr`

    * no: fails
