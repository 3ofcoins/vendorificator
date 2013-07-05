Feature: simple file download

Scenario: just URL as name
  Given a repository with following Vendorfile:
    """ruby
    download 'http://test-assets.3ofcoins.net.s3-website-us-east-1.amazonaws.com/testrepo-0.1.tar.gz'
    """
  When I run vendor command "sync"
  Then following has been conjured:
    | Name      | testrepo-0.1.tar.gz |
  And there's a git commit note including "ea207a" in "download_checksum"
  And there's a git commit note including "20480" in "download_filesize"
  And there's a git commit note including "test-assets.3ofcoins" in "download_url"

