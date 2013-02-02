Feature: bare 'vendor' clause

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  When I run "vendor sync"
  Then the following has been conjured:
    | Name      | generated |
    | Version   | 0.23      |
    | With file | README    |
  And file "vendor/generated/VERSION" reads "0.23"
