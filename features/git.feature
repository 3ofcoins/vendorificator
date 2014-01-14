Feature: Git-based vendor module

Scenario: Vendorificating a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo"
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo                                 |
    | Version   | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file | test/alias.c                             |
  And there's a git log message including "at revision 10e9ac58c77bc229d8c59a5b4eb7422916453148"
  And there's a git commit note including "10e9ac" in "git_revision"

Scenario: Vendorificating a subdirectory from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :subdirectory => 'test'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file     | alias.c                                  |
    | Without file  | test/alias.c                             |
  And there's a git log message including "at revision 10e9ac58c77bc229d8c59a5b4eb7422916453148"

Scenario: Vendorificating a certain branch from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :branch => 'topic/pink'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | ecbfa229ba5f11c05b18bcc4f7c32b8f25d63f8c |
    | With file     | README.md                                |
  And there's a git log message including "at revision ecbfa229ba5f11c05b18bcc4f7c32b8f25d63f8c"
  And there's a git commit note including "ecbfa2" in "git_revision"

Scenario: Vendorificating a certain tag from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :tag => 'email-v0'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name         | testrepo        |
    | Version      | email-v0        |
    | Without file | README.md       |
    | With file    | test/alias.c    |
  And there's a git log message including "at revision f81247bde4ef7a1c7d280140cc0bcf0b8221a51f"
  And there's a git commit note including "f81247" in "git_revision"

Scenario: Vendorificating a certain revision from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :revision => '6ff1be'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | 6ff1be9c3819c93a2f41e0ddc09f252fcf154f34 |
    | With file     | alias.c                                  |
    | Without file  | test/alias.c                             |
  And there's a git log message including "at revision 6ff1be9c3819c93a2f41e0ddc09f252fcf154f34"
  And there's a git commit note including "6ff1be" in "git_revision"
