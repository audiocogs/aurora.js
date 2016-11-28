EventEmitter = require './core/events'

class Queue extends EventEmitter
    constructor: (@asset) ->
        @bufferSize = 0
        @readyMark = 22464
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
        @bufferSize += buffer.length
        
        if @buffering
            @asset.decodePacket()
            if @bufferSize >= @readyMark or @ended
                @buffering = false
                @emit 'ready'
            
    read: ->
        return null if @buffers.length is 0
        unless @buffering
            @asset.decodePacket()
        @bufferSize -= @buffers[0].length
        if @bufferSize <= 0
            @buffering = true
            @emit 'buffering'

        return @buffers.shift()
        
    reset: ->
        @buffers.length = 0
        @buffering = true
        @asset.decodePacket()
        
module.exports = Queue
