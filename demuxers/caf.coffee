class CAFDemuxer extends Demuxer
    Demuxer.register(CAFDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is 'caff'
        
    readChunk: ->
        if not @format and @stream.available(64) # Number out of my behind
            if @stream.readString(4) != 'caff'
                return @emit 'error', "Invalid CAF, does not begin with 'caff'"
                
            # skip version and flags
            @stream.advance(4)
            
            if @stream.readString(4) isnt 'desc'
                return @emit 'error', "Invalid CAF, 'caff' is not followed by 'desc'"
                
            unless @stream.readUInt32() is 0 and @stream.readUInt32() is 32
                return @emit 'error', "Invalid 'desc' size, should be 32"
                
            @format =
                sampleRate:         @stream.readFloat64()
                formatID:           @stream.readString(4)
                formatFlags:        @stream.readUInt32()
                bytesPerPacket:     @stream.readUInt32()
                framesPerPacket:    @stream.readUInt32()
                channelsPerFrame:   @stream.readUInt32()
                bitsPerChannel:     @stream.readUInt32()
                
            @emit 'format', @format
            
        while (@headerCache && @stream.available(1)) || @stream.available(13)
            unless @headerCache
                @headerCache =
                    type:               @stream.readString(4)
                    oversize:           @stream.readUInt32() isnt 0
                    size:               @stream.readUInt32()
                
                if @headerCache.type == 'data' # Silly-Hack
                    @stream.advance(4)
                    @headerCache.size -= 4
                
            
            if @headerCache.oversize
                return @emit 'error', "Holy Shit, an oversized file, not supported in JS"
            
            switch @headerCache.type
                when 'kuki'
                    if @stream.available(@headerCache.size)
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
                        
                        @stream.advance(@headerCache.size - 24)
                        @headerCache = null
                    
                when 'data'
                    buffer = @stream.readSingleBuffer(@headerCache.size)
                    @headerCache.size -= buffer.length
                    
                    @emit 'data', buffer, @headerCache.size is 0
                    
                    if @headerCache.size <= 0
                        @headerCache = null
                    
                else
                    if @stream.available(@headerCache.size)
                        @stream.advance(@headerCache.size)
                        @headerCache = null
                        
        return