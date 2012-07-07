class Stream
    buf = new ArrayBuffer(16)
    uint8 = new Uint8Array(buf)
    int8 = new Int8Array(buf)
    uint16 = new Uint16Array(buf)
    int16 = new Int16Array(buf)
    uint32 = new Uint32Array(buf)
    int32 = new Int32Array(buf)
    float32 = new Float32Array(buf)
    float64 = new Float64Array(buf) if Float64Array?
    
    # detect the native endianness of the machine
    # 0x3412 is little endian, 0x1234 is big endian
    nativeEndian = new Uint16Array(new Uint8Array([0x12, 0x34]).buffer)[0] is 0x3412
    
    constructor: (@list) ->
        @localOffset = 0
        @offset = 0
        
    @fromBuffer: (buffer) ->
        list = new BufferList
        list.push(buffer)
        return new Stream(list)
    
    copy: ->
        result = new Stream(@list.copy())
        result.localOffset = @localOffset
        result.offset = @offset
        return result
    
    available: (bytes) ->
        return bytes <= @list.availableBytes - @localOffset
        
    remainingBytes: ->
        return @list.availableBytes - @localOffset
    
    advance: (bytes) ->
        @localOffset += bytes
        @offset += bytes
        
        while @list.first and (@localOffset >= @list.first.length)
            @localOffset -= @list.shift().length
        
        return this
        
    readUInt8: ->
        a = @list.first.data[@localOffset]

        @localOffset += 1
        @offset += 1

        if @localOffset == @list.first.length
            @localOffset = 0
            @list.shift()

        return a

    peekUInt8: (offset = 0) ->
        offset = @localOffset + offset
        list = @list.buffers

        for buffer in list    
            if buffer.length > offset
                return buffer.data[offset]

            offset -= buffer.length

        return 0
        
    read: (bytes, littleEndian = false) ->
        if littleEndian is nativeEndian
            for i in [0...bytes] by 1
                uint8[i] = @readUInt8()
        else
            for i in [bytes - 1..0] by -1
                uint8[i] = @readUInt8()
        
        return
        
    peek: (bytes, offset, littleEndian = false) ->
        if littleEndian is nativeEndian
            for i in [0...bytes] by 1
                uint8[i] = @peekUInt8(offset + i)
        else
            for i in [0...bytes] by 1
                uint8[bytes - i - 1] = @peekUInt8(offset + i)
                
        return
        
    readInt8: ->
        @read(1)
        return int8[0]

    peekInt8: (offset = 0) ->
        @peek(1, offset)
        return int8[0]
        
    readUInt16: (littleEndian) ->
        @read(2, littleEndian)
        return uint16[0]

    peekUInt16: (offset = 0, littleEndian) ->
        @peek(2, offset, littleEndian)
        return uint16[0]

    readInt16: (littleEndian) ->
        @read(2, littleEndian)
        return int16[0]

    peekInt16: (offset = 0, littleEndian) ->
        @peek(2, offset, littleEndian)
        return int16[0]
        
    readUInt24: (littleEndian) ->
        if littleEndian
            return @readUInt16(true) + (@readUInt8() << 16)
        else
            return (@readUInt16() << 8) + @readUInt8()

    peekUInt24: (offset = 0, littleEndian) ->
        if littleEndian
            return @peekUInt16(offset, true) + (@peekUInt8(offset + 2) << 16)
        else
            return (@peekUInt16(offset) << 8) + @peekUInt8(offset + 2)

    readInt24: (littleEndian) ->
        if littleEndian
            return @readUInt16(true) + (@readInt8() << 16)
        else
            return (@readInt16() << 8) + @readUInt8()

    peekInt24: (offset = 0, littleEndian) ->
        if littleEndian
            return @peekUInt16(offset, true) + (@peekInt8(offset + 2) << 16)
        else
            return (@peekInt16(offset) << 8) + @peekUInt8(offset + 2)
    
    readUInt32: (littleEndian) ->
        @read(4, littleEndian)
        return uint32[0]
    
    peekUInt32: (offset = 0, littleEndian) ->
        @peek(4, offset, littleEndian)
        return uint32[0]
    
    readInt32: (littleEndian) ->
        @read(4, littleEndian)
        return int32[0]
    
    peekInt32: (offset = 0, littleEndian) ->
        @peek(4, offset, littleEndian)
        return int32[0]
        
    readFloat32: (littleEndian) ->
        @read(4, littleEndian)
        return float32[0]
        
    peekFloat32: (offset = 0, littleEndian) ->
        @peek(4, offset, littleEndian)
        return float32[0]
    
    readFloat64: (littleEndian) ->
        @read(8, littleEndian)
        
        # use Float64Array if available
        if float64
            return float64[0]
        else
            return float64Fallback()
            
    float64Fallback = ->
        [low, high] = uint32
        return 0.0 if not high or high is 0x80000000

        sign = 1 - (high >>> 31) * 2 # +1 or -1
        exp = (high >>> 20) & 0x7ff
        frac = high & 0xfffff

        # NaN or Infinity
        if exp is 0x7ff
            return NaN if frac
            return sign * Infinity

        exp -= 1023
        out = (frac | 0x100000) * Math.pow(2, exp - 20)
        out += low * Math.pow(2, exp - 52)

        return sign * out
            
    peekFloat64: (offset = 0, littleEndian) ->
        @peek(8, offset, littleEndian)
        
        # use Float64Array if available
        if float64
            return float64[0]
        else
            return float64Fallback()
        
    # IEEE 80 bit extended float
    readFloat80: (littleEndian) ->
        @read(10, littleEndian)
        return float80()
        
    float80 = ->
        [high, low] = uint32
        a0 = uint8[9]
        a1 = uint8[8]
        
        sign = 1 - (a0 >>> 7) * 2 # -1 or +1
        exp = ((a0 & 0x7F) << 8) | a1
        
        if exp is 0 and low is 0 and high is 0
            return 0
            
        if exp is 0x7fff
            if low is 0 and high is 0
                return sign * Infinity
                
            return NaN
        
        exp -= 16383
        out = low * Math.pow(2, exp - 31)
        out += high * Math.pow(2, exp - 63)
        
        return sign * out
        
    peekFloat80: (offset = 0, littleEndian) ->
        @peek(10, offset, littleEndian)
        return float80()
    
    readString: (length) ->
        result = []
        for i in [0...length] by 1
            result.push String.fromCharCode @readUInt8()
        
        return result.join ''
    
    peekString: (offset, length) ->
        result = []
        for i in [0...length] by 1
            result.push String.fromCharCode @peekUInt8(offset + i)
        
        return result.join ''
        
    readUTF8: (length) ->
        # a little trick taking advantage of some built in functions
        # to decode UTF-8
        return decodeURIComponent escape @readString(length)
        
    peekUTF8: (offset, length) ->
        return decodeURIComponent escape @peekString(offset, length)
    
    readBuffer: (length) ->
        result = Buffer.allocate(length)
        to = result.data
        
        for i in [0...length] by 1
            to[i] = @readUInt8()
        
        return result
        
    peekBuffer: (offset = 0, length) ->
        result = Buffer.allocate(length)
        to = result.data
        
        for i in [0...length] by 1
            to[i] = @peekUInt8(offset + i)
        
        return result
    
    readSingleBuffer: (length) ->
        result = @list.first.slice(@localOffset, length)
        @advance(result.length)
        return result
        
    peekSingleBuffer: (length) ->
        result = @list.first.slice(@localOffset, length)
        return result