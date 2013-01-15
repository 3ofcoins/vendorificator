# Matching (#{PATTERN}) will match "foo" or /foo/, and return a
# regular expression. With quotes, the expression will be escaped.

PATTERN = /[\"\/](?:\\.|[^\"\/\\])*[\"\/]/

Transform /^\/((?:\\.|[^\/\\])*)\/$/ do |rx|
  Regexp.new(rx)
end

Transform /^\"((?:\\.|[^\"\\])*)\"$/ do |str|
  Regexp.new(Regexp.quote(str))
end
