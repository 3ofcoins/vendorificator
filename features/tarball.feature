Feature: simple tarball module

Scenario: just URL as name
  Given a repository with following Vendorfile:
    """
    archive 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo-0.1" exists
  And tag "vendor/testrepo-0.1/testrepo-0.1.tar.gz" exists
  And file "vendor/testrepo-0.1/test/alias.c" exists

Scenario: URL as keyword
  Given a repository with following Vendorfile:
    """
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo" exists
  And tag "vendor/testrepo/testrepo-0.1.tar.gz" exists
  And file "vendor/testrepo/test/alias.c" exists

Scenario: Version & checksum
  Given a repository with following Vendorfile:
    """
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz',
      :version => '0.1',
      :checksum => 'ea207a896f929ffb3a1dfe128332d6134a18edab7c01b97bfb2b1c7eacebe0cb'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo" exists
  And tag "vendor/testrepo/0.1" exists
  And file "vendor/testrepo/test/alias.c" exists

Scenario: Wrong checksum
  Given a repository with following Vendorfile:
    """
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz',
      :version => '0.1',
      :checksum => 'incorrect'
    """
  When I try to run "vendorify"
  Then the command has failed
  And I'm on "master" branch
  And branch "vendor/testrepo" does not exist
  And tag "vendor/testrepo/0.1" does not exist
  And file "vendor/testrepo/test/alias.c" does not exist

Scenario: Tarball without a root directory
  Given a repository with following Vendorfile:
    """
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1-noroot.tar.gz'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo" exists
  And tag "vendor/testrepo/testrepo-0.1-noroot.tar.gz" exists
  And file "vendor/testrepo/test/alias.c" exists
