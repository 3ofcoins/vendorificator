Feature: bare 'vendor' clause

Background:
  Given a repository with following Vendorfile:
    """
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """

Scenario:
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/generated" exists
  And tag "vendor/generated/0.23" exists
  And file "vendor/generated/README" exists
  And file "vendor/generated/VERSION" reads "0.23"
