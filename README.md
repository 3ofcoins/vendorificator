# Vendorificator

> **THIS WORK IS HEAVILY IN PROGRESS** and is far from usable yet. Sorry
about that - I'm working on it. Expect first usable version in January 2013.

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

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
