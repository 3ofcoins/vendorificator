Feature: Overlay usage

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    overlay '/foo' do
      vendor 'generated', :version => '0.23' do |v|
        File.open('README', 'w') { |f| f.puts "Hello, World!" }
      end
    end
    """
  When I run vendor command "install -v 1"
  Then the following has been conjured:
    | Name      | generated                          |
    | Version   | 0.23                               |
    | With file | README                             |
    | Path      | foo/generated                      |
  And the file "vendor/foo/generated/README" should contain "Hello, World!"
  And branch "vendor/overlay/foo/layer/generated" exists
  And branch "vendor/generated" does not exist
  And branch "vendor/overlay/foo/merged" exists

