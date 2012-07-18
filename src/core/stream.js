void function (global) {
	'use strict'

	var unalignedBuffer = new ArrayBuffer(16)
	var unalignedBytes = new Uint8Array(unalignedBuffer)
	var unalignedView = new DataView(unalignedBuffer)

	var stream = Aurora.extend(Aurora.object, 'Aurora::Stream', {
		offset: { value: 0, writable: true },
		localOffset: { value: 0, writable: true }
	})

	stream.constructor = function (list) {
		Aurora.object.constructor.apply(this)

		this.$.list = list
	}

	stream.constructor.fromBuffer = function (buffer) {
		var list = new Aurora.BufferList()

		list.push(buffer)

		return new Aurora.Stream(list)
	}
	
	stream.available = function (n) {
		return n <= this.$.list.availableBytes - this.$.localOffset
	}

	stream.remainingBytes = function () {
		return this.$.list.availableBytes
	}

	stream.advance = function (n) {
		this.$.offset += n; this.$.localOffset += n

		while (this.$.list.first && (this.$.localOffset >= this.$.list.first.length)) {
			this.$.localOffset -= this.$.list.shift().length
		}

		return this
	}

	stream.read = function (n) {
		for (var i = 0; i < n; i++) {
			unalignedBytes[i] = this.readUInt8()
		}
	}

	stream.readUInt8 = function () {
		var a = this.$.list.first.view.getUint8(this.$.localOffset)

		this.$.offset += 1; this.$.localOffset += 1

		if (this.$.localOffset == this.$.list.first.length) {
			this.$.localOffset = 0; this.$.list.shift()
		}

		return a
	}

	stream.readUInt16 = function (littleEndian) {
		if (2 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint16(this.$.localOffset, littleEndian)

			this.$.offset += 2; this.$.localOffset += 2

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(2); return unalignedView.getUint16(0, littleEndian)
		}
	}

	stream.readUInt24 = function (littleEndian) {
		if (3 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint8(this.$.localOffset + 0)
			var b = this.$.list.first.view.getUint8(this.$.localOffset + 1)
			var c = this.$.list.first.view.getUint8(this.$.localOffset + 2)

			this.$.offset += 3; this.$.localOffset += 3

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}
		} else {
			this.read(3);
			
			var a = unalignedView.getUint8(0)
			var a = unalignedView.getUint8(1)
			var a = unalignedView.getUint8(2)
		}
		
		if (littleEndian) {
			return (a << 0) | (b << 8) | (c << 16)
		} else {
			return (c << 0) | (b << 8) | (a << 16)
		}
	}

	stream.readUInt32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getUint32(0, littleEndian)
		}
	}

	stream.readInt8 = function () {
		var a = this.$.list.first.view.getInt8(this.$.localOffset)

		this.$.offset += 1; this.$.localOffset += 1

		if (this.$.localOffset == this.$.list.first.length) {
			this.$.localOffset = 0; this.$.list.shift()
		}

		return a
	}

	stream.readInt16 = function (littleEndian) {
		if (2 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getInt16(this.$.localOffset, littleEndian)

			this.$.offset += 2; this.$.localOffset += 2

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(2); return unalignedView.getInt16(0, littleEndian)
		}
	}

	stream.readInt24 = function (littleEndian) {
		if (3 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint8(this.$.localOffset + 0)
			var b = this.$.list.first.view.getUint8(this.$.localOffset + 1)
			var c = this.$.list.first.view.getUint8(this.$.localOffset + 2)

			this.$.offset += 3; this.$.localOffset += 3

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}
		} else {
			this.read(3);
			
			var a = unalignedView.getUint8(0)
			var a = unalignedView.getUint8(1)
			var a = unalignedView.getUint8(2)
		}
		
		if (littleEndian) {
			return (a << 0) | (b << 8) | ((c << 24) >> 8)
		} else {
			return (c << 0) | (b << 8) | ((a << 24) >> 8)
		}
	}

	stream.readInt32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getInt32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getInt32(0, littleEndian)
		}
	}

	stream.readFloat32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getFloat32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getFloat32(0, littleEndian)
		}
	}

	stream.readFloat64 = function (littleEndian) {
		if (8 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getFloat64(this.$.localOffset, littleEndian)

			this.$.offset += 8; this.$.localOffset += 8

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(8); return unalignedView.getFloat64(0, littleEndian)
		}
	}

	stream.readString = function (n) {
		var result = []

		for (var i = 0; i < n; i++) {
			result.push(String.fromCharCode(this.readUInt8()))
		}

		return result.join('')
	}

	stream.readUTF8 = function (n) {
		/* TODO: Does this always work? */
		return decodeURIComponent(escape(this.readString(length)))
	}

	stream.readBuffer = function (n) {
		var result = new Aurora.Buffer.allocate(n)

		for (var i = 0; i < n; i++) {
			result.view.setUint8(i, this.readUInt8())
		}

		return result
	}

	stream.readSingleBuffer = function (n) {
		var result = this.$.list.first.slice(this.$.localOffset, n)

		this.advance(result.length)

		return result
	}

	stream.peek = function (offset, n) {
		for (var i = 0; i < n; i++) {
			unalignedBytes[i] = this.peekUInt8(offset + i)
		}
	}

	stream.peekUInt8 = function (offset) {
		var offset = this.$.localOffset + offset
		var list = this.$.list.buffers

		for (var i = 0; i < list.length; i++) {
			if (list[i].length > offset) {
				return list[i].view.getUint8(offset)
			}

			offset -= list[i].length
		}
		
		return 0 /* TODO: Semantics Unclear? */
	}

	stream.peekString = function (offset, n) {
		var result = []

		for (var i = 0; i < n; i++) {
			result.push(String.fromCharCode(this.peekUInt8(offset + i)))
		}

		return result.join('')
	}
