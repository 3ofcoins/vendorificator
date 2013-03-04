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

Scenario: Vendorificating a certain branch from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :branch => 'topic/pink'
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | ecbfa229ba5f11c05b18bcc4f7c32b8f25d63f8c |
    | With file     | README.md                                |

Scenario: Vendorificating a certain revision from a git repo
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo",
        :revision => '6ff1be'
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name          | testrepo                                 |
    | Version       | 6ff1be9c3819c93a2f41e0ddc09f252fcf154f34 |
    | With file     | alias.c                                  |
    | Without file  | test/alias.c                             |

