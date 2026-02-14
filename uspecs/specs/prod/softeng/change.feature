Feature: Create change request
  Engineer asks AI Agent to create change request

  Scenario: Create change request without issue reference
    When Engineer asks AI Agent to create change request without issue reference
    Then Active Change Folder is created with Change File
    And Change File follows Change File Template 1
    And Frontmatter does not have issue_url value

  Scenario Outline: Create change request with issue reference
    Given AI Agent <ability> to fetch issue content from the referenced issue URL
    When Engineer asks AI Agent to create change request with issue reference
    Then Active Change Folder is created with Change File
    And Change File follows Change File Template 1
    And Frontmatter has issue_url value set to the referenced issue URL
    And Issue File <issue-file-created-and-contains> the fetched issue contents in markdown format
    And Change File <references> Issue File in the Why section
    Examples:
      | ability                        | references                    | issue-file-created-and-contains |
      | has ability to fetch content   | references Issue File         | contains fetched issue content  |
      | does not have ability to fetch | does not reference Issue File | is not created                  |

  Scenario Outline: Create change request with --branch option
    When Engineer asks AI Agent to create change request with --branch option
    Then Active Change Folder is created with Change File
    And Change File follows Change File Template 1
    And Git branch is created with name following branch naming rules
    And Branch creation <result> <reason>
    Examples:
      | result   | reason                                    |
      | succeeds | when git repository exists                |
      | fails    | when git repository does not exist        |
      | fails    | when branch with same name already exists |
