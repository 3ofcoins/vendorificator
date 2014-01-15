# Changes

## 0.5.0

 - Added overlays
 - Added fake mode
 - Tools now check specs from repo rather than copy from original
   work tree; added tool extras for files that shouldn't be committed
   to vendor branch.
 - Better error messages
 - Improved CLI syntax, verbosity levels

## 0.4.0

 - Dropped support for Ruby 1.8.7
 - Refactored internals to avoid touching user's work tree - all
   conjuring is done in a temporary shared clone, fetched and merged
   from there
 - Module metadata is stored in Git notes; new `vendor info` command
   shows it.
 - Test dependency cleanup (use up-to-date Cucumber and Minitest)
 - Support for external fetching tools with predefined shortcuts for
   Bundler and Berkshelf

## 0.3.0

 - New command `vendor push` for pushing managed branches and tags to
   remote repository
 - Nicer syntax for mixin hooks
 - Add `:tag` option for `git` submodule
 - Better stashing of local changes when syncing
 - Verbosity tweaks
 - Refactor implementation of configuration, other internal refactors
 - Improved test coverage

## 0.2.0

 - New vendor type `download` for downloading a single file
 - Support `--version` and `-h` / `--help` switches
 - New `:subdirectory` option for vendor modules
 - Support JRuby
 - Fix error when cleaning empty repository
 - Misc verbosity tweaks
 - Use MiniGit instead of Grit as Git library; other internal refactors
 - Run Cucumber tests with Aruba

## 0.1.1

 - Add `--update` option to `vendor sync` and `vendor status` to check
   whether upstream version has changed
 - It is now possible to explicitly set module's category to `nil`
 - Ruby 1.8.7 compatibility fix
 - Gem runtime/development dependency fixes
 - Initial minitest specs
 - Make Cucumber tests use Webmock

## 0.1.0

Initial release.



