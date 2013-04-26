Feature: bare 'vendor' clause

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  When I successfully run `vendor sync`
  Then the following has been conjured:
    | Name      | generated |
    | Version   | 0.23      |
    | With file | README    |
  And the file "vendor/generated/VERSION" should contain "0.23"
  And there's a git commit note including ":version: '0.23'"
