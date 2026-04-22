Feature: Align Working Change Folder plan and specs with source changes
  Engineer aligns plan and specs in the Working Change Folder with source changes since the merge-base with pr_remote/default_branch

  # ## Glossary
  #
  # baseline: git merge-base of HEAD with pr_remote/default_branch
  # diff_scope: everything outside uspecs/changes/
  # Diff threshold: 100K bytes

  Rule: Core behavior

    Background:
      Given there is one Working Change Folder
      And diff size is within diff threshold

    Scenario: Core output
      When Engineer invokes usync action
      Then WCF Implementation Plan in change.md or impl.md (if exists) is updated to reflect changes in diff_scope vs baseline
      And All specifications mentioned in Implementation Plan are updated to reflect changes in diff_scope vs baseline
      And If issue.md exists, Engineer is informed of any discrepancies between issue.md and actual sources
      And Correct items or sub-items in changes.md/impl.md are never removed
      And Not more than 5 new sub-items per to-do item are added

  Rule: Large diff handling

    Background:
      Given there is one Working Change Folder
      And diff size exceeds diff threshold

    Scenario: Diff exceeds size threshold without -y option
      Given -y option is not specified
      When Engineer invokes usync action
      Then Engineer sees "Huge diff detected (<size> bytes). Do you want to proceed? 1. Yes 2. Cancel"
      And 1 causes "Diff exceeds size threshold with -y option" scenario

    Scenario: Diff exceeds size threshold with -y option
      Given -y option is specified
      When Engineer invokes usync action
      Then Core output is produced


  Rule: Edge cases

    # Change Folder validations
    Scenario: Exactly one Working Change Folder

    # Git validations
    Scenario: Project inside Git working tree

    # Git validations
    Scenario Outline: Git working tree is clean
