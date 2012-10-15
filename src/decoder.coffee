class AV.Decoder extends AV.EventEmitter
    constructor: (demuxer, @format) ->
        list = new AV.BufferList
        @stream = new AV.Stream(list)
        @bitstream = new AV.Bitstream(@stream)
        @receivedFinalBuffer = false
        
        demuxer.on 'cookie', (cookie) =>
            @setCookie cookie
            
        demuxer.on 'data', (chunk, final) =>
            @receivedFinalBuffer = !!final
            list.push chunk
            setTimeout =>
                @emit 'available'
            , 0
            
        @init()
            
    init: ->
        return
            
    setCookie: (cookie) ->
        return
    
    readChunk: ->
        return
        
    seek: (position) ->
        return 'Not Implemented.'
    
    codecs = {}
    @register: (id, decoder) ->
        codecs[id] = decoder
        
    @find: (id) ->
        return codecs[id] or null