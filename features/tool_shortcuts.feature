Feature: `rubygems_bundler` and `chef_berkshelf` shortcuts for tools

Scenario: rubygems_bundler
  Given a repository with following Vendorfile:
    """ruby
    # Delete Bundler's variables
    %w[RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE].each do |var|
      ENV.delete(var)
    end
    rubygems_bundler
    """
  And following Gemfile:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "hello"
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name         | rubygems        |
    | Path         | cache           |
    | With file    | hello-0.0.1.gem |
    | Without file | first-0.gem     |
    | Branch       | vendor/rubygems |

@berkshelf
Scenario: chef_berkshelf
  Given a repository with following Vendorfile:
    """ruby
    chef_berkshelf
    """
  And a file named "Berksfile" with:
    """ruby
    site :opscode
    cookbook 'build-essential'
    """
  And I successfully run `berks install`
  And I successfully run `git add Berksfile Berksfile.lock`
  And I successfully run `git commit -m Berksfile`
  When I run vendor command "install"
  Then following has been conjured:
    | Name         | cookbooks                   |
    | With file    | build-essential/metadata.rb |
    | Branch       | vendor/cookbooks            |

