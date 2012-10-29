class AV.Demuxer extends AV.EventEmitter
    @probe: (buffer) ->
        return false
    
    constructor: (source, chunk) ->
        list = new AV.BufferList
        list.append chunk
        @stream = new AV.Stream(list)
        
        received = false
        source.on 'data', (chunk) =>
            received = true
            list.append chunk
            @readChunk chunk
            
        source.on 'error', (err) =>
            @emit 'error', err
            
        source.on 'end', =>
            # if there was only one chunk received, read it
            @readChunk chunk unless received
            @emit 'end'
            
        @init()
            
    init: ->
        return
            
    readChunk: (chunk) ->
        return
        
    seek: (timestamp) ->
        return 0
        
    formats = []
    @register: (demuxer) ->
        formats.push demuxer
            
    @find: (buffer) ->
        stream = AV.Stream.fromBuffer(buffer)        
        for format in formats when format.probe(stream)
            return format
            
        return null