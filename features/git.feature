Feature: Git-based vendor module

Scenario:
  Given a repository with following Vendorfile:
    """
    git 'git://github.com/github/testrepo.git'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo" exists
  And tag "vendor/testrepo/10e9ac58c77bc229d8c59a5b4eb7422916453148" exists
  And file "vendor/testrepo/test/alias.c" exists
