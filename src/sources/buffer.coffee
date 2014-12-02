EventEmitter = require '../core/events'
BufferList = require '../core/bufferlist'
AVBuffer = require '../core/buffer'

class BufferSource extends EventEmitter    
    constructor: (input) ->
        # Now make an AV.BufferList
        if input instanceof BufferList
            @list = input
            
        else
            @list = new BufferList
            @list.append new AVBuffer(input)
            
        @paused = true
        
    setImmediate = global.setImmediate or (fn) ->
        global.setTimeout fn, 0
        
    clearImmediate = global.clearImmediate or (timer) ->
        global.clearTimeout timer
        
    start: ->
        @paused = false
        @_timer = setImmediate @loop
        
    loop: =>
        @emit 'progress', (@list.numBuffers - @list.availableBuffers + 1) / @list.numBuffers * 100 | 0
        @emit 'data', @list.first
        if @list.advance()
            setImmediate @loop
        else
            @emit 'end'
        
    pause: ->
        clearImmediate @_timer
        @paused = true
        
    reset: ->
        @pause()
        @list.rewind()
        
module.exports = BufferSource
