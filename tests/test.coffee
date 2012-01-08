#
# A simple unit testing framework
# Create modules and test cases using the assert and deepEqual functions
# then run all the tests with Test.run() and look in your JS console!
#

class Test
    constructor: ->
        @module = "unknown"
        @setup = ->
        @teardown = ->
        @tests = {}
        @currentTest = null
        @assertTimes = 0
        @testPassed = true
        
    test: (name, fn) ->
        @tests[name] = fn
        
    assert: (condition) ->
        if not condition
            console.error(@currentTest + '[' + @assertTimes + '] failed.')
            @testPassed = false
            
        @assertTimes++
        
    deepEqual: (actual, expected) ->
        @assert _deepEqual(actual, expected)
    
    # From Node.js, thanks!    
    _deepEqual = (actual, expected) ->
        if actual is expected
            return true
            
        else if isNaN(actual) and isNaN(expected)
            return true
            
        else if actual instanceof Date and expected instanceof Date
            return actual.getTime() is expected.getTime()
            
        else if typeof actual isnt 'object' and typeof expected isnt 'object'
            return actual == expected
            
        else
            if not actual? or not expected?
                return false
                
            if actual.prototype isnt expected.prototype
                return false
            
            try
                ka = Object.keys(actual)
                kb = Object.keys(expected)
            catch e # happens when one is a string literal and the other isn't
                return false
            
            if ka.length isnt kb.length
                return false
                
            # test keys
            ka.sort()
            kb.sort()
            
            for key, i in ka
                return false if key isnt kb[i]
            
            # test values
            for key in ka
                return false if not _deepEqual(actual[key], expected[key])
                
            return true
        
    run: ->
        @setup()
        
        results = {}
        for name, test of @tests
            @testPassed = true
            @assertTimes = 0
            @currentTest = name
            
            test.call(this)
            results[name] = @testPassed
        
        @currentTest = null
        @assertTimes = 0
        
        @teardown()
        return results
    
    Test.tests = {}
    Test.module = (module, fn) ->
        test = new Test(module)
        Test.tests[module] = test
        fn.call(test)
        
    Test.run = ->
        results = {}
        for module, test of Test.tests
            results[module] = test.run()
            
            passed = true
            for name, result of results[module]
                passed = false if not result
             
            if not passed        
                console.error('Module "' + module + '" failed.')
            else
                console.log('Module "' + module + '" passed!' )
                
        return results