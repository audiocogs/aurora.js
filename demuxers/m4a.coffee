class M4ADemuxer extends Demuxer
    Demuxer.register(M4ADemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(8, 4) is 'M4A '
        
    readChunk: ->
        return unless @stream.available(1)
        
        if not @readHeaders and @stream.available(8)
            @len = @stream.readUInt32() - 8
            @type = @stream.readString(4)
            
            return @readChunk() if @len is 0
            @readHeaders = true
            
        if @type is 'mdat'
            buffer = @stream.readSingleBuffer(@len)
            @len -= buffer.length
            @readHeaders = @len > 0
            
            if @sentCookie
                @emit 'data', buffer
            else
                @dataSections ?= []
                @dataSections.push buffer
            
        else if @stream.available(@len)
            switch @type
                when 'ftyp'
                    if @stream.readString(4) isnt 'M4A '
                        return @emit 'error', 'Not a valid M4A file.'
                    
                    @stream.advance(@len - 4)
                
                # traverse into these types - they are container atoms    
                when 'moov', 'trak', 'mdia', 'minf', 'stbl', 'udta', 'ilst'
                    break
                    
                when 'meta'
                    @stream.advance(4) # random zeros
                    
                when 'mdhd'
                    @stream.advance(4) # version and flags
                    @stream.advance(8) # creation and modification dates
                    
                    @sampleRate = @stream.readUInt32()
                    @duration = @stream.readUInt32()
                    @emit 'duration', @duration / @sampleRate * 1000 | 0
                    
                    @stream.advance(4) # language and quality
                    
                when 'stsd'
                    pos = @stream.offset
                    maxpos = @stream.offset + @len
                    
                    @stream.advance(4) # version and flags
                    
                    numEntries = @stream.readUInt32()
                    if numEntries isnt 1
                        return @emit 'error', "Only expecting one entry in sample description atom!"
                        
                    @stream.advance(4) # size
                    
                    @format = {}
                    @format.formatID = @stream.readString(4)
                    
                    @stream.advance(6) # reserved
                    
                    if @stream.readUInt16() isnt 1
                        return @emit 'error', 'Unknown version in stsd atom.'
                    
                    @stream.advance(6) # skip revision level and vendor
                    @stream.advance(2) # reserved
                    
                    @format.channelsPerFrame = @stream.readUInt16()
                    @format.bitsPerChannel = @stream.readUInt16()
                    
                    @stream.advance(4) # skip compression id and packet size
                    
                    @format.sampleRate = @stream.readUInt16()
                    @stream.advance(2)
                    
                    @emit 'format', @format
                    
                    # read the cookie
                    @emit 'cookie', @stream.readBuffer(maxpos - @stream.offset)
                    @sentCookie = true
                    
                    # if the data was already decoded, emit it
                    if @dataSections
                        interval = setInterval =>
                            @emit 'data', @dataSections.shift()
                            clearInterval interval if @dataSections.length is 0
                        , 100
                    
                else
                    console.log @type
                    @stream.advance(@len)
            
            @readHeaders = false        
        
        @readChunk()