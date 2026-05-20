Feature: Implementation plan management
  Engineer implements change request

  # ## Glossary
  #
  # Implementation Folder: Active Change Folder the implementation plan is applied to
  # Implementation Plan File: impl.md or change.md file, which exists

  Scenario: Multiple Active Working Change Folders
    Given multiple Active Working Change Folders exist
    When Engineer invokes uimpl action
    Then AI Agent displays a message "Multiple appropriate change folders found. Please specify which one to use"
    And lists all Active Change Folders

    # Agent reinvokes uchange with --impl-folder option
    And allows Engineer to select one and then Agent reinvokes action with the selected folder as Implementation Folder

  Scenario: No Active Working Change Folders
    Given no Active Working Change Folders exist
    When Engineer invokes uimpl action
    Then AI Agent displays a message "No active working change folder found. Please create a change request first"
    And Implementation Plan is not created

  Rule: Implementation Folder is identified
    Background:
      Given Implementation Folder is selected by Engineer or there is only one Active Working Change Folder

    Scenario Outline: uimpl base behavior
      Given impl.md <existence> in Implementation Folder
      When Engineer invokes uimpl action
      Then Implementation Plan File is <file>
      Examples:
        | existence      | file                    |
        | does not exist | {impl_folder}/change.md |
        | already exists | {impl_folder}/impl.md   |

    Scenario: Only Review Item unchecked
      Given only Review Item in Implementation Plan File is unchecked
      When Engineer invokes uimpl action
      Then AI Agent displays a message "Review item is pending. Please review the implementation plan and check the item when ready"
      And AI Agent does not perform any implementation action

    Scenario Outline: How section creation when missing
      Given there are no unchecked to-do items in Implementation Plan File
      And `change.md` does not contain a `## How` section
      And no planning section (`Domain specifications`, `Functional design`, `Provisioning and configuration`, `Technical design`, `Construction`) exists in Implementation Plan File
      When Engineer invokes uimpl action <flag>
      Then AI Agent <outcome>
      Examples:
        | flag          | outcome                                                                                                                  |
        | without flags | appends `## How` to `change.md` per `artdef_change_how.md` and stops execution                                           |
        | with `--plan` | does not create `## How` and proceeds with the existing planning sections cascade described in the next Scenario Outline |

    Scenario Outline: No unchecked to-do items
      Given there are no unchecked to-do items in Implementation Plan File
      When Engineer invokes uimpl action
      And AI Agent executes only one (the first available) <action> depending on <condition>
      Examples:
        | condition                                                                  | action                                                                                                                                                                                          |
        | `Domain specifications` section does not exist and it is needed            | Create `Domain specifications` section with checkbox items referencing domain.md files                                                                                                          |
        | `Functional design specifications` section does not exist and it is needed | Create `Functional design specifications` section with checkbox items referencing spec files                                                                                                    |
        | `Provisioning and configuration` section does not exist and it is needed   | Create `Provisioning and configuration` section with installation/configuration steps                                                                                                           |
        | `Technical design specifications` section does not exist and it is needed  | Create `Technical design specifications` section with checkbox items referencing design files                                                                                                   |
        | `Construction` section does not exist and it is needed                     | Create `Construction` section, optionally `Quick start` section, and set `scope:` (when at least one scope applies) and `breaking: true` (when the change is breaking) in change.md frontmatter |
        | Nothing of the above                                                       | Display message "No action needed"                                                                                                                                                              |
      And AI Agent stops execution after performing the action

    Scenario: Some unchecked to-do items
      Given some to-do items in Implementation Plan File are unchecked
      When Engineer invokes uimpl action
      Then AI Agent implements each unchecked To-Do Item and checks it immediately after implementation
      But it stops on Review Item if it is unchecked

    Scenario Outline: Auto-invoke self-review after todos
      Given some to-do items in <section> are unchecked in Implementation Plan File
      When Engineer invokes uimpl action <flag>
      And AI Agent completes the unchecked to-do items
      Then AI Agent <action>
      Examples:
        | section                          | flag             | action                                                      |
        | Functional design specifications |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Technical design specifications  |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Domain specifications            |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Provisioning and configuration   |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Construction                     |                  | invokes `softeng self-review --type construction --stage A` |
        | any                              | --no-self-review | does not invoke self-review                                 |

    Scenario Outline: Auto-invoke self-review after section creation
      Given Implementation Plan File has no unchecked to-do items
      And the <section> section does not yet exist in Implementation Plan File
      When Engineer invokes uimpl action <flag>
      And AI Agent appends the <section> section
      Then AI Agent <action>
      Examples:
        | section                          | flag             | action                                                    |
        | Domain specifications            |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Functional design specifications |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Provisioning and configuration   |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Technical design specifications  |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Construction                     |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | any                              | --no-self-review | does not invoke self-review                               |

    Scenario: No section appended and no todos: self-review is not chained
      Given Implementation Plan File has no unchecked to-do items
      And all implementation plan sections already exist in Implementation Plan File
      When Engineer invokes uimpl action
      Then AI Agent emits the "plan completed" notice
      And AI Agent does not invoke self-review

    Scenario: Construction todos: AI Agent evaluates concurrency
      Given some to-do items in Construction are unchecked in Implementation Plan File
      When Engineer invokes uimpl action
      And AI Agent completes the unchecked to-do items
      Then AI Agent evaluates whether the completed changes touch concurrency-sensitive code paths
      And AI Agent includes --concurrency on the self-review invocation when applicable