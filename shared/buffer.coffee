class Buffer
    constructor: (@data) ->
        @length = @data.length
        @timestamp = null
        @duration  = null
        @final = false
        @discontinuity = false
    
    @allocate: (size) ->
        return new Buffer(new Uint8Array(size))
    
    copy: ->
        buffer = new Buffer(new Uint8Array(@data))
        
        buffer.timestamp = @timestamp
        buffer.duration = @duration
        buffer.final = @final
        buffer.discontinuity = @discontinuity
    
    slice: (position, length) ->
        if position == 0 && length >= @length
            return this
        else
            return new Buffer(@data.subarray(position, length))
        
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
    Float64 = new ArrayBuffer(8)
    Float32 = new ArrayBuffer(4)

    FromFloat64 = new Float64Array(Float64)
    FromFloat32 = new Float32Array(Float32)

    ToFloat64 = new Uint32Array(Float64)
    ToFloat32 = new Uint32Array(Float32)
    
    constructor: (@list) ->
        @localOffset = 0
        @offset = 0
    
    copy: ->
        result = new Stream(@list.copy)
        
        result.localOffset = @localOffset
        result.offset = @offset
        return result
    
    available: (bytes) ->
        @list.availableBytes - @localOffset >= bytes
    
    advance: (bytes) ->
        @localOffset += bytes; @offset += bytes
        
        while @list.first && (@localOffset >= @list.first.length)
            @localOffset -= @list.shift().length
        
        return this
    
    readUInt32: (littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + 3
            a0 = buffer[@localOffset + 0]
            a1 = buffer[@localOffset + 1]
            a2 = buffer[@localOffset + 2]
            a3 = buffer[@localOffset + 3]
            
            @advance(4)
        else
            a0 = @readUInt8()
            a1 = @readUInt8()
            a2 = @readUInt8()
            a3 = @readUInt8()
        
        if littleEndian
            return ((a3 << 24) >>> 0) + (a2 << 16) + (a1 << 8) + (a0)
        else
            return ((a0 << 24) >>> 0) + (a1 << 16) + (a2 << 8) + (a3)
    
    peekUInt32: (offset = 0, littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + offset + 3
            a0 = buffer[@localOffset + offset + 0]
            a1 = buffer[@localOffset + offset + 1]
            a2 = buffer[@localOffset + offset + 2]
            a3 = buffer[@localOffset + offset + 3]
        else
            a0 = @peekUInt8(offset + 0)
            a1 = @peekUInt8(offset + 1)
            a2 = @peekUInt8(offset + 2)
            a3 = @peekUInt8(offset + 3)
        
        if littleEndian
            return ((a3 << 24) >>> 0) + (a2 << 16) + (a1 << 8) + (a0)
        else
            return ((a0 << 24) >>> 0) + (a1 << 16) + (a2 << 8) + (a3)
    
    readInt32: (littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + 3
            a0 = buffer[@localOffset + 0]
            a1 = buffer[@localOffset + 1]
            a2 = buffer[@localOffset + 2]
            a3 = buffer[@localOffset + 3]
            
            @advance(4)
        else
            a0 = @readUInt8()
            a1 = @readUInt8()
            a2 = @readUInt8()
            a3 = @readUInt8()
        
        if littleEndian
            return (a3 << 24) + (a2 << 16) + (a1 << 8) + (a0)
        else
            return (a0 << 24) + (a1 << 16) + (a2 << 8) + (a3)
    
    peekInt32: (offset = 0, littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + offset + 3
            a0 = buffer[@localOffset + offset + 0]
            a1 = buffer[@localOffset + offset + 1]
            a2 = buffer[@localOffset + offset + 2]
            a3 = buffer[@localOffset + offset + 3]
        else
            a0 = @peekUInt8(offset + 0)
            a1 = @peekUInt8(offset + 1)
            a2 = @peekUInt8(offset + 2)
            a3 = @peekUInt8(offset + 3)
        
        if littleEndian
            return (a3 << 24) + (a2 << 16) + (a1 << 8) + (a0)
        else
            return (a0 << 24) + (a1 << 16) + (a2 << 8) + (a3)
    
    readUInt16: (littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + 1
            a0 = buffer[@localOffset + 0]
            a1 = buffer[@localOffset + 1]
            
            @advance(2)
        else
            a0 = @readUInt8()
            a1 = @readUInt8()
        
        if littleEndian
            return (a1 << 8) + a0
        else
            return (a0 << 8) + (a1)
    
    peekUInt16: (offset = 0, littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + offset + 1
            a0 = buffer[@localOffset + offset + 0]
            a1 = buffer[@localOffset + offset + 1]
        else
            a0 = @peekUInt8(offset + 0)
            a1 = @peekUInt8(offset + 1)
        
        if littleEndian
            return (a1 << 8) + a0
        else
            return (a0 << 8) + (a1)
    
    readInt16: (littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + 1
            a0 = buffer[@localOffset + 0]
            a1 = buffer[@localOffset + 1]
        else
            a0 = @readInt8()
            a1 = @readUInt8()
        
        if littleEndian
            return (a1 << 8) + a0
        else
            return (a0 << 8) + (a1)
    
    peekInt16: (offset = 0, littleEndian) ->
        buffer = @list.first.data
        
        if buffer.length > @localOffset + offset + 1
            a0 = buffer[@localOffset + offset + 0]
            a1 = buffer[@localOffset + offset + 1]
        else
            a0 = @peekInt8(offset + 0)
            a1 = @peekUInt8(offset + 1)
        
        if littleEndian
            return (a1 << 8) + a0
        else
            return (a0 << 8) + (a1)
    
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
        i = 0
        buffer = @list.buffers[i].data
        
        until buffer.length > offset
            offset -= buffer.length
            buffer = @list.buffers[++i].data
        
        return buffer[offset]
    
    peekSafeUInt8: (offset = 0) ->
        offset = @localOffset + offset
        list = @list.buffers
        
        for i in [0...list.length] by 1
            buffer = list[i]
            
            if buffer.length > offset
                return buffer.data[offset]
            else
                offset -= buffer.length
        
        return 0
    
    readInt8: ->
        a0 = (@list.first.data[@localOffset] << 24) >> 24
        @advance(1)
        return a0
    
    peekInt8: (offset = 0) ->
        offset = @localOffset + offset
        i = 0
        buffer = @list.buffers[i].data
        
        until buffer.length > offset
            offset -= buffer.length
            buffer = @list.buffers[++i].data
        
        return ((buffer[offset] << 24) >> 24)
    
    readFloat64: (littleEndian) ->
        if littleEndian
            ToFloat64[0] = @readUInt32(true)
            ToFloat64[1] = @readUInt32(true)
        else
            ToFloat64[1] = @readUInt32()
            ToFloat64[0] = @readUInt32()
            
        return FromFloat64[0]
    
    readFloat32: (littleEndian) ->
        ToFloat32[0] = @readUInt32(littleEndian)
        return FromFloat32[0]
        
    # IEEE 80 bit extended float
    readFloat80: ->
        a0 = @readUInt8()
        a1 = @readUInt8()
        
        sign = (a0 >>> 7) * 2 - 1 # -1 or +1
        exp = ((a0 & 0x7F) << 8) | a1
        low = @readUInt32()
        high = @readUInt32()
        
        if exp is 0 and low is 0 and high is 0
            return 0
            
        if exp is 0x7fff
            if low is 0 and high is 0
                return if sign * Infinity
                
            return NaN
        
        exp -= 16383
        out = low * Math.pow(2, exp - 31)
        out += high * Math.pow(2, exp - 63)
        
        return sign * out
    
    readString: (length) ->
        result = []
        
        for i in [0 ... length]
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
        
        for i in [0 ... length]
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
    
    peekSafeBig: (bits) ->
        a0 = @stream.peekSafeUInt8(0) * 0x0100000000
        a1 = @stream.peekSafeUInt8(1) * 0x0001000000
        a2 = @stream.peekSafeUInt8(2) * 0x0000010000
        a3 = @stream.peekSafeUInt8(3) * 0x0000000100
        a4 = @stream.peekSafeUInt8(4) * 0x0000000001
        
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