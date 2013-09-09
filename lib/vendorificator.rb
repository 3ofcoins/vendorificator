# Require everything except the CLI.

require "vendorificator/version"

require 'vendorificator/config'
require 'vendorificator/environment'
require 'vendorificator/errors'
require 'vendorificator/commit'
require 'vendorificator/io_proxy'
require 'vendorificator/overlay'

require 'vendorificator/vendor'
require 'vendorificator/vendor/download'
require 'vendorificator/vendor/archive'
require 'vendorificator/vendor/git'
require 'vendorificator/vendor/chef_cookbook'
require 'vendorificator/vendor/tool'

require 'vendorificator/unit'
require 'vendorificator/unit/vendor'
require 'vendorificator/unit/overlay'
