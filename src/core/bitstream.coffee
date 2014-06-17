class Bitstream
    constructor: (@stream) ->
        @bitPosition = 0

    copy: ->
        result = new Bitstream @stream.copy()
        result.bitPosition = @bitPosition
        return result

    offset: -> # Should be a property
        return 8 * @stream.offset + @bitPosition

    available: (bits) ->
        return @stream.available((bits + 8 - @bitPosition) / 8)

    advance: (bits) ->
        pos = @bitPosition + bits
        @stream.advance(pos >> 3)
        @bitPosition = pos & 7
        
    rewind: (bits) ->
        pos = @bitPosition - bits
        @stream.rewind(Math.abs(pos >> 3))
        @bitPosition = pos & 7
        
    seek: (offset) ->
        curOffset = @offset()
        
        if offset > curOffset
            @advance offset - curOffset 
            
        else if offset < curOffset 
            @rewind curOffset - offset

    align: ->
        unless @bitPosition is 0
            @bitPosition = 0
            @stream.advance(1)
        
    read: (bits, signed) ->
        return 0 if bits is 0
        
        mBits = bits + @bitPosition
        if mBits <= 8
            a = ((@stream.peekUInt8() << @bitPosition) & 0xff) >>> (8 - bits)

        else if mBits <= 16
            a = ((@stream.peekUInt16() << @bitPosition) & 0xffff) >>> (16 - bits)

        else if mBits <= 24
            a = ((@stream.peekUInt24() << @bitPosition) & 0xffffff) >>> (24 - bits)

        else if mBits <= 32
            a = (@stream.peekUInt32() << @bitPosition) >>> (32 - bits)

        else if mBits <= 40
            a0 = @stream.peekUInt8(0) * 0x0100000000 # same as a << 32
            a1 = @stream.peekUInt8(1) << 24 >>> 0
            a2 = @stream.peekUInt8(2) << 16
            a3 = @stream.peekUInt8(3) << 8
            a4 = @stream.peekUInt8(4)

            a = a0 + a1 + a2 + a3 + a4
            a %= Math.pow(2, 40 - @bitPosition)                        # (a << bitPosition) & 0xffffffffff
            a = Math.floor(a / Math.pow(2, 40 - @bitPosition - bits))  # a >>> (40 - bits)

        else
            throw new Error "Too many bits!"
            
        if signed
            # if the sign bit is turned on, flip the bits and 
            # add one to convert to a negative value
            if mBits < 32
                if a >>> (bits - 1)
                    a = ((1 << bits >>> 0) - a) * -1
            else
                if a / Math.pow(2, bits - 1) | 0
                    a = (Math.pow(2, bits) - a) * -1

        @advance bits
        return a
        
    peek: (bits, signed) ->
        return 0 if bits is 0
        
        mBits = bits + @bitPosition
        if mBits <= 8
            a = ((@stream.peekUInt8() << @bitPosition) & 0xff) >>> (8 - bits)

        else if mBits <= 16
            a = ((@stream.peekUInt16() << @bitPosition) & 0xffff) >>> (16 - bits)

        else if mBits <= 24
            a = ((@stream.peekUInt24() << @bitPosition) & 0xffffff) >>> (24 - bits)

        else if mBits <= 32
            a = (@stream.peekUInt32() << @bitPosition) >>> (32 - bits)

        else if mBits <= 40
            a0 = @stream.peekUInt8(0) * 0x0100000000 # same as a << 32
            a1 = @stream.peekUInt8(1) << 24 >>> 0
            a2 = @stream.peekUInt8(2) << 16
            a3 = @stream.peekUInt8(3) << 8
            a4 = @stream.peekUInt8(4)

            a = a0 + a1 + a2 + a3 + a4
            a %= Math.pow(2, 40 - @bitPosition)                        # (a << bitPosition) & 0xffffffffff
            a = Math.floor(a / Math.pow(2, 40 - @bitPosition - bits))  # a >>> (40 - bits)

        else
            throw new Error "Too many bits!"
            
        if signed
            # if the sign bit is turned on, flip the bits and 
            # add one to convert to a negative value
            if mBits < 32
                if a >>> (bits - 1)
                    a = ((1 << bits >>> 0) - a) * -1
            else
                if a / Math.pow(2, bits - 1) | 0
                    a = (Math.pow(2, bits) - a) * -1

        return a

    readLSB: (bits, signed) ->
        return 0 if bits is 0
        if bits > 40
            throw new Error "Too many bits!"

        mBits = bits + @bitPosition
        a  = (@stream.peekUInt8(0)) >>> @bitPosition
        a |= (@stream.peekUInt8(1)) << (8  - @bitPosition) if mBits > 8
        a |= (@stream.peekUInt8(2)) << (16 - @bitPosition) if mBits > 16
        a += (@stream.peekUInt8(3)) << (24 - @bitPosition) >>> 0 if mBits > 24            
        a += (@stream.peekUInt8(4)) * Math.pow(2, 32 - @bitPosition) if mBits > 32

        if mBits >= 32
            a %= Math.pow(2, bits)
        else
            a &= (1 << bits) - 1
            
        if signed
            # if the sign bit is turned on, flip the bits and 
            # add one to convert to a negative value
            if mBits < 32
                if a >>> (bits - 1)
                    a = ((1 << bits >>> 0) - a) * -1
            else
                if a / Math.pow(2, bits - 1) | 0
                    a = (Math.pow(2, bits) - a) * -1

        @advance bits
        return a
        
    peekLSB: (bits, signed) ->
        return 0 if bits is 0
        if bits > 40
            throw new Error "Too many bits!"

        mBits = bits + @bitPosition
        a  = (@stream.peekUInt8(0)) >>> @bitPosition
        a |= (@stream.peekUInt8(1)) << (8  - @bitPosition) if mBits > 8
        a |= (@stream.peekUInt8(2)) << (16 - @bitPosition) if mBits > 16
        a += (@stream.peekUInt8(3)) << (24 - @bitPosition) >>> 0 if mBits > 24            
        a += (@stream.peekUInt8(4)) * Math.pow(2, 32 - @bitPosition) if mBits > 32
        
        if mBits >= 32
            a %= Math.pow(2, bits)
        else
            a &= (1 << bits) - 1
            
        if signed
            # if the sign bit is turned on, flip the bits and 
            # add one to convert to a negative value
            if mBits < 32
                if a >>> (bits - 1)
                    a = ((1 << bits >>> 0) - a) * -1
            else
                if a / Math.pow(2, bits - 1) | 0
                    a = (Math.pow(2, bits) - a) * -1

        return a
        
module.exports = Bitstream
