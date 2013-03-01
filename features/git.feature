Feature: Git-based vendor module

Scenario: Vendorificating a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo"
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name      | testrepo                                 |
    | Version   | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file | test/alias.c                             |

Scenario: Vendorificating a subdirectory from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :subdirectory => 'test'
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file     | alias.c                                  |
    | Without file  | test/alias.c                             |

