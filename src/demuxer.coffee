EventEmitter = require './core/events'
BufferList = require './core/bufferlist'
Stream = require './core/stream'

class Demuxer extends EventEmitter
    @probe: (buffer) ->
        return false
    
    constructor: (source, chunk) ->
        list = new BufferList
        list.append chunk
        @stream = new Stream(list)
        
        received = false
        source.on 'data', (chunk) =>
            received = true
            list.append chunk
            try
              @readChunk chunk
            catch e
              @emit 'error', e
            
        source.on 'error', (err) =>
            @emit 'error', err
            
        source.on 'end', =>
            # if there was only one chunk received, read it
            @readChunk chunk unless received
            @emit 'end'
        
        @seekPoints = []
        @init()
            
    init: ->
        return
            
    readChunk: (chunk) ->
        return
        
    addSeekPoint: (offset, timestamp) ->
        index = @searchTimestamp timestamp
        @seekPoints.splice index, 0, 
            offset: offset
            timestamp: timestamp
        
    searchTimestamp: (timestamp, backward) ->
        low = 0
        high = @seekPoints.length
        
        # optimize appending entries
        if high > 0 and @seekPoints[high - 1].timestamp < timestamp
            return high
        
        while low < high
            mid = (low + high) >> 1
            time = @seekPoints[mid].timestamp
            
            if time < timestamp
                low = mid + 1
                
            else if time >= timestamp
                high = mid
                
        if high > @seekPoints.length
            high = @seekPoints.length
            
        return high
        
    seek: (timestamp) ->
        if @format and @format.framesPerPacket > 0 and @format.bytesPerPacket > 0
            seekPoint =
                timestamp: timestamp
                offset: @format.bytesPerPacket * timestamp / @format.framesPerPacket
                
            return seekPoint
        else
            index = @searchTimestamp timestamp
            return @seekPoints[index]
        
    formats = []
    @register: (demuxer) ->
        formats.push demuxer
            
    @find: (buffer) ->
        stream = Stream.fromBuffer(buffer)        
        for format in formats
            offset = stream.offset
            try
                 return format if format.probe(stream)
            catch e
                # an underflow or other error occurred
                
            stream.seek(offset)
            
        return null
        
module.exports = Demuxer
