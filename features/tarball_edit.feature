Feature: Edit the tarball after downloading

Scenario:
  Given a repository with following Vendorfile:
    """
    archive :testrepo,
            :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz' do
      FileUtils::rm Dir['test/archive*.c']
    end
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/testrepo" exists
  And tag "vendor/testrepo/testrepo-0.1.tar.gz" exists
  And file "vendor/testrepo/test/alias.c" exists
  And file "vendor/testrepo/test/archive.c" does not exist
