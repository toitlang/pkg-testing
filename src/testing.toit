import bytes
import encoding.json
import log
import core.message_manual_decoding_ show print_for_manually_decoding_

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

  start_time_ := Time.monotonic_us

  constructor:
    events.add {
      "protocolVersion":"0.1.0",
      "runnerVersion":"1.0",
      "type":"start",
      "time": (Time.monotonic_us - start_time_) / 1000
    }

  start test/Test:
    events.add {
      "test": {
        "id": test.id,
        "name": test.name,
      },
      "type":"testStart",
      "time": time_ms_
    }

  done test/Test:
    events.add {
      "testID": test.id,
      "result": "success",
      "type": "testDone",
    }

  done:
    events.add {
      "result": "success",
      "type": "done",
    }

    encoder := json.Encoder
    events.do:
      encoder.encode it
      encoder.put_byte_ '\n'
    print_on_stderr_ encoder.to_string

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
