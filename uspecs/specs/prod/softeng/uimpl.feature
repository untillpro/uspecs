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

    Scenario Outline: Only Review Item unchecked
      Given only Review Item `<item>` in Implementation Plan File is unchecked
      When Engineer invokes uimpl action
      Then AI Agent displays a message "Review item is pending. Please review the implementation plan and check the item when ready"
      And AI Agent does not emit next todo instructions
      And AI Agent does not perform any implementation action
      Examples:
        | item         |
        | - [ ] Review |
        | - review     |

    Scenario Outline: How section creation when missing
      Given there are no unchecked to-do items in Implementation Plan File
      And `change.md` does not contain a `## How` section
      And no planning section (`Domain design`, `Functional design`, `Provisioning and configuration`, `Technical design`, `Construction`) exists in Implementation Plan File
      And the fault localization gate does not trigger (see Rule: Fault localization gate, which precedes How authoring)
      When Engineer invokes uimpl action <flag>
      Then AI Agent <outcome>
      Examples:
        | flag          | outcome                                                                                                                  |
        | without flags | appends `## How` to `change.md` per `artdef_change_how.md` and stops execution                                           |
        | with `--plan` | does not create `## How` and proceeds with the existing planning sections cascade described in the next Scenario Outline |

    Scenario: How section content
      Given AI Agent appends `## How` to `change.md` per `artdef_change_how.md`
      When AI Agent authors the section
      Then `Decisions:` contains only new high-level choices not already established by `change.md` or its referenced documents
      And per-file edits, symbols, exact test cases, command sequences, and ordered implementation steps are deferred to `## Construction`
      And `Decisions:` contains `- None` when there are no new implementation decisions
      And `Assumptions:` contains only unverified premises necessary for the high-level implementation strategy
      And `Assumptions:` contains `- None` when there are no such premises
      And `Out of scope:` contains only new scope boundaries and is omitted when there are none
      And `References:` contains only sources that directly support a new decision or assumption and is omitted when there are none

    Scenario Outline: No unchecked to-do items
      Given there are no unchecked to-do items in Implementation Plan File
      When Engineer invokes uimpl action
      And AI Agent executes only one (the first available) <action> depending on <condition>
      Examples:
        | condition                                                                  | action                                                                                                                                                                                                              |
        | `Domain design` section does not exist and it is needed                    | Create `Domain design` section with checkbox items referencing Domain Design Specification artifacts                                                                                                                |
        | `Functional design` section does not exist and it is needed                | Create `Functional design` section with checkbox items referencing functional specification files                                                                                                                    |
        | `Provisioning and configuration` section does not exist and it is needed   | Create `Provisioning and configuration` section with installation/configuration steps                                                                                                                               |
        | `Technical design` section does not exist and it is needed                 | Create `Technical design` section with checkbox items referencing technical specification files                                                                                                                      |
        | `Construction` section does not exist and it is needed                     | Create `Construction` section, optionally `Quick start` section, and set `scope:` as a YAML flow list (when at least one scope applies) and `breaking: true` (when the change is breaking) in change.md frontmatter |
        | Nothing of the above                                                       | Display message "No action needed"                                                                                                                                                                                  |
      And AI Agent stops execution after performing the action

    Scenario: Fix-type change skips specs-tier cascade steps
      Given `change.md` frontmatter is `type: fix`
      And `change.md` contains a `## How` section
      And there are no unchecked to-do items in Implementation Plan File
      And the cascade would otherwise propose a `Domain design`, `Functional design`, or `Technical design` section
      When Engineer invokes uimpl action
      Then AI Agent skips those specs-tier sections
      And AI Agent proceeds to the next applicable cascade step (`Provisioning and configuration` or `Construction`)

    Scenario: Some unchecked to-do items
      Given some to-do items in Implementation Plan File are unchecked
      When Engineer invokes uimpl action
      Then AI Agent implements each unchecked To-Do Item and checks it immediately after implementation
      But it stops on Review Item if it is unchecked

    Scenario Outline: Review item bounds the emitted Construction todos
      Given unchecked Construction to-do items exist before and after Review Item `<item>` in Implementation Plan File
      When Engineer invokes uimpl action
      Then AI Agent emits next todo instructions containing only the unchecked Construction to-do items before Review Item
      And unchecked Construction to-do items after Review Item are left for a later implementation cycle
      Examples:
        | item         |
        | - [ ] Review |
        | - review     |

    Scenario Outline: Auto-invoke self-review after todos
      Given some to-do items in <section> are unchecked in Implementation Plan File
      When Engineer invokes uimpl action <flag>
      And AI Agent completes the unchecked to-do items
      Then AI Agent <action>
      Examples:
        | section                          | flag             | action                                                      |
        | Functional design                |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Technical design                 |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
        | Domain design                    |                  | invokes `softeng self-review --type specs --stage A -b 4`   |
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
        | Domain design                    |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Functional design                |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Provisioning and configuration   |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Technical design                 |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | Construction                     |                  | invokes `softeng self-review --type specs --stage A -b 4` |
        | any                              | --no-self-review | does not invoke self-review                               |

    Scenario: No section appended and no todos: self-review is not chained
      Given Implementation Plan File has no unchecked to-do items
      And all implementation plan sections already exist in Implementation Plan File
      When Engineer invokes uimpl action
      Then AI Agent emits the "plan completed" notice
      And AI Agent does not invoke self-review

  Rule: Fault localization gate

    Scenario Outline: Gate trigger conditions
      Given change.md frontmatter has type <type>
      And the unlocalized fault marker `? <-- fault: not yet localized` appears <location>
      When Engineer invokes uimpl action
      Then the fault localization gate <outcome>
      Examples:
        | type | location                                      | outcome          |
        | fix  | as a standalone line in the What section      | triggers         |
        | fix  | embedded in a prose line in the What section  | does not trigger |
        | fix  | as a standalone line outside the What section | does not trigger |
        | feat | as a standalone line in the What section      | does not trigger |

    Scenario Outline: Gated invocation emits no planning content
      Given the fault localization gate triggers
      When Engineer invokes uimpl action <flag>
      Then AI Agent does not create a `## How` section
      And AI Agent does not create any planning section
      Examples:
        | flag          |
        | without flags |
        | with `--plan` |

    Scenario: Gated instructions direct fault localization
      Given the fault localization gate triggers
      When Engineer invokes uimpl action
      Then AI Agent is instructed to localize the fault
      And AI Agent is instructed to track localization efforts in fault.md in the Change Folder

    Scenario: Existing fault.md is continued, not restarted
      Given the fault localization gate triggers
      And fault.md exists in the Change Folder
      When Engineer invokes uimpl action
      Then AI Agent is instructed to read fault.md and build on the recorded efforts rather than restart the investigation

    Scenario: Successful localization
      Given the fault localization gate triggers
      When AI Agent localizes the fault
      Then AI Agent replaces the `?` step in the What section flowchart with the concrete faulty step
      And AI Agent re-invokes uimpl with the original arguments

    Scenario: Failed localization
      Given the fault localization gate triggers
      When AI Agent cannot localize the fault
      Then AI Agent updates fault.md with the efforts taken
      And AI Agent informs the Engineer of the efforts taken
      And AI Agent stops processing
