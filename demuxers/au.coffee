class AUDemuxer extends Demuxer
    Demuxer.register(AUDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is '.snd'
        
    readChunk: ->
        if not @readHeader and @stream.available(24)
            if @stream.readString(4) isnt '.snd'
                return @emit 'error', 'Invalid AU file.'
                
            size = @stream.readUInt32()
            dataSize = @stream.readUInt32()
            
            encoding = @stream.readUInt32()
            @format = {}
            
            switch encoding
                when 1
                    @format.formatID = 'ulaw'
                    @format.bitsPerChannel = 8
                    
                when 2
                    @format.formatID = 'lpcm'
                    @format.bitsPerChannel = 8
                    
                when 3
                    @format.formatID = 'lpcm'
                    @format.bitsPerChannel = 16
                    
                when 4
                    @format.formatID = 'lpcm'
                    @format.bitsPerChannel = 24
                    
                when 5, 6
                    @format.formatID = 'lpcm'
                    @format.bitsPerChannel = 32
                    @format.formatFlags = 1 if encoding is 6
                    
                when 7
                    @format.formatID = 'lpcm'
                    @format.bitsPerChannel = 64
                    @format.formatFlags = 1
                    
                when 27
                    @format.formatID = 'alaw'
                    @format.bitsPerChannel = 8
                    
                else
                    return @emit 'error', 'Unsupported encoding in AU file.'
             
            @format.sampleRate = @stream.readUInt32()
            @format.channelsPerFrame = @stream.readUInt32()
            
            if dataSize isnt 0xffffffff
                bytes = @format.bitsPerChannel / 8
                @emit 'duration', dataSize / bytes / @format.channelsPerFrame / @format.sampleRate * 1000 | 0
            
            @emit 'format', @format
            @readHeader = true
            
        if @readHeader
            @emit 'data', @stream.readSingleBuffer(@stream.list.availableBytes - @stream.localOffset)