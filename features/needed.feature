Feature: a vendor module is downloaded only if needed

Scenario: already downloaded tarball
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo, :version => '0.1',
      :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run vendor command "sync"
  Then I'm on "master" branch
  And the last vendor output should match /module\s+testrepo/
  And the last vendor output should match "testrepo-0.1.tar.gz"

  When I run vendor command "sync"
  Then the last vendor output should match /module\s+testrepo/
  And the last vendor output should match /up to date\s+testrepo/
  And the last vendor output should not match "testrepo-0.1.tar.gz"
