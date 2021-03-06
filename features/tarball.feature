Feature: simple tarball module

Scenario: just URL as name
  Given a repository with following Vendorfile:
    """ruby
    archive 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo-0.1        |
    | Version   | testrepo-0.1.tar.gz |
    | With file | test/alias.c        |

Scenario: URL as keyword
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo            |
    | Version   | testrepo-0.1.tar.gz |
    | With file | test/alias.c        |

Scenario: Version & checksum
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz',
      :version => '0.1',
      :checksum => 'ea207a896f929ffb3a1dfe128332d6134a18edab7c01b97bfb2b1c7eacebe0cb'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo     |
    | Version   | 0.1          |
    | With file | test/alias.c |
  And there's a git commit note including "ea207a" in "archive_checksum"
  And there's a git commit note including "20480" in "archive_filesize"
  And there's a git commit note including "test-assets.3ofcoins" in "archive_url"

Scenario: Wrong checksum
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz',
      :version => '0.1',
      :checksum => 'incorrect'
    """
  When I run `vendor install`
  Then it should fail
  And following has not been conjured:
    | Name      | testrepo     |
    | With file | test/alias.c |

Scenario: Tarball without a root directory
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1-noroot.tar.gz'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo        |
    | With file | test/alias.c    |
