Feature: collaboration over a remote repository

Scenario: pulling from a remote repo that somebody has updated
  Given a repository cloned from "remote.1"
  Then a file named "vendor/example.html" should exist
  And the file "vendor/stub/VERSION" should contain "1"
  And tag "vendor/example.html/0" exists
  And tag "vendor/stub/1" exists
  And tag "vendor/stub/2" does not exist
  And branch "vendor/example.html" does not exist
  And branch "vendor/stub" does not exist

  When I run `git pull --tags`
  Then tag "vendor/example.html/0" exists
  And tag "vendor/stub/1" exists
  And tag "vendor/stub/2" does not exist
  And branch "vendor/example.html" does not exist
  And branch "vendor/stub" does not exist

  When I run vendor command "pull"
  Then tag "vendor/example.html/0" exists
  And tag "vendor/stub/1" exists
  And tag "vendor/stub/2" does not exist
  And branch "vendor/example.html" exists
  And branch "vendor/stub" exists
  And the following has been conjured:
    | Name      | example.html | stub    |
    | Version   |            0 | 1       |
    | With file |              | VERSION |

  When remote repository is updated from "remote.2"
  And I run vendor command "pull"
  Then tag "vendor/stub/2" exists
  And the file "vendor/stub/VERSION" should contain "1"
  And the following has been conjured:
    | Name      | example.html | stub    |
    | Version   |            0 | 1       |
    | With file |              | VERSION |
  And the last vendor output should match /updated\s+stub/
  And the last vendor output should match /unchanged\s+example\.html/

  When I run `git pull origin master`
  Then the file "vendor/stub/VERSION" should contain "2"