//    peekInt8: (offset = 0) ->
//        @peek(1, offset)
//        return int8[0]
//        
//    peekUInt16: (offset = 0, littleEndian) ->
//        @peek(2, offset, littleEndian)
//        return uint16[0]
//
//    peekInt16: (offset = 0, littleEndian) ->
//        @peek(2, offset, littleEndian)
//        return int16[0]
//
//    peekUInt24: (offset = 0, littleEndian) ->
//        if littleEndian
//            return @peekUInt16(offset, true) + (@peekUInt8(offset + 2) << 16)
//        else
//            return (@peekUInt16(offset) << 8) + @peekUInt8(offset + 2)
//
//    peekInt24: (offset = 0, littleEndian) ->
//        if littleEndian
//            return @peekUInt16(offset, true) + (@peekInt8(offset + 2) << 16)
//        else
//            return (@peekInt16(offset) << 8) + @peekUInt8(offset + 2)
//    
//    peekUInt32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return uint32[0]
//    
//    peekInt32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return int32[0]
//    
//    peekFloat32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return float32[0]
//    
//    peekFloat64: (offset = 0, littleEndian) ->
//        @peek(8, offset, littleEndian)
//        
//        # use Float64Array if available
//        if float64
//            return float64[0]
//        else
//            return float64Fallback()
//        
//    # IEEE 80 bit extended float
//    readFloat80: (littleEndian) ->
//        @read(10, littleEndian)
//        return float80()
//        
//    float80 = ->
//        [high, low] = uint32
//        a0 = uint8[9]
//        a1 = uint8[8]
//        
//        sign = 1 - (a0 >>> 7) * 2 # -1 or +1
//        exp = ((a0 & 0x7F) << 8) | a1
//        
//        if exp is 0 and low is 0 and high is 0
//            return 0
//            
//        if exp is 0x7fff
//            if low is 0 and high is 0
//                return sign * Infinity
//                
//            return NaN
//        
//        exp -= 16383
//        out = low * Math.pow(2, exp - 31)
//        out += high * Math.pow(2, exp - 63)
//        
//        return sign * out
//        
//    peekFloat80: (offset = 0, littleEndian) ->
//        @peek(10, offset, littleEndian)
//        return float80()
//    
//    peekUTF8: (offset, length) ->
//        return decodeURIComponent escape @peekString(offset, length)
//    
//    peekBuffer: (offset = 0, length) ->
//        result = Buffer.allocate(length)
//        to = result.data
//        
//        for i in [0...length] by 1
//            to[i] = @peekUInt8(offset + i)
//        
//        return result
//    
//    peekSingleBuffer: (length) ->
//        result = @list.first.slice(@localOffset, length)
//        return result

	Aurora.stream = stream
	Aurora.Stream = stream.constructor

	Aurora.Stream.prototype = stream
}(this)
