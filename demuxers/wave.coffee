class WAVEDemuxer extends Demuxer
    Demuxer.register(WAVEDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is 'RIFF' && 
               buffer.peekString(8, 4) is 'WAVE'
               
    FORMAT_LPCM  = 0x0001
    FORMAT_FLOAT = 0x0003
    FORMAT_ALAW  = 0x0006
    FORMAT_ULAW  = 0x0007
               
    readChunk: ->
        if not @readStart and @stream.available(12)
            if @stream.readString(4) isnt 'RIFF'
                return @emit 'error', 'Invalid WAV file.'
                
            @fileSize = @stream.readUInt32()
            @readStart = true
            
            if @stream.readString(4) isnt 'WAVE'
                return @emit 'error', 'Invalid WAV file.'
                
        while @stream.available(1)
            if not @readHeaders and @stream.available(8)
                @type = @stream.readString(4)
                @len = @stream.readUInt32(true) # little endian
                
            switch @type
                when 'fmt '
                    encoding = @stream.readUInt16(true)
                    #if encoding not in [FORMAT_LPCM, FORMAT_FLOAT]
                    #    return @emit 'error', 'Unsupported format in WAV file.'
                    
                    encoding++ if encoding is FORMAT_LPCM
                    format = 'lpcm'
                    format = 'ulaw' if encoding is FORMAT_ULAW
                    format = 'alaw' if encoding is FORMAT_ALAW
                        
                    @format = 
                        formatID: format
                        formatFlags: encoding
                        channelsPerFrame: @stream.readUInt16(true)
                        sampleRate: @stream.readUInt32(true)
                        
                    @stream.advance(4) # bytes/sec.
                    @stream.advance(2) # block align
                    
                    @format.bitsPerChannel = @stream.readUInt16(true)
                    @emit 'format', @format
                    
                when 'data'
                    buffer = @stream.readSingleBuffer(@len)
                    @len -= buffer.length
                    @readHeaders = @len > 0
                    @emit 'data', buffer
                    
                else
                    return unless @stream.available(@len)
                    @stream.advance(@len)
                        
            @readHeaders = false unless @type is 'data'
            
        return