global.AV = require '../'
global.assert = require 'assert'

global.expect = (count, done) ->
  return ->
    done() if --count is 0
