# Vendorificator

> **THIS PROGRAM IS STILL IN BETA**, use on your own risk!

## About

[Vendor everything](http://errtheblog.com/posts/50-vendor-everything). Keep your own copies of upstream dependencies that your project needs somewhere close to your project, best in the same source control repository. But how to do it, and keep track of all the upstream modules, their origin and license, upgrades, local changes, and so on? It's what Vendorificator helps you with.

Vendorificator keeps the upstream dependencies in your Git repository, using Git itself to help you with tracking all the updates, upgrades, and changes. You specify how to get the dependency in a config file written in plain Ruby, called `Vendorfile` (you don't need to know much Ruby to be able to write it - but you can use all Ruby you know if you want to!). Then you run `vendorify` command, and everything is done by magic:

 * All of defined dependencies are downloaded to specified directories of your repository;
 * Every dependency has its own pristine branch, to make it possible to cleanly upgrade the third-party module even if you have introduced your local changes;
 * After every download and change of the pristine branch, the resulting commit is annotated with the details: timestamp, origin (including version, download checksum, and/or Git SHA-1), and any comments you might need to keep;
 * You can easily upgrade the dependencies, change their origin for subsequent updates (projects do move around), add or remove them, etc;
 * At any moment, you can get a list of third-party modules you use with its origin, version, timestamp, and list of your own patches;
 * When you upgrade the dependency, you can easily review differences introduced to pristine copy by yourself, difference between old and new version, and merge the new version as you'd merge any regular Git branch.

All kinds of external dependencies you need - be it Ruby, Python, JavaScript, shell scripts, CSS libraries, Chef cookbooks, or any other modules you may need, are specified in a single place, and managed with a single tool.

## Installation

Add this line to your application's Gemfile:

    gem 'vendorificator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vendorificator

## Usage

Vendorificator is a command-line tool. The command is called `vendor`
(`bundle exec vendor` if you use Bundler). It accepts multiple
subcommands.

Run `vendor` to see list of subcommands. Run `vendor help _command_`
to get detailed description of a command.

There is a lightning talk presentation/demo slide deck online at
https://speakerdeck.com/mpasternacki/vendorificator

### Commands

Most important commands are listed here; use `vendor help` for more
detail.

 * `vendor sync` will update all vendor modules that need updating
 * `vendor status` will list all the modules and their status
 * `vendor pull` will pull all vendor branches, tags, and notes from
   a Git remote
 * `vendor push` will push all vendor branches, tags, and notes to
   a Git remote
 * `vendor diff` will show the differences between vendor module's
   pristine branch and curent work tree
 * `vendor log` will show a `git log` of all changes made to a particular
   vendor module's files that are not in module's pristine branch

## Configuration

Vendorificator reads its configuration from a Ruby file named
`Vendorfile` (or `config/vendor.rb`). If the file does not exist in
the current directory, it looks for it in parent directories until it
gets to the git repository's root. All files Vendorificator creates
are rooted in directory containing the `Vendorfile` (or the directory
containing `config` directory with `vendor.rb` file in it).

Vendorfile is a Ruby file containing configuration settings and
description of upstream vendor modules. It may also contain any custom
Ruby code if needed.

### Settings

 * `basedir "subpath"` -- directory below work root where
   Vendorificator will download modules. Defaults to `"vendor"`.
 * `branch_prefix "prefix"` -- prefix for name of Git
   branches. Defaults to `"vendor"`, which means all branches created
   by Vendorificator start with `"vendor/"`.
 * `remotes ['remote1', 'remote2', ...]` -- list of Git remotes that
   `vendor pull` will use as default. Defaults to `['origin']`.
 * `chef_cookbook_ignore_dependencies ['cookbook1', 'cookbook2', ...]`
   -- default value for `:ignore_dependencies` argument of
 `chef_cookbook` modules.

### Modules

A **vendor module** is a single piece of upstream code managed by
Vendorificator. It is a basic building block. A vendor module is
declared by calling one of a couple functions that define them.

#### vendor

Vendor is most general of those. You call it like this:

```ruby
vendor 'name', :option => 'value' do
  # here in the block you code what needs to be done
  # to get ("conjure") the module. You're already in
  # the right directory, branch, etc, and what you add to the
  # current directory will be committed and tagged.
end
```

It takes following options:

 * `:version` - the version of module. If the module's contents should
   change, increase the version, so that Vendorificator knows it needs
   to re-create the module.
 * `:category` - module's *category* is subdirectory of the basedir
   where module's directory will be created. For example, `vendor
   "foo"` will go to `vendor/foo` by default, but `vendor "foo",
   :category => :widgets` will go to `vendor/widgets/foo`. It is also
   added in a similar way to module's branch name, tag names, etc.
 * `:path` - lets you specify subdirectory in which the module will be
   downloaded

All other upstream modules take these options, and can be given a
block to postprocess their content (e.g. if a tarball includes a
`.git` file/directory that confuses Git, you can remove it in a
block).

Example:

```ruby
vendor 'generated', :version => '0.23' do |v|
  File.open('README', 'w') { |f| f.puts "Hello, World!" }
  File.open('VERSION', 'w') { |f| f.puts v.version }
end
```

#### download

Downloads a single file:

```ruby
download 'socks.el', :url => 'http://cvs.savannah.gnu.org/viewvc/*checkout*/w3/lisp/socks.el?root=w3&revision=HEAD'
download 'http://mumble.net/~campbell/emacs/paredit.el'
```

#### archive

Archive takes a tar.gz, tar.bz2, or zip file, downloads it, and
unpacks it as contents of the module. It takes same options as
`vendor`, plus:

 * `:url` -- address from which to download the archive. If not given,
   module's name will be used as URL, and its basename as module's
   name (e.g. `archive
   "http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz"` will be named
   `"hello-2.8"` and downloaded from the URL).
 * `:filename` -- a filename to download. Useful if URL doesn't
   specify this nwell.
 * `:type` -- `:targz`, `:tarbz2`, or `:zip`
 * `:unpack` -- a command that will be used to unpack the file
 * `:basename` -- defaults to basename of `filename`, will be used as
   directory name
 * `:no_strip_root` -- by default, if archive consists of a single
   directory, Vendorificator will strip it. Setting this to true
   disables this behaviour.
 * `:checksum` -- if set to SHA256 checksum of the file, it will be
   checked on download.

Archive's `:version` defaults to file name.

Example:

```ruby
    archive :hello,
      :url => 'http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz',
      :version => '2.8',
      :checksum => 'e6b77f81f7cf7daefad4a9f5b65de6cae9c3f13b8cfbaea8cb53bb5ea5460d73'
```

#### git

Downloads snapshot of a Git repository. Takes the same options as
`vendor`, plus:

 * `:repository` -- address of the repository. Defaults to name (and
   sets name to its basename then), just like `:url` for `archive`
   (e.g. `git "git://github.com/github/testrepo.git"` will be cloned
   from that repository, and named `testrepo`).
 * `:branch`, `:revision`, `:tag` -- what to check out when repository
   is cloned.

Git module's `:version` defaults to the `:tag` if given, or the
conjured revision otherwise.

Example:

```ruby
git 'git://github.com/mpasternacki/nagios.git',
    :branch => 'COOK-1997',
    :category => :cookbooks,
    :version => '0.20130124.2'
```

#### chef_cookbook

Downloads an Opscode Chef cookbook from http://community.opscode.com/
website (same thing that `knife cookbook site install` does). It
resolves dependencies -- all needed modules will be downloaded by
default. Its category defaults to `:cookbooks`. It may take the same
arguments as `archive` (but the name and possibly version is almost
always enough), plus:

 * `:ignore_dependencies` -- if true, ignore dependencies
   completely. If an array, don't download dependencies that are in
   the array. Default for that is `chef_cookbook_ignore_dependencies`
   setting.

Examples:

```ruby
chef_cookbook 'apt'
chef_cookbook 'memcached'
chef_cookbook 'chef-server', :ignore_dependences => true
```

```ruby
chef_cookbook_ignore_dependencies ['runit']
chef_cookbook 'memcached'
```

```ruby
chef_cookbook 'memcached', ignore_dependencies => ['runit']
```

If you get Chef cookbooks from Git or anywhere else than Opscode's
community website, you can still use dependency resolution by using a :hooks
option to add it:

```ruby
git 'git://github.com/user/cookbook.git',
  :category => :cookbooks,
  :hooks => 'ChefCookbookDependencies'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
