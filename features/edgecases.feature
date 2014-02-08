Feature: weird edge cases

Scenario: module with a .gitignore file
  Given a repository with following Vendorfile:
    """ruby
    vendor 'ignore', :version => 1 do
      File.open('.gitignore', 'w') { |f| f.puts 'ignored.txt' }
    end
    """
  When I run vendor command "install"
  Then the following has been conjured:
    | Name      | ignore     |
    | With file | .gitignore |

  When I write to "vendor/ignore/ignored.txt" with:
    """
    whatever
    """
  Then git repository is clean

  When I change Vendorfile to:
    """ruby
    vendor 'ignore', :version => 2 do
      File.open('files.txt', 'w')  { |f| f.puts Dir.entries('.').join("\n") }
      File.open('.gitignore', 'w') { |f| f.puts 'ignored.txt' }
    end
    """
  And I run vendor command "install"
  Then the file "vendor/ignore/files.txt" should not contain "ignored.txt"
  And the file "vendor/ignore/ignored.txt" should contain exactly:
    """
    whatever
    """
  And git repository is clean

Scenario: Git overlay in root directory
  Given a repository with following Vendorfile:
    """ruby
    overlay '/' do
      git "file://#{ENV['FIXTURES_DIR']}/git/testrepo"
    end
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | testrepo                                 |
    | Branch    | vendor/overlay/layer/testrepo            |
    | Version   | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file | test/alias.c                             |
    | Path      | .                                        |

Scenario: a new version of vendor module is same as previous
  Given a repository with following Vendorfile:
    """ruby
    vendor 'hello', :version => 1 do
      File.write('README', 'Hello, World!')
    end
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | hello  |
    | Version   | 1      |
    | With file | README |
  When I change Vendorfile to:
    """ruby
    vendor 'hello', :version => 2 do
      File.write('README', 'Hello, World!')
    end
    """
  And I run vendor command "update"
  Then following has been conjured:
    | Name      | hello  |
    | Version   | 2      |
    | With file | README |
  
