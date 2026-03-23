Feature: Change Folder validations
    Change Folder validations used across multiple features

    Scenario Outline: Exactly one Working Change Folder
        Given <condition>
        When action that requires a single Working Change Folder is invoked
        Then AI Agent displays error message and stops
        Examples:
            | condition                             | message                                                  |
            | Multiple Working Change Folders exist | Multiple Working Change Folders exist: <list of folders> |
            | No Working Change Folder exists       | same as condition                                        |

    Scenario Outline: All todo items are completed
        Given <condition>
        When action that requires completed todo items is invoked
        Then AI Agent displays error message and stops
        Examples:
            | condition                                | message                                                      |
            | Change Folder has uncompleted todo items | There are files with uncompleted todo items: <list of files> |