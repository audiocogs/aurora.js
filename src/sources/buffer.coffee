class AV.BufferSource extends AV.EventEmitter    
    constructor: (input) ->
        # convert ArrayBuffer and typed array input to AV.Buffer
        arrayBuffer = input.buffer or input
        if arrayBuffer instanceof ArrayBuffer
            input = new AV.Buffer new Uint8Array(arrayBuffer)
            
        else if AV.isNode and Buffer.isBuffer(input)
            input = new AV.Buffer new Uint8Array(input)
            
        # Now make an AV.BufferList
        if input instanceof AV.BufferList
            @list = input
            
        else if input instanceof AV.Buffer
            @list = new AV.BufferList
            @list.append input
        
        else
            @emit 'error', 'Input must be a buffer or buffer list'
            
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