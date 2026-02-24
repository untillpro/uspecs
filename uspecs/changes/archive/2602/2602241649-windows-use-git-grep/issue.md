# AIR-3062: uspecs: on windows try to use grep from the git install

Type: Sub-task
Parent: AIR-2649 - Internal technical problems: Minor issues
Status: To Do
URL: https://untill.atlassian.net/browse/AIR-3062

## Why

Windows may have multiple grep installed and it breaks the scripts since some options are not supported or do not work as expected.

## What

We should use grep from Bash/MSYS2 (bundled with git) on Windows.

