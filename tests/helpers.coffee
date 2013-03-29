# make QUnit print test results to the console in Node
if not QUnit? and require?
    AV = require '../node.js'
    QUnit = require 'qunit-cli'
            
# setup testing environment
assert = QUnit
test = QUnit.test
module = (name, fn) ->
    QUnit.module name
    fn()