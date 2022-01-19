import testing

main:
  testing.scope:
    testing.run "failed expect": | test/testing.Test |
      test.expect 4 == 5

    testing.run "failed require": | test/testing.Test |
      test.require 4 == 5
