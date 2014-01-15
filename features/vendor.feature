Feature: bare 'vendor' clause

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    annotate 'foo', 'bar'
    vendor 'generated', :version => '0.23', :annotate => 'by Przemo' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  When I run vendor command "install -v 1"
  Then the following has been conjured:
    | Name      | generated        |
    | Version   | 0.23             |
    | With file | README           |
  And the file "vendor/generated/VERSION" should contain "0.23"
  And there's a git commit note including "bar" in "foo"
  And there's a git commit note including "by Przemo" in "module_annotations"
  And tag "vendor/generated/0.23" exists
