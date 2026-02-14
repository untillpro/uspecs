Feature: Branch protection
  Developer pushes commits to branches with validation rules to prevent direct pushes to protected branches

  Scenario Outline: Developer pushes to branch
    Given branch "<branch>" with protection status "<protected>"
    When Developer attempts to push commits with message "<commit_message>" to "<branch>"
    Then push should <result>

    Examples:
      | branch         | protected | commit_message  | result                                                   |
      | main           | true      | fix bug         | be rejected with "Direct pushes to main are not allowed" |
      | main           | true      | urgent fix      | be rejected with "Direct pushes to main are not allowed" |
      | main           | true      | superurgent fix | succeed                                                  |
      | feature/login  | false     | add feature     | succeed                                                  |
      | bugfix/fix-123 | false     | fix issue       | succeed                                                  |

