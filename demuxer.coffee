class Demuxer extends EventEmitter
    @probe: (buffer) ->
        return false
    
    constructor: (source, chunk) ->
        list = new BufferList
        list.push(chunk)
        @stream = new Stream(list)
        
        received = false
        source.on 'data', (chunk) =>
            received = true
            list.push chunk
            @readChunk chunk
            
        source.on 'error', (err) =>
            @emit 'error', err
            
        source.on 'end', =>
            # if there was only one chunk received, read it
            @readChunk chunk unless received
            @emit 'end'
            
    readChunk: (chunk) ->
        return
        
    seek: (timestamp) ->
        return 0
        
    formats = []
    @register: (demuxer) ->
        formats.push demuxer
            
    @find: (buffer) ->
        stream = Stream.fromBuffer(buffer)        
        for format in formats when format.probe(stream)
            return format
            
        return null