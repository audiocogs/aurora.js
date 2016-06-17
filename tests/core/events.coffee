AV = require '../../'
assert = require 'assert'

describe 'core/events', ->    
    it 'on', ->
        emitter = new AV.EventEmitter
        times = 0
        
        emitter.on 'test', (a, b) ->
            times++
            assert.equal 'a', a
            assert.equal 'b', b
            
        emitter.emit 'test', 'a', 'b'
        emitter.emit 'test', 'a', 'b'
        assert.equal 2, times
        
    it 'off', ->
        emitter = new AV.EventEmitter
        times = 0
        
        emitter.on 'test', fn = ->
            times++
            
        emitter.emit 'test'
        emitter.off 'test', fn
        emitter.emit 'test'
        
        assert.equal 1, times
        
    it 'once', ->
        emitter = new AV.EventEmitter
        times = 0
        
        emitter.once 'test', ->
            times++
            
        emitter.emit 'test'
        emitter.emit 'test'
        emitter.emit 'test'
        
        assert.equal 1, times
        
    it 'emit', ->
        emitter = new AV.EventEmitter
        times = 0
        
        emitter.on 'test', ->
            times++
            
        emitter.on 'test', ->
            times++
            
        emitter.emit 'test'
        assert.equal 2, times