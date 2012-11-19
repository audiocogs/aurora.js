class AV.Decoder extends AV.EventEmitter
    constructor: (@demuxer, @format) ->
        list = new AV.BufferList
        @stream = new AV.Stream(list)
        @bitstream = new AV.Bitstream(@stream)
        
        @receivedFinalBuffer = false
        @waiting = false
        
        @demuxer.on 'cookie', (cookie) =>
            try
                @setCookie cookie
            catch error
                @emit 'error', error
            
        @demuxer.on 'data', (chunk) =>
            list.append chunk
            @decode() if @waiting
            
        @demuxer.on 'end', =>
            @receivedFinalBuffer = true
            @decode() if @waiting
            
        @init()
            
    init: ->
        return
            
    setCookie: (cookie) ->
        return
    
    readChunk: ->
        return
        
    decode: ->
        @waiting = false
        offset = @bitstream.offset()
        
        try
            packet = @readChunk()
        catch error
            if error not instanceof AV.UnderflowError
                @emit 'error', error
                return false
            
        # if a packet was successfully read, emit it
        if packet
            @emit 'data', packet
            return true
            
        # if we haven't reached the end, jump back and try again when we have more data
        else if not @receivedFinalBuffer
            @bitstream.seek offset
            @waiting = true
            
        # otherwise we've reached the end
        else
            @emit 'end'
            
        return false
        
    seek: (timestamp) ->
        # use the demuxer to get a seek point
        seekPoint = @demuxer.seek(timestamp)
        @stream.seek(seekPoint.offset)
        return seekPoint.timestamp
    
    codecs = {}
    @register: (id, decoder) ->
        codecs[id] = decoder
        
    @find: (id) ->
        return codecs[id] or null