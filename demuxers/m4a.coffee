class M4ADemuxer extends Demuxer
    Demuxer.register(M4ADemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(8, 4) is 'M4A '
        
    readChunk: ->
        if not @readHeaders and @stream.available(8)
            @len = @stream.readUInt32()
            @type = @stream.readString(4)
            console.log @type
            @readHeaders = true
            
        if @stream.available(@len - 8)
            switch @type
                when 'ftyp'
                    if @stream.readString(4) isnt 'M4A '
                        return @emit 'error', 'Not a valid M4A file.'
                    
                    @stream.advance(@len - 12)
                
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
                    
                    @stream.advance(4) # language and quality
                    
                when 'stsd'
                    pos = @stream.offset
                    maxpos = @stream.offset + @len - 8
                    
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
                    @emit 'cookie', @stream.readBuffer(@stream.offset - pos)
                    @sentCookie = true
                    
                    @stream.offset = @stream.localOffset = maxpos
                    
                    #console.log @dataPos, @dataLen
                    @stream.offset = @dataPos
                    @emit 'data', @stream.readBuffer(@dataLen)
                    #if not @sentData
                        #for chunk, i in @dataSections
                        #    @emit 'data', chunk
                    
                when 'mdat'
                    break if @receivedData
                    
                    @receivedData = true
                    @dataPos = @stream.offset
                    @dataLen = @len - 8
                    
                    @stream.advance(@len - 8)
                    ###
                    break if @receivedData
                    
                    @dataSections ?= []
                    buffer = @stream.readSingleBuffer(@len - 8)
                    @len -= buffer.length
                    
                    if @len <= 8
                        @readHeaders = false
                        @receivedData = true
                    
                    if @sentCookie
                        @sentData = true
                        @emit 'data', buffer
                    else
                        @dataSections.push buffer
                    
                    return @readChunk()
                    ###
                    
                else
                    @stream.advance(@len - 8)
            
            @readHeaders = false        
            @readChunk()