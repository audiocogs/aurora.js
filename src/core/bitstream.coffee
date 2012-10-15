class AV.Bitstream
    constructor: (@stream) ->
        @bitPosition = 0
    
    copy: ->
        result = new AV.Bitstream(@stream.copy())
        result.bitPosition = @bitPosition
        return result
    
    offset: -> # Should be a property
        return 8 * @stream.offset + @bitPosition
    
    available: (bits) ->
        return @stream.available((bits + 8 - @bitPosition) / 8)
    
    advance: (bits) ->
        @bitPosition += bits
        
        @stream.advance(@bitPosition >> 3)
        @bitPosition = @bitPosition & 7
        
        return this
    
    align: ->
        unless @bitPosition == 0
            @bitPosition = 0
            @stream.advance(1)
        
        return this
    
    readBig: (bits) ->
        return 0 if bits is 0
        val = @peekBig(bits)
        @advance(bits)
        return val
    
    peekBig: (bits) ->
        return 0 if bits is 0
        a0 = @stream.peekUInt8(0) * 0x0100000000
        a1 = @stream.peekUInt8(1) * 0x0001000000
        a2 = @stream.peekUInt8(2) * 0x0000010000
        a3 = @stream.peekUInt8(3) * 0x0000000100
        a4 = @stream.peekUInt8(4) * 0x0000000001
        
        a = a0 + a1 + a2 + a3 + a4
        a = a % Math.pow(2, 40 - @bitPosition)
        a = a / Math.pow(2, 40 - @bitPosition - bits)
        
        return a << 0
    
    read: (bits) ->
        return 0 if bits is 0        
        a = @stream.peekUInt32(0)
        a = (a << @bitPosition) >>> (32 - bits)
        
        @advance(bits)
        return a
        
    readSigned: (bits) ->
        return 0 if bits is 0
        a = @stream.peekUInt32(0)
        a = (a << @bitPosition) >> (32 - bits)
        
        @advance(bits)
        return a
    
    peek: (bits) ->
        return 0 if bits is 0
        a = @stream.peekUInt32(0)
        a = (a << @bitPosition) >>> (32 - bits)
        return a
    
    readSmall: (bits) ->
        return 0 if bits is 0
        a = @stream.peekUInt16(0)
        a = ((a << @bitPosition) & 0xFFFF) >>> (16 - bits)
        
        @advance(bits)
        return a
        
    peekSmall: (bits) ->
        return 0 if bits is 0
        a = @stream.peekUInt16(0)
        a = ((a << @bitPosition) & 0xFFFF) >>> (16 - bits)
        return a
    
    readOne: ->
        a = @stream.peekUInt8(0)
        a = ((a << @bitPosition) & 0xFF) >>> 7
        
        @advance(1)
        return a
        
    peekOne: ->
        a = @stream.peekUInt8(0)
        a = ((a << @bitPosition) & 0xFF) >>> 7
        return a
        
    bitMask = [
        0x00000000, 0x00000001, 0x00000003, 0x00000007,
        0x0000000f, 0x0000001f, 0x0000003f, 0x0000007f,
        0x000000ff, 0x000001ff, 0x000003ff, 0x000007ff,
        0x00000fff, 0x00001fff, 0x00003fff, 0x00007fff,
        0x0000ffff, 0x0001ffff, 0x0003ffff, 0x0007ffff,
        0x000fffff, 0x001fffff, 0x003fffff, 0x007fffff,
        0x00ffffff, 0x01ffffff, 0x03ffffff, 0x07ffffff,
        0x0fffffff, 0x1fffffff, 0x3fffffff, 0x7fffffff,
        0xffffffff
    ]

    readLSB: (bits) ->
        return 0 if bits is 0
        
        modBits = bits + @bitPosition
        a  = (@stream.peekUInt8(0) & 0xFF) >>> @bitPosition
        a |= (@stream.peekUInt8(1) & 0xFF) << (8  - @bitPosition) if modBits > 8
        a |= (@stream.peekUInt8(2) & 0xFF) << (16 - @bitPosition) if modBits > 16
        a |= (@stream.peekUInt8(3) & 0xFF) << (24 - @bitPosition) if modBits > 24
        a |= (@stream.peekUInt8(4) & 0xFF) << (32 - @bitPosition) if modBits > 32
        
        @advance bits
        return a & bitMask[bits]