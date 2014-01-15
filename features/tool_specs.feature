Feature: tool's specs can be specified in a flexible way

Scenario Outline:
  Given a repository with following Vendorfile:
    """ruby
    tool 'find', :specs => <specs>,
         :command => "mkdir -p vendor/find ; find . -type f -not -name found -a -not -path './.git/*' > vendor/find/found"
    """
  Given an empty file named "<file1>"
  Given an empty file named "<file2>"
  Given an empty file named "<file3>"
  Given I run `git add .`
  Given I run `git commit -m add`
  Given an empty file named "untracked.txt"
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | find        |
    | Path      | vendor/find |
    | With file | found       |
  And the file "vendor/find/found" should match <matches>
  And the file "vendor/find/found" should not match <doesnt_match>

  Examples:
    | specs              | file1   | file2       | file3           | matches    | doesnt_match     |
    | '*.txt'            | foo.txt | bar.txt     | baz.py          | /foo\.txt/ | /baz\.py/        |
    | '*.txt'            | foo.txt | bar.txt     | baz.py          | /bar\.txt/ | /baz\.py/        |
    | '*.txt'            | foo.txt | bar.txt     | baz.py          | /bar\.txt/ | /untracked\.txt/ |
    | ['*.txt', '*.py' ] | foo.txt | bar.py      | baz.rb          | /foo\.txt/ | /baz\.rb/        |
    | ['*.txt', '*.py' ] | foo.txt | bar.py      | baz.rb          | /bar\.py/  | /baz\.rb/        |
    | '**/*.txt'         | foo.txt | foo/bar.txt | foo/bar/baz.txt | /foo\.txt/ | /xxx/            |
    | '**/*.txt'         | foo.txt | foo/bar.txt | foo/bar/baz.txt | /bar\.txt/ | /xxx/            |
    | '**/*.txt'         | foo.txt | foo/bar.txt | foo/bar/baz.txt | /baz\.txt/ | /xxx/            |
