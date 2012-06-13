class XLAWDecoder extends Decoder
    Decoder.register('ulaw', XLAWDecoder)
    Decoder.register('alaw', XLAWDecoder)
    
    SIGN_BIT   = 0x80
    QUANT_MASK = 0xf
    SEG_SHIFT  = 4
    SEG_MASK   = 0x70
    BIAS       = 0x84
    
    constructor: ->
        super
        
        @format.bitsPerChannel = 16
        @table = table = new Float32Array(256)
        
        if @format.formatID is 'ulaw'
            for i in [0...256]
                # Complement to obtain normal u-law value.
                val = ~i
            
                # Extract and bias the quantization bits. Then
                # shift up by the segment number and subtract out the bias.
                t = ((val & QUANT_MASK) << 3) + BIAS
                t <<= (val & SEG_MASK) >>> SEG_SHIFT
            
                table[i] = if val & SIGN_BIT then BIAS - t else t - BIAS
                
        else
            for i in [0...256]
                val = i ^ 0x55
                t = val & QUANT_MASK
                seg = (val & SEG_MASK) >>> SEG_SHIFT
                
                if seg
                    t = (t + t + 1 + 32) << (seg + 2)
                else
                    t = (t + t + 1) << 3
                    
                table[i] = if val & SIGN_BIT then t else -t
                
        return
            
    readChunk: =>
        {stream, table} = this
        chunkSize = Math.min(4096, @stream.remainingBytes())
        samples = chunkSize / (@format.bitsPerChannel / 8) >> 0
        
        if chunkSize is 0
            return @once 'available', @readChunk
        
        output = new Int16Array(samples)
        for i in [0...samples] by 1
            output[i] = table[stream.readUInt8()]
            
        @emit 'data', output