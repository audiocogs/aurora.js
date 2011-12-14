class Decoder extends EventEmitter
    constructor: (demuxer, @format) ->
        list = new BufferList
        @stream = new Stream(list)
        @bitstream = new Bitstream(@stream)
        
        demuxer.on 'cookie', (cookie) =>
            @setCookie cookie
            
        demuxer.on 'data', (chunk, final) =>
            list.push chunk
            @emit 'available'
            
    setCookie: (cookie) ->
        return
    
    readChunk: (chunk) ->
        return
        
    seek: (position) ->
        return 'Not Implemented.'
    
    codecs = {}
    @register: (id, decoder) ->
        codecs[id] = decoder
        
    @find: (id) ->
        return codecs[id] or null