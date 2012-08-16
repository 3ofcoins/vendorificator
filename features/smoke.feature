Feature: smoke test of the test suite
  In order to trust my tests,
  As the developer of Vendorificator,
  I want to make sure that test environment itself does not emit smoke.

  Scenario: The default environment
    Given nothing in particular
    When nothing happens
    Then the README file exists
    And git repository is clean
    And git history has one commit
    And I'm on "master" branch
    And no other branch exists
    
