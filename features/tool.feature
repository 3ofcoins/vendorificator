Feature: use a tool to download stuff

Background:
  Given a repository with following Vendorfile:
    """ruby
    # Delete Bundler's variables
    %w[RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE].each do |var|
      ENV.delete(var)
    end

    tool 'bundler',
         :path => 'cache', # Hardcoded, meh
         :specs => [ 'Gemfile', 'Gemfile.lock' ],
         :command => 'bundle package --all'
    """

@wip
Scenario: Use Gem bundler to download rubygems, and Vendorificator to vendor them
  Given I have following Gemfile:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "hello"
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name         | bundler         |
    | Path         | cache           |
    | With file    | hello-0.0.1.gem |
    | Without file | first-0.gem     |

@wip
Scenario: Bundler correctly downloads and caches dependencies
  Given I have following Gemfile:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "first"
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name         | bundler         |
    | Path         | cache           |
    | Without file | hello-0.0.1.gem |
    | With file    | first-0.gem     |
    | With file    | second-0.gem    |

@wip
Scenario: directory contents are completely replaced on re-vendoring
  Given I have following Gemfile:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "hello"
    """
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name         | bundler         |
    | Path         | cache           |
    | With file    | hello-0.0.1.gem |
    | Without file | first-0.gem     |
  When I change Gemfile to:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "first"
    """
  And I successfully run `vendor sync`
  Then following has been conjured:
    | Name         | bundler         |
    | Path         | cache           |
    | Without file | hello-0.0.1.gem |
    | With file    | first-0.gem     |
    | With file    | second-0.gem    |
