Feature: smoke test of the test suite
  In order to trust my tests,
  As the developer of Vendorificator,
  I want to make sure that test environment itself does not emit smoke.

  Scenario: The default environment
    Given a repository with following Vendorfile:
      """
      """
    Then a file named "README" should exist
    And a 0 byte file named "Vendorfile" should exist
    And git repository is clean
    And git history has 1 commit
    And I'm on "master" branch
    And no other branch exists

