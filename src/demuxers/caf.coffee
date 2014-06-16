Demuxer = require '../demuxer'
M4ADemuxer = require './m4a'

class CAFDemuxer extends Demuxer
    Demuxer.register(CAFDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is 'caff'
        
    readChunk: ->
        if not @format and @stream.available(64) # Number out of my behind
            if @stream.readString(4) isnt 'caff'
                return @emit 'error', "Invalid CAF, does not begin with 'caff'"
                
            # skip version and flags
            @stream.advance(4)
            
            if @stream.readString(4) isnt 'desc'
                return @emit 'error', "Invalid CAF, 'caff' is not followed by 'desc'"
                
            unless @stream.readUInt32() is 0 and @stream.readUInt32() is 32
                return @emit 'error', "Invalid 'desc' size, should be 32"
                
            @format = {}
            @format.sampleRate = @stream.readFloat64()
            @format.formatID = @stream.readString(4)
            
            flags = @stream.readUInt32()
            if @format.formatID is 'lpcm'
                @format.floatingPoint = Boolean(flags & 1)
                @format.littleEndian = Boolean(flags & 2)
             
            @format.bytesPerPacket = @stream.readUInt32()
            @format.framesPerPacket = @stream.readUInt32()
            @format.channelsPerFrame = @stream.readUInt32()
            @format.bitsPerChannel = @stream.readUInt32()
                
            @emit 'format', @format
            
        while @stream.available(1)
            unless @headerCache
                @headerCache =
                    type: @stream.readString(4)
                    oversize: @stream.readUInt32() isnt 0
                    size: @stream.readUInt32()
                
                if @headerCache.oversize
                    return @emit 'error', "Holy Shit, an oversized file, not supported in JS"
            
            switch @headerCache.type
                when 'kuki'
                    if @stream.available(@headerCache.size)
                        if @format.formatID is 'aac ' # variations needed?
                            offset = @stream.offset + @headerCache.size
                            if cookie = M4ADemuxer.readEsds(@stream)
                                @emit 'cookie', cookie
                                
                            @stream.seek offset # skip extra garbage
                    
                        else
                            buffer = @stream.readBuffer(@headerCache.size)
                            @emit 'cookie', buffer
                        
                        @headerCache = null
                        
                when 'pakt'
                    if @stream.available(@headerCache.size)
                        if @stream.readUInt32() isnt 0
                            return @emit 'error', 'Sizes greater than 32 bits are not supported.'
                            
                        @numPackets = @stream.readUInt32()
                        
                        if @stream.readUInt32() isnt 0
                            return @emit 'error', 'Sizes greater than 32 bits are not supported.'
                            
                        @numFrames = @stream.readUInt32()
                        @primingFrames = @stream.readUInt32()
                        @remainderFrames = @stream.readUInt32()
                        
                        @emit 'duration', @numFrames / @format.sampleRate * 1000 | 0
                        @sentDuration = true
                        
                        byteOffset = 0
                        sampleOffset = 0
                        for i in [0...@numPackets] by 1
                            @addSeekPoint byteOffset, sampleOffset
                            byteOffset += @format.bytesPerPacket or M4ADemuxer.readDescrLen(@stream)
                            sampleOffset += @format.framesPerPacket or M4ADemuxer.readDescrLen(@stream)
                        
                        @headerCache = null
                        
                when 'info'
                    entries = @stream.readUInt32()
                    metadata = {}
                    
                    for i in [0...entries]
                        # null terminated strings
                        key = @stream.readString(null)
                        value = @stream.readString(null)                        
                        metadata[key] = value
                    
                    @emit 'metadata', metadata
                    @headerCache = null
                    
                when 'data'
                    unless @sentFirstDataChunk
                        # skip edit count
                        @stream.advance(4)
                        @headerCache.size -= 4

                        # calculate the duration based on bytes per packet if no packet table
                        if @format.bytesPerPacket isnt 0 and not @sentDuration
                            @numFrames = @headerCache.size / @format.bytesPerPacket
                            @emit 'duration', @numFrames / @format.sampleRate * 1000 | 0
                            
                        @sentFirstDataChunk = true
                
                    buffer = @stream.readSingleBuffer(@headerCache.size)
                    @headerCache.size -= buffer.length
                    @emit 'data', buffer
                    
                    if @headerCache.size <= 0
                        @headerCache = null
                    
                else
                    if @stream.available(@headerCache.size)
                        @stream.advance(@headerCache.size)
                        @headerCache = null
                        
        return