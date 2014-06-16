# make QUnit print test results to the console in Node
if not QUnit? and require?
    global.AV = require '../'
    global.QUnit = require 'qunit-cli'
            
# setup testing environment
global.assert = QUnit
global.test = QUnit.test
global.describe = (name, fn) ->
    QUnit.module name
    fn()