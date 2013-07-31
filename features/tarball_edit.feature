Feature: Edit the tarball after downloading

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    archive :testrepo,
            :url => 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz' do
      FileUtils::rm Dir['test/archive*.c']
    end
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name         | testrepo       |
    | With file    | test/alias.c   |
    | Without file | test/archive.c |
