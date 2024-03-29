import bytes
import encoding.json
import log

logger/log.Logger := log.default.with_name "testing"

current_scope_/Scope? := null

scope [block]:
  current_scope_ = Scope
  block.call current_scope_
  current_scope_.done
  current_scope_ = null

class Scope:
  tests/List ::= []
  events/List ::= []
  group_id_ ::= Test.next_test_id_++

  start_time_ := Time.monotonic_us

  constructor:
    event_ "start" {
      "protocolVersion": "0.1.0",
      "runnerVersion": null,
    }
    event_ "allSuites" {
      "count": 1,
    }
    event_ "suite" {
      "suite": {
        "id": 0,
        "platform": null,
        "path": "toit.run"
      },
    }
    event_ "group" {
      "group":{
        "id": group_id_,
        "suiteID": 0,
        "parentID": null,
        "name": null,
        "metadata": {
          "skip": false,
          "skipReason": null
        },
      },
    }

  start test/Test:
    event_ "testStart" {
      "test": {
        "id": test.id,
        "name": test.name,
        "groupIDs": [group_id_],
        "suiteID": 0,
      }
    }

  done test/Test:
    event_ "testDone" {
      "testID": test.id,
      "result": "success",
      "hidden": false,
      "skipped": false,
    }

  done:
    event_ "done" {
      "result": "success",
      "success": true,
    }

    events.do:
      print_on_stderr_
        json.stringify it

  event_ type/string args/Map:
    args["type"] = type
    args["time"] = time_ms_
    events.add args

  time_ms_ -> int: return (Time.monotonic_us - start_time_) / 1000

run name/string [block]:
  test := Test name
  test.run block

class Test:
  static next_test_id_/int := 1

  name/string
  id/int ::= next_test_id_++
  logger_/log.Logger
  expects_/List ::= []

  constructor .name --logger=logger:
    logger_ = logger.with_tag "name" name

  run [block]:
    logger_.info "running test"
    current_scope_.start this
    error := catch --trace:
        block.call this
    current_scope_.done this
    if error:
      // Give time to print trace.
      sleep --ms=50
      logger_.error "test failed" --tags={"error": error}
    logger_.info "done running test"
    print expects_

  expect value/bool:
    if not value:
      logger_.warn "failed" --tags={"expected": true, "value": value}
      expects_.add "failed"

  require value/bool:
    if not value:
      throw "failed, expected 'true', was '$value'"
