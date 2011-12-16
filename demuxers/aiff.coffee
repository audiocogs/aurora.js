class AIFFDemuxer extends Demuxer
    Demuxer.register(AIFFDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is 'FORM' && 
               buffer.peekString(8, 4) in ['AIFF', 'AIFC']
        
    readChunk: ->
        if not @readStart and @stream.available(12)
            if @stream.readString(4) isnt 'FORM'
                return @emit 'error', 'Invalid AIFF.'
                
            @fileSize = @stream.readUInt32()
            @readStart = true
            
            if @stream.readString(4) not in ['AIFF', 'AIFC']
                return @emit 'error', 'Invalid AIFF.'
        
        while @stream.available(1)
            if not @readHeaders and @stream.available(8)
                @type = @stream.readString(4)
                @len = @stream.readUInt32()
                
            switch @type
                when 'COMM'
                    return unless @stream.available(@len)
                    
                    @format =
                        formatID: 'lpcm'
                        channelsPerFrame: @stream.readUInt16()
                        sampleCount: @stream.readUInt32()
                        bitsPerChannel: @stream.readUInt16()
                        sampleRate: @stream.readFloat64() # TODO: wrong... should be 10 bytes?
                        
                    @stream.advance(@len - 16)
                    @emit 'format', @format
                    
                when 'SSND'
                    unless @readSSNDHeader and @stream.available(4)
                        offset = @stream.readUInt32()
                        @stream.advance(4) # skip block size
                        @stream.advance(offset) # skip to data
                        @readSSNDHeader = true
                        
                    buffer = @stream.readSingleBuffer(@len)
                    @len -= buffer.length
                    @readHeaders = @len > 0
                    @emit 'data', buffer
                    
                else
                    return unless @stream.available(@len)
                    @stream.advance(@len)
                        
            @readHeaders = false unless @type is 'SSND'