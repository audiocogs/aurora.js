class LPCMDecoder extends Decoder
    Decoder.register('lpcm', LPCMDecoder)
    
    constructor: ->
        super
        
        flags = @format.formatFlags or 0
        @floatingPoint = Boolean(flags & 1)
        @littleEndian = Boolean(flags & 2)
    
    readChunk: =>
        {stream, littleEndian} = this        
        chunkSize = 4096
        samples = chunkSize / (@format.bitsPerChannel / 8) >> 0
        bytes = samples * (@format.bitsPerChannel / 8)
        
        unless stream.available(bytes)
            @once 'available', @readChunk
        
        else
            if @floatingPoint
                switch @format.bitsPerChannel
                    when 32
                        output = new Float32Array(samples)
                        for i in [0...samples] by 1
                            output[i] = stream.readFloat32(littleEndian)
                            
                    when 64
                        output = new Float64Array(samples)
                        for i in [0...samples] by 1
                            output[i] = stream.readFloat64(littleEndian)
                            
                    else
                        return @emit 'error', 'Unsupported bit depth.'
                
            else
                switch @format.bitsPerChannel
                    when 8
                        output = new Int8Array(samples)
                        for i in [0...samples] by 1
                            output[i] = stream.readUInt8()
                    
                    when 16
                        output = new Int16Array(samples)
                        for i in [0...samples] by 1
                            output[i] = stream.readUInt16(littleEndian)
                        
                    when 24
                        return @emit 'error', '24 bit is unsupported.'
                    
                    when 32
                        output = new Int32Array(samples)
                        for i in [0...samples] by 1
                            output[i] = stream.readUInt32(littleEndian)
                        
                    else
                        return @emit 'error', 'Unsupported bit depth.'
            
            @emit 'data', output