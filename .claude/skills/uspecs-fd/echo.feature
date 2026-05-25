Feature: Print text with echo
  User runs echo command to print text to stdout

  Rule: Basic flow

    Scenario Outline: Print arguments
      When User runs `echo <args>`
      Then stdout is <output>
      And exit code is 0
      Examples:
        | args                      | output                               |
        | hello                     | "hello{NEWLINE}"                     |
        | hello world               | "hello world{NEWLINE}"               |
        | no\t\n escapes by default | "no\t\n escapes by default{NEWLINE}" |
        |                           | "{NEWLINE}"                          |

    Scenario: Variable expansion
      Given environment variables:
        | name | value       |
        | USER | alice       |
        | HOME | /home/alice |
      When User runs `echo $USER at $HOME`
      Then stdout is "alice at /home/alice{NEWLINE}"

  Rule: Alternative flows

    Scenario: -n suppresses the trailing newline
      When User runs `echo -n hello`
      Then stdout is "hello"

    Scenario: Unknown option is treated as literal text
      When User runs `echo --unknown`
      Then stdout is "--unknown{NEWLINE}"
      And exit code is 0

  Rule: Escape sequences

    # Recognized escape sequences are listed in echo--reqs.md#escape-sequences
    Scenario Outline: -e enables backslash escapes
      When User runs `echo -e <args>`
      Then stdout is <output>
      Examples:
        | args           | output                         |
        | "a\tb"         | "a{TAB}b{NEWLINE}"             |
        | "line1\nline2" | "line1{NEWLINE}line2{NEWLINE}" |

    Scenario: Unrecognized escape is printed literally
      When User runs `echo -e "a\zb"`
      Then stdout is "a\zb{NEWLINE}"

    Scenario: \c suppresses further output
      When User runs `echo -e "before\cafter"`
      Then stdout is "before"