import testing

main:
  testing.scope:
    testing.run "expect true": | test/testing.Test |
      test.expect 42 == 42

    testing.run "require true": | test/testing.Test |
      test.require 42 == 42
