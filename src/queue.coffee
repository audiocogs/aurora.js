EventEmitter = require './core/events'

class Queue extends EventEmitter
    constructor: (@asset) ->
        @readyMark = 64
        @finished = false
        @buffering = true
        @ended = false
        
        @buffers = []
        @asset.on 'data', @write
        @asset.on 'end', =>
            @ended = true
            
        @asset.decodePacket()
        
    write: (buffer) =>
        @buffers.push buffer if buffer
        
        if @buffering
            if @buffers.length >= @readyMark or @ended
                @buffering = false
                @emit 'ready'
            else    
                @asset.decodePacket()
            
    read: ->
        return null if @buffers.length is 0
        
        @asset.decodePacket()
        return @buffers.shift()
        
    reset: ->
        @buffers.length = 0
        @buffering = true
        @asset.decodePacket()
        
module.exports = Queue
