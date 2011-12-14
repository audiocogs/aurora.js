class Demuxer extends EventEmitter
    @probe: (buffer) ->
        return false
    
    constructor: (source, chunk) ->
        list = new BufferList()
        list.push(chunk)
        @stream = new Stream(list)
        
        source.on 'data', (chunk) =>
            list.push chunk
            @readChunk chunk
            
        source.on 'error', (err) =>
            @emit 'error', err
            
        source.on 'end', =>
            @emit 'end'
            
    readChunk: (chunk) ->
        return
        
    seek: (timestamp) ->
        return 0
        
    formats = []
    @register: (demuxer) ->
        formats.push demuxer
            
    @find: (buffer) ->
        list = new BufferList
        list.push(buffer)
        stream = new Stream(list)
        
        for format in formats when format.probe(stream)
            return format
            
        return null