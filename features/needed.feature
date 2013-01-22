Feature: a vendor module is downloaded only if needed

Scenario: already downloaded tarball
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run "vendor"
  Then I'm on "master" branch
  And command output includes /module\s+testrepo/
  And command output includes "testrepo-0.1.tar.gz"
  Then I run "vendor" 
  And command output includes /module\s+testrepo/
  And command output includes /up to date\s+testrepo/
  And command output does not include "testrepo-0.1.tar.gz"
