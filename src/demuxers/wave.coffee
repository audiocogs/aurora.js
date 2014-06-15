Demuxer = require '../demuxer'

class WAVEDemuxer extends Demuxer
    Demuxer.register(WAVEDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is 'RIFF' && 
               buffer.peekString(8, 4) is 'WAVE'
               
    formats = 
        0x0001: 'lpcm'
        0x0003: 'lpcm'
        0x0006: 'alaw'
        0x0007: 'ulaw'
               
    readChunk: ->
        if not @readStart and @stream.available(12)
            if @stream.readString(4) isnt 'RIFF'
                return @emit 'error', 'Invalid WAV file.'
                
            @fileSize = @stream.readUInt32(true)
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
                    if encoding not of formats
                        return @emit 'error', 'Unsupported format in WAV file.'
                        
                    @format = 
                        formatID: formats[encoding]
                        floatingPoint: encoding is 0x0003
                        littleEndian: formats[encoding] is 'lpcm'
                        channelsPerFrame: @stream.readUInt16(true)
                        sampleRate: @stream.readUInt32(true)
                        framesPerPacket: 1
                        
                    @stream.advance(4) # bytes/sec.
                    @stream.advance(2) # block align
                    
                    @format.bitsPerChannel = @stream.readUInt16(true)
                    @format.bytesPerPacket = (@format.bitsPerChannel / 8) * @format.channelsPerFrame
                    
                    @emit 'format', @format

                    # Advance to the next chunk
                    @stream.advance(@len - 16)
                    
                when 'data'
                    if not @sentDuration
                        bytes = @format.bitsPerChannel / 8
                        @emit 'duration', @len / bytes / @format.channelsPerFrame / @format.sampleRate * 1000 | 0
                        @sentDuration = true
                
                    buffer = @stream.readSingleBuffer(@len)
                    @len -= buffer.length
                    @readHeaders = @len > 0
                    @emit 'data', buffer
                    
                else
                    return unless @stream.available(@len)
                    @stream.advance(@len)
                        
            @readHeaders = false unless @type is 'data'
            
        return