/*
 * Copyright (c) 2012, Jens Nockert, Devon Govett
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

void function (global) {
	"use strict";

	global.Aurora = {}
}(this)

void function (global) {
	'use strict'

	Aurora.object = Object.create({}, {
		$: { value: {}, configurable: true },
		typename: { value: 'Aurora::Object', enumerable: true, configurable: true },
		prototype: {
			get: function () {
				return Object.getPrototypeOf(this)
			},
			enumerable: true
		}
	})

	Aurora.object.constructor = function () {
		Object.defineProperty(this, '$', { value: this.prototype.$.__cs_clone(2) })
	}

	Aurora.object.clone = function (depth) {
		var result = Object.create(Object.getPrototypeOf(this))

		var keys = Object.getOwnPropertyNames(this), remaining = depth ? depth - 1 : 0

		if (remaining > 0) {
			for (var i = 0; i < keys.length; i++) {
				var descriptor = Object.getOwnPropertyDescriptor(this, keys[i])

				if (descriptor.value && descriptor.value.__cs_clone) {
					descriptor.value = descriptor.value.__cs_clone(remaining)
				}

				Object.defineProperty(result, keys[i], descriptor)
			}
		} else {
			for (var i = 0; i < keys.length; i++) {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(this, keys[i]))
			}
		}

		/* TODO: Check for Frozen, Sealed, Non-Extensible? */

		return result
	}

	Object.defineProperty(Object.prototype, '__cs_clone', { value: Aurora.object.clone })
	Object.defineProperty(Array.prototype, '__cs_clone', { value: Array.prototype.slice })

	var cloneTypedArray = function (depth) {
		if (depth > 1) {
			var result = new this.constructor(this.length)
			
			result.set(this)
			
			return result
		} else {
			return this.subarray(0)
		}
	}

	Object.defineProperty(Uint8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint8ClampedArray.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Int8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Float32Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Float64Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Date.prototype, '__cs_clone', { value: function () {
		return new Date(this)
	}})

	Aurora.extend = function (type, name, privateProperties, properties) {
		var result = Object.create(Object.getPrototypeOf(type))
		var keys = Object.getOwnPropertyNames(type), dollar = type.$.__cs_clone(2)

		for (var i = 0; i < keys.length; i++) {
			if (keys[i] != '$' && keys[i] != 'typename') {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(type, keys[i]))
			}
		}

		Object.defineProperties(result, properties || {})
		Object.defineProperties(dollar, privateProperties || {})

		Object.defineProperty(result, '$', { value: dollar })
		Object.defineProperty(result, 'typename', { value: name, enumerable: true })

		return result
	}
}(this)

void function (global) {
	'use strict'

	var buffer = Aurora.extend(Aurora.object, 'Aurora::Buffer')

	buffer.constructor = function (data, offset, byteLength) {
		Aurora.object.constructor.apply(this)

		var off = offset ? offset : 0

		if (!byteLength || byteLength > data.byteLength - off) {
			this.view = new DataView(data, off)
		} else {
			this.view = new DataView(data, off, byteLength)
		}

		this.$.data = data

		this.length = this.view.byteLength
	}

	buffer.constructor.allocate = function (n) {
		return new Aurora.Buffer(new ArrayBuffer(n))
	}

	buffer.slice = function (position, length) {
		if (position == 0 && length >= this.length) {
			return new Aurora.Buffer(this.$.data)
		} else {
			return new Aurora.Buffer(this.$.data, position, length)
		}
	}

	/* TODO: Is this really the right place for blob work? */
	buffer.constructor.makeBlobURL = function (data) {
		return URL.createObjectURL(new Blob([data]))
	}

	buffer.constructor.revokeBlobURL = function (url) {
		URL.revokeBlobURL(url)
	}

	Aurora.buffer = buffer
	Aurora.Buffer = buffer.constructor

	Aurora.Buffer.prototype = buffer
}(this)

