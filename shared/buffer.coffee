class Buffer
    constructor: (@data) ->
        @length = @data.length
    
    @allocate: (size) ->
        return new Buffer(new Uint8Array(size))
    
    copy: ->
        return new Buffer(new Uint8Array(@data))
    
    slice: (position, length) ->
        if position is 0 and length >= @length
            return new Buffer(@data)
        else
            return new Buffer(@data.subarray(position, position + length))
        
class BufferList
    constructor: ->
        @buffers = []
        
        @availableBytes = 0
        @availableBuffers = 0        
        @first = null
    
    copy: ->
        result = new BufferList()

        result.buffers = @buffers.slice(0)
        result.availableBytes = @availableBytes
        result.availableBuffers = @availableBuffers
    
    shift: ->
        result = @buffers.shift()
        
        @availableBytes -= result.length
        @availableBuffers -= 1
        
        @first = @buffers[0]
        return result
    
    push: (buffer) ->
        @buffers.push(buffer)
        
        @availableBytes += buffer.length
        @availableBuffers += 1
        
        @first = buffer unless @first
        return this
    
    unshift: (buffer) ->
        @buffers.unshift(buffer)
        
        @availableBytes += buffer.length
        @availableBuffers += 1
        
        @first = buffer
        return this

class Stream
    buf = new ArrayBuffer(8)
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
    nativeEndian = new Uint16Array(new Uint8Array([0x12, 0x34]).buffer)[0] is 0x3412;
    
    constructor: (@list) ->
        @localOffset = 0
        @offset = 0
    
    copy: ->
        result = new Stream(@list.copy)
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
    
    readUInt8: ->
        a0 = @list.first.data[@localOffset]
        
        @localOffset += 1
        @offset += 1
        
        if @localOffset == @list.first.length
            @localOffset = 0
            @list.shift()
        
        return a0
    
    peekUInt8: (offset = 0) ->
        offset = @localOffset + offset
        buffer = @list.first.data
        i = 0
        
        until buffer.length > offset
            offset -= buffer.length
            buffer = @list.buffers[++i].data
            
        return buffer[offset]
    
    readInt8: ->
        @read(1, littleEndian)
        return int8[0]
    
    peekInt8: (offset = 0) ->
        @peek(1, offset, littleEndian)
        return int8[0]
    
    readFloat64: (littleEndian) ->
        @read(8, littleEndian)
        
        # use Float64Array if available
        if float64
            return float64[0]
        else
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
    
    readFloat32: (littleEndian) ->
        @read(4, littleEndian)
        return float32[0]
        
    # IEEE 80 bit extended float
    readFloat80: ->
        a0 = @readUInt8()
        a1 = @readUInt8()
        
        sign = 1 - (a0 >>> 7) * 2 # -1 or +1
        exp = ((a0 & 0x7F) << 8) | a1
        low = @readUInt32()
        high = @readUInt32()
        
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
    
    readString: (length) ->
        result = []
        
        for i in [0...length]
            result.push(String.fromCharCode(@readUInt8()))
        
        return result.join('')
    
    peekString: (offset, length) ->
        result = []
        
        for i in [0...length]
            result.push(String.fromCharCode(@peekUInt8(offset + i)))
        
        return result.join('')
    
    readBuffer: (length) ->
        result = Buffer.allocate(length)
        to = result.data
        
        for i in [0...length]
            to[i] = @readUInt8()
        
        return result
    
    readSingleBuffer: (length) ->
        result = @list.first.slice(@localOffset, length)
        @advance(result.length)
        return result

class Bitstream
    constructor: (@stream) ->
        @bitPosition = 0
    
    copy: ->
        result = new Bitstream(@stream.copy())
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
        a0 = @stream.peekUInt8(0) * 0x0100000000
        a1 = @stream.peekUInt8(1) * 0x0001000000
        a2 = @stream.peekUInt8(2) * 0x0000010000
        a3 = @stream.peekUInt8(3) * 0x0000000100
        a4 = @stream.peekUInt8(4) * 0x0000000001
        
        a = a0 + a1 + a2 + a3 + a4
        a = a % Math.pow(2, 40 - @bitPosition)
        a = a / Math.pow(2, 40 - @bitPosition - bits)
        
        @advance(bits)
        return a << 0
    
    peekBig: (bits) ->
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
        a = @stream.peekUInt32(0)
        a = (a << @bitPosition) >>> (32 - bits)
        
        @advance(bits)
        return a
    
    readSmall: (bits) ->
        a = @stream.peekUInt16(0)
        a = ((a << @bitPosition) & 0xFFFF) >>> (16 - bits)
        
        @advance(bits)
        return a
    
    readOne: () ->
        a = @stream.peekUInt8(0)
        a = ((a << @bitPosition) & 0xFF) >>> 7
        
        @advance(1)
        return a