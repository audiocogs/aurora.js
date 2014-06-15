Demuxer = require '../demuxer'

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
            @fileType = @stream.readString(4)
            @readStart = true
            
            if @fileType not in ['AIFF', 'AIFC']
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
                        sampleRate: @stream.readFloat80()
                        framesPerPacket: 1
                        littleEndian: false
                        floatingPoint: false
                        
                    @format.bytesPerPacket = (@format.bitsPerChannel / 8) * @format.channelsPerFrame
                    
                    if @fileType is 'AIFC'
                        format = @stream.readString(4)
                        
                        @format.littleEndian = format is 'sowt' and @format.bitsPerChannel > 8
                        @format.floatingPoint = format in ['fl32', 'fl64']
                        
                        format = 'lpcm' if format in ['twos', 'sowt', 'fl32', 'fl64', 'NONE']
                        @format.formatID = format
                        @len -= 4
                        
                    @stream.advance(@len - 18)
                    @emit 'format', @format
                    @emit 'duration', @format.sampleCount / @format.sampleRate * 1000 | 0
                    
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
            
        return