# make QUnit print test results to the console in Node
if not QUnit? and require?
    AV = require '../node.js'
    QUnit = require './qunit/qunit.js'
    require 'colors'
    
    # setup QUnit callbacks to print test results for Node
    do ->
        QUnit.config.autorun = false
        errors = []
        
        # print the name of each module
        QUnit.moduleStart (details) ->
            console.log '\n' + details.name.bold.blue
            
        # when an individual assertion fails, add it to the list of errors to display
        QUnit.log (details) ->
            if not details.result
                errors.push details
            
        # when a test ends, print success/failure and any errors
        QUnit.testDone (details) ->
            if details.failed is 0
                console.log ('  ✔ ' + details.name).green
            else
                console.log ('  ✖ ' + details.name).red
                for error in errors
                    if error.message
                        console.log '    ' + error.message.red
                
                    if error.actual isnt undefined
                        console.log ('    ' + error.actual + ' != ' + error.expected).red
                
                errors.length = 0
            
        # when all of the tests are done, print summary
        QUnit.done (details) ->
            console.log ('\nTests completed in ' + details.runtime + ' milliseconds.').grey
            msg = details.passed + ' tests of ' + details.total + ' passed'
        
            if details.failed > 0
                console.log (msg + ', ' + details.failed + ' failed.').red.bold
            else
                console.log (msg + '.').green.bold
            
# setup testing environment
assert = QUnit
test = QUnit.test
module = (name, fn) ->
    QUnit.module name
    fn()