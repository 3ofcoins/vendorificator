Feature: use a tool to download stuff

Background:
  Given a repository with following Vendorfile:
    """ruby
    # Delete Bundler's variables
    %w[RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE].each do |var|
      ENV.delete(var)
    end

    tool 'bundler',
         :path => 'vendor/cache',
         :specs => [ 'Gemfile', 'Gemfile.lock' ],
         :command => 'bundle package --all'
    """
  And a file named "Gemfile" with:
    """ruby
    source "file://#{ENV['FIXTURES_DIR']}/rubygems"
    gem "hello"
    """
  And I successfully run `bundle` with bundler disabled
  And I successfully run `git add Gemfile Gemfile.lock`
  And I successfully run `git commit -m Bundler`

@wip
@announce
Scenario: Use Gem bundler to download rubygems, and Vendorificator to vendor them
  When I successfully run `vendor sync`
  Then following has been conjured:
    | Name      | bundler         |
    | With file | hello-0.0.1.gem |
