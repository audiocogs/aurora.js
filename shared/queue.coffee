class Queue extends EventEmitter
    constructor: (@decoder) ->
        @readyMark = 64
        @finished = false
        @buffering = true
        
        @buffers = []
        @decoder.on 'data', @write
        @decoder.on 'end', @write
        @decoder.readChunk()
        
    write: (buffer) =>
        @buffers.push buffer if buffer
        
        if @buffering
            if @buffers.length >= @readyMark or @decoder.receivedFinalBuffer
                @buffering = false
                @emit 'ready'
            else    
                @decoder.readChunk()
            
    read: ->
        return null if @buffers.length is 0
        
        @decoder.readChunk()    
        return @buffers.shift()