void function (global) {
	'use strict'

	var bufferList = Aurora.extend(Aurora.object, 'Aurora::BufferList')

	bufferList.constructor = function (data, offset, byteLength) {
		Aurora.object.constructor.apply(this)

		this.buffers = [], this.availableBytes = 0, this.availableBuffers = 0

		this.first = null
	}

	bufferList.shift = function () {
		var result = this.buffers.shift()

		this.availableBytes -= result.length
		this.availableBuffers -= 1

		this.first = this.buffers[0]

		return result
	}

	bufferList.unshift = function (buffer) {
		this.buffers.unshift(buffer)

		this.availableBytes += buffer.length
		this.availableBuffers += 1

		this.first = buffer

		return this
	}

	bufferList.push = function (buffer) {
		this.buffers.push(buffer)

		this.availableBytes += buffer.length
		this.availableBuffers += 1

		this.first = this.first || buffer

		return this
	}

	Aurora.bufferList = bufferList
	Aurora.BufferList = bufferList.constructor

	Aurora.BufferList.prototype = bufferList
}(this)


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

void function (global) {
	'use strict'

	var bitMask = [
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

	var bitStream = Aurora.extend(Aurora.object, 'Aurora::BitStream', {
		bitPosition: { value: 0, writable: true },
		offset: { get: function () { return 8 * this.stream.offset + this.bitPosition } }
	})

	bitStream.constructor = function (stream) {
		Aurora.object.constructor.apply(this)

		this.$.stream = stream
	}
	
	bitStream.available = function (n) {
		return this.$.stream.available((n + 8 - this.$.bitPosition) / 8)
	}

	bitStream.advance = function (n) {
		this.$.bitPosition += n

		this.$.stream.advance(this.$.bitPosition >> 3)
		this.$.bitPosition &= 7

		return this
	}

	bitStream.align = function () {
		if (this.$.bitPosition != 0) {
			this.$.bitPosition = 0; this.$.stream.advance(1)
		}

		return this
	}

	bitStream.peekBig = function (n) {
		if (n == 0) { return 0 }

		var a0 = this.$.stream.peekUInt8(0) * 0x0100000000
		var a1 = this.$.stream.peekUInt8(1) * 0x0001000000
		var a2 = this.$.stream.peekUInt8(2) * 0x0000010000
		var a3 = this.$.stream.peekUInt8(3) * 0x0000000100
		var a4 = this.$.stream.peekUInt8(4) * 0x0000000001

		var a = a0 + a1 + a2 + a3 + a4
		a = a % Math.pow(2, 40 - this.$.bitPosition)
		a = a / Math.pow(2, 40 - this.$.bitPosition - n)
		
		return a << 0
	}

	bitStream.peek = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		return (a << this.$.bitPosition) >>> (32 - n)
	}

	bitStream.peekSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)

		return ((a << this.$.bitPosition) & 0xFFFF) >>> (16 - n)
	}

	bitStream.peekOne = function (n) {
		var a = this.$.stream.peekUInt8(0)

		return ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readBig = function (n) {
		var value = this.peekBig(bits)

		this.advance(n)

		return value
	}

	bitStream.readSigned = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.read = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)
		a = ((a << this.$.bitPosition) & 0xFFFF) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readOne = function () {
		var a = this.$.stream.peekUInt8(0)
		a = ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readLSB = function (n) {
		if (n == 0) { return 0 }

		var modBits = n + this.$.bitPosition

		var a = this.$.stream.peekUInt8(0) >>> this.$.bitPosition

		if (modBits > 8) {
			a = a | (this.$.stream.peekUInt8(1) << (8  - this.$.bitPosition))
		}

		if (modBits > 16) {
			a = a | (this.$.stream.peekUInt8(2) << (16 - this.$.bitPosition))
		}

		if (modBits > 24) {
			a = a | (this.$.stream.peekUInt8(3) << (24 - this.$.bitPosition))
		}

		if (modBits > 32) {
			a = a | (this.$.stream.peekUInt8(4) << (32 - this.$.bitPosition))
		}

		this.advance(n)

		return a & bitMask[n]
	}

	Aurora.bitStream = bitStream
	Aurora.BitStream = bitStream.constructor

	Aurora.BitStream.prototype = bitStream
}(this)


void function (global) {
	'use strict'

	var eventEmitter = Aurora.extend(Aurora.object, 'Aurora::EventEmitter', {
		events: { value: {} }
	})

	eventEmitter.constructor = function () {
		Aurora.object.constructor.apply(this)
	}

	eventEmitter.on = function (event, fn) {
		var callbacks = this.$.events[event] || []
		callbacks.push(fn)
		this.$.events[event] = callbacks
	}

	eventEmitter.off = function (event, fn) {
		var array = this.$.events[event]

		if (array) {
			var index = array.indexOf(fn)
			if (index != -1) {
				array.splice(index, 1)
			}
		}
	}

	eventEmitter.once = function (event, fn) {
		var cb = function () {
			this.off(event, cb)
			fn.apply(this, arguments)
		}
		this.on(event, cb)
	}

	eventEmitter.emit = function (event) {
		var array = this.$.events[event], args = Array.prototype.slice.call(arguments, 1)
		if (array) {
			for (var i = 0; i < array.length; i++) {
				array[i].apply(this, args)
			}
		}
	}

	Aurora.eventEmitter = eventEmitter
	Aurora.EventEmitter = eventEmitter.constructor

	Aurora.EventEmitter.prototype = eventEmitter
}(this)


void function (global) {
	'use strict'

	var formats = []
	var demuxer = Aurora.extend(Aurora.eventEmitter, 'Aurora::Demuxer')

	demuxer.constructor = function (source, chunk) {
		Aurora.eventEmitter.constructor.apply(this)

		var list = new Aurora.BufferList()
		list.push(chunk)

		this.$.stream = new Aurora.Stream(list)

		var received = false, self = this

		source.on('data', function (chunk) {
			received = true, list.push(chunk), this.readChunk(chunk)
		}.bind(this))

		source.on('error', function (err) {
			this.emit('error', err)
		}.bind(this))

		source.on('end', function () {
			if (!received) { this.readChunk() }

			this.emit('end')
		}.bind(this))

		this.init() /* TODO: Why not use the constructor? */
	}

	demuxer.constructor.probe = function (buffer) {
		return false
	}

	demuxer.constructor.register = function (demuxer) {
		formats.push(demuxer)
	}

	demuxer.constructor.find = function (buffer) {
		var stream = Aurora.Stream.fromBuffer(buffer)

		for (var i = 0; i < formats.length; i++) {
			if (formats[i].probe(stream)) {
				return formats[i]
			}
		}

		return null
	}

	demuxer.init = function () { }
	demuxer.readChunk = function (chunk) { }
	demuxer.seek = function (timestamp) { }

	Aurora.demuxer = demuxer
	Aurora.Demuxer = demuxer.constructor

	Aurora.Demuxer.prototype = demuxer
}(this)

void function (global) {
	'use strict'

	var codecs = {}
	var decoder = Aurora.extend(Aurora.eventEmitter, 'Aurora::Decoder')

	decoder.constructor = function (demuxer, format) {
		Aurora.eventEmitter.constructor.apply(this)

		this.$.format = format

		var list = new Aurora.BufferList()

		this.$.stream = new Aurora.Stream(list)
		this.$.bitstream = new Aurora.BitStream(this.$.stream)

		this.receivedFinalBuffer = false

		demuxer.on('cookie', function (cookie) {
			this.setCookie(cookie)
		}.bind(this))

		demuxer.on('data', function (chunk, last) {
			this.receivedFinalBuffer = !!last

			list.push(chunk)

			setTimeout(function () {
				this.emit('available')
			}.bind(this), 0)
		}.bind(this))

		this.init() /* TODO: Why not use the constructor? */
	}

	decoder.constructor.probe = function (buffer) {
		return false
	}

	decoder.constructor.register = function (id, decoder) {
		codecs[id] = decoder
	}

	decoder.constructor.find = function (id) {
		return codecs[id]
	}

	decoder.init = function () { }
	decoder.setCookie = function (cookie) { }
	decoder.readChunk = function (chunk) { }
	decoder.seek = function (timestamp) { }

	Aurora.decoder = decoder
	Aurora.Decoder = decoder.constructor

	Aurora.Decoder.prototype = decoder
}(this)

void function (global) {
	'use strict'

	var filter = Aurora.extend(Aurora.object, 'Aurora::Filter', {}, {
		value: { get: function () { return this.$.context[this.$.key] } }
	})

	filter.constructor = function (context, key) {
		Aurora.object.constructor.apply(this)
		
		this.$.context = context, this.$.key = key
	}

	filter.process = function (buffer) {
		return
	}

	Aurora.filter = filter
	Aurora.Filter = filter.constructor

	Aurora.Filter.prototype = filter
}(this)

/*
 * The AudioDevice class is responsible for interfacing with various audio
 * APIs in browsers, and for keeping track of the current playback time
 * based on the device hardware time and the play/pause/seek state
 */

void function (global) {
	'use strict'

	var devices = []
	var device = Aurora.extend(Aurora.eventEmitter, 'Aurora::Device', {
		lastTime: { value: 0, writable: true }
	})

	device.constructor = function (sampleRate, channels) {
		Aurora.eventEmitter.constructor.apply(this)

		this.sampleRate = sampleRate, this.channels = channels
		this.playing = false
		this.currentTime = 0
	}

	device.constructor.register = function (device) {
		devices.push(device)
	}

	device.constructor.create = function (sampleRate, channels) {
		for (var i = 0; i < devices.length; i++) {
			if (devices[i].supported) {
				return new devices[i](sampleRate, channels)
			}
		}

		return null
	}

	device.start = function () {
		if (this.playing) { return }

		this.playing = true
		this.device = Aurora.Device.create(this.sampleRate, this.channels)
		this.$.lastTime = this.device.getDeviceTime()

		this.$.timer = setInterval(this.updateTime.bind(this), 200)
		this.$.refill = function (buffer) {
			this.emit('refill', buffer)
		}.bind(this)

		this.device.on('refill', this.$.refill)
	}

	device.stop = function () {
		if (!this.playing) { return }

		this.playing = false

		this.device.off('refill', this.$.refill)

		clearInterval(this.$.timer)
	}

	device.destroy = function () {
		this.stop()

		this.device.destroy()
	}

	device.seek = function (currentTime) {
		this.currentTime = currentTime

		this.$.lastTime = this.device.getDeviceTime()

		this.emit('timeUpdate', currentTime)
	}

	device.updateTime = function () {
		var time = this.device.getDeviceTime()
		this.currentTime += ((time - this.$.lastTime) / this.device.sampleRate * 1000) >> 0
		this.$.lastTime = time

		this.emit('timeUpdate', this.currentTime)
	}

	Aurora.device = device
	Aurora.Device = device.constructor

	Aurora.Device.prototype = device
}(this)


void function (global) {
	'use strict'

	var queue = Aurora.extend(Aurora.eventEmitter, 'Aurora::Queue', {
		buffers: { value: [] }
	})

	queue.constructor = function (decoder) {
		Aurora.eventEmitter.constructor.apply(this)

		this.$.decoder = decoder

		this.readyMark = 64
		this.finished = false
		this.buffering = true

		decoder.on('data', this.write.bind(this))

		decoder.readChunk()
	}

	queue.write = function (buffer) {
		if (buffer) { this.$.buffers.push(buffer) }

		if (this.buffering) {
			if ((this.$.buffers.length >= this.readyMark) || this.$.decoder.receivedFinalBuffer) {
				this.buffering = false

				this.emit('ready')
			} else {
				this.$.decoder.readChunk()
			}
		}
	}

	queue.read = function () {
		if (this.$.buffers.length == 0) { return null }

		this.$.decoder.readChunk()

		return this.$.buffers.shift()
	}

	Aurora.queue = queue
	Aurora.Queue = queue.constructor

	Aurora.Queue.prototype = queue
}(this)

