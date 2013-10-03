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
    | Name      | generated |
    | Version   | 0.23      |
    | Path      | foo      |
    | With file | README    |
  And the file "foo/README" should contain "Hello, World!"
  And branch "vendor/overlay/foo/layer/generated" exists
  And branch "vendor/generated" does not exist
  And branch "vendor/overlay/foo/merged" exists

Scenario: Overlay in repository root
  Given a repository with following Vendorfile:
    """ruby
    overlay '/' do
      vendor 'generated', :version => '0.23' do |v|
        File.open('UNIQ_README', 'w') { |f| f.puts "Hello, World!" }
      end
    end
    """
  When I run vendor command "install -v 1"
  Then the following has been conjured:
    | Name      | generated   |
    | Version   | 0.23        |
    | With file | UNIQ_README |
    | Path      | .           |
  And the file "UNIQ_README" should contain "Hello, World!"
  And branch "vendor/overlay/layer/generated" exists
  And branch "vendor/generated" does not exist
  And branch "vendor/overlay/merged" exists

Scenario: overlay with multiple sources
  Given a repository with following Vendorfile:
    """ruby
    overlay '/xyzzy' do
      vendor 'foo', :version => '0.23' do |v|
        File.open('README.foo', 'w') { |f| f.puts "Hello, World! -- foo" }
      end
      vendor 'bar', :version => '0.42' do |v|
        File.open('README.bar', 'w') { |f| f.puts "Hello, World! -- bar" }
      end
    end
    """
  When I run vendor command "install -v 1"
  Then the following has been conjured:
    | Name      | foo        |
    | Version   | 0.23       |
    | With file | README.foo |
    | Path      | xyzzy      |
  And the following has been conjured:
    | Name      | bar        |
    | Version   | 0.42       |
    | With file | README.bar |
    | Path      | xyzzy      |
  And the file "xyzzy/README.foo" should contain "Hello, World! -- foo"
  And the file "xyzzy/README.bar" should contain "Hello, World! -- bar"
  And branch "vendor/overlay/xyzzy/layer/foo" exists
  And branch "vendor/overlay/xyzzy/layer/bar" exists
  And branch "vendor/overlay/xyzzy/merged" exists
  And branch "vendor/foo" does not exist
  And branch "vendor/bar" does not exist

Scenario: Overlay ID
  Given a repository with following Vendorfile:
    """ruby
    overlay 'base', path: '/' do
      vendor 'generated', :version => '0.23' do |v|
        File.open('README', 'w') { |f| f.puts "Hello, World!" }
      end
    end
    """
  When I run vendor command "install -v 1"
  Then the following has been conjured:
    | Name      | generated |
    | Version   | 0.23      |
    | With file | README    |
    | Path      | /         |
  And the file "README" should contain "Hello, World!"
  And branch "vendor/overlay/base/layer/generated" exists
  And branch "vendor/overlay/base/merged" exists
  And branch "vendor/generated" does not exist